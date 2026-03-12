#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

NAMESPACE="${NAMESPACE:-monitoring}"
RELEASE="${RELEASE:-kube-prometheus-stack}"
PROOF_DIR="${HOME}/stage4-proof"

mkdir -p "${PROOF_DIR}"

echo "== Capture current objects =="
kubectl get pods -n "${NAMESPACE}" -o wide | tee "${PROOF_DIR}/00-monitoring-pods.txt"
kubectl get svc -n "${NAMESPACE}" -o wide | tee "${PROOF_DIR}/01-monitoring-services.txt"
kubectl get prometheusrule -n "${NAMESPACE}" -o yaml | tee "${PROOF_DIR}/02-prometheusrules.yaml"

GRAFANA_NODEPORT="$(kubectl get svc "${RELEASE}-grafana" -n "${NAMESPACE}" -o jsonpath='{.spec.ports[0].nodePort}')"
echo "grafana_nodeport=${GRAFANA_NODEPORT}" | tee "${PROOF_DIR}/03-grafana-nodeport.txt"

PROM_SVC="$(kubectl get svc -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -E 'prometheus$|prometheus-' | grep -v operated | head -n1)"
AM_SVC="$(kubectl get svc -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep alertmanager | head -n1)"

if [ -z "${PROM_SVC}" ] || [ -z "${AM_SVC}" ]; then
  echo "ERROR: could not detect Prometheus or Alertmanager service names"
  exit 1
fi

cleanup() {
  kill "${PROM_PID:-0}" "${AM_PID:-0}" 2>/dev/null || true
}
trap cleanup EXIT

echo "== Port-forward Prometheus and Alertmanager =="
kubectl port-forward "svc/${PROM_SVC}" -n "${NAMESPACE}" 9090:9090 >/tmp/stage4-prom-pf.log 2>&1 &
PROM_PID=$!
kubectl port-forward "svc/${AM_SVC}" -n "${NAMESPACE}" 9093:9093 >/tmp/stage4-am-pf.log 2>&1 &
AM_PID=$!

sleep 8

echo "== Wait for Prometheus alert to become firing =="
for i in $(seq 1 30); do
  curl -s http://127.0.0.1:9090/api/v1/alerts | tee "${PROOF_DIR}/10-prometheus-alerts.json" >/dev/null
  if grep -q 'Stage4NodeHighCPU' "${PROOF_DIR}/10-prometheus-alerts.json"; then
    echo "Prometheus sees Stage4NodeHighCPU"
    break
  fi
  sleep 10
done

if ! grep -q 'Stage4NodeHighCPU' "${PROOF_DIR}/10-prometheus-alerts.json"; then
  echo "ERROR: Stage4NodeHighCPU was not found in Prometheus alerts"
  exit 1
fi

echo "== Wait for Alertmanager alert =="
for i in $(seq 1 30); do
  curl -s http://127.0.0.1:9093/api/v2/alerts | tee "${PROOF_DIR}/11-alertmanager-alerts.json" >/dev/null
  if grep -q 'Stage4NodeHighCPU' "${PROOF_DIR}/11-alertmanager-alerts.json"; then
    echo "Alertmanager sees Stage4NodeHighCPU"
    break
  fi
  sleep 10
done

if ! grep -q 'Stage4NodeHighCPU' "${PROOF_DIR}/11-alertmanager-alerts.json"; then
  echo "ERROR: Stage4NodeHighCPU was not found in Alertmanager"
  exit 1
fi

echo "== Grafana access reminder =="
cat <<EOF | tee "${PROOF_DIR}/12-grafana-access.txt"
Open Grafana from your browser:
http://<VM_PUBLIC_IP>:${GRAFANA_NODEPORT}

Then capture a small screenshot from Grafana Alerting showing:
- Stage4NodeHighCPU
- state = firing
EOF

echo "Verification complete."