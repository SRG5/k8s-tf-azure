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

PROM_SVC="${RELEASE}-prometheus"
AM_SVC="${RELEASE}-alertmanager"

kubectl get svc "${PROM_SVC}" -n "${NAMESPACE}" >/dev/null
kubectl get svc "${AM_SVC}" -n "${NAMESPACE}" >/dev/null

PROM_PID=""
AM_PID=""

cleanup() {
  if [ -n "${PROM_PID}" ] && kill -0 "${PROM_PID}" 2>/dev/null; then
    kill "${PROM_PID}" 2>/dev/null || true
  fi
  if [ -n "${AM_PID}" ] && kill -0 "${AM_PID}" 2>/dev/null; then
    kill "${AM_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "== Port-forward Prometheus and Alertmanager =="
kubectl port-forward "svc/${PROM_SVC}" -n "${NAMESPACE}" 9090:9090 >/tmp/stage4-prom-pf.log 2>&1 &
PROM_PID=$!
kubectl port-forward "svc/${AM_SVC}" -n "${NAMESPACE}" 9093:9093 >/tmp/stage4-am-pf.log 2>&1 &
AM_PID=$!

sleep 8

PROM_FIRING=false
AM_FOUND=false

echo "== Wait for Prometheus alert to become firing =="
for i in $(seq 1 30); do
  curl -sS http://127.0.0.1:9090/api/v1/alerts | tee "${PROOF_DIR}/10-prometheus-alerts.json" >/dev/null

  if grep -q 'Stage4NodeHighCPU' "${PROOF_DIR}/10-prometheus-alerts.json" && \
     grep -q '"state":"firing"' "${PROOF_DIR}/10-prometheus-alerts.json"; then
    echo "Prometheus sees Stage4NodeHighCPU firing"
    PROM_FIRING=true
    break
  fi

  sleep 10
done

if [ "${PROM_FIRING}" != "true" ]; then
  echo "ERROR: Stage4NodeHighCPU was not found in Prometheus alerts as firing"
  exit 1
fi

echo "== Wait for Alertmanager alert =="
for i in $(seq 1 30); do
  curl -sS http://127.0.0.1:9093/api/v2/alerts | tee "${PROOF_DIR}/11-alertmanager-alerts.json" >/dev/null

  if grep -q 'Stage4NodeHighCPU' "${PROOF_DIR}/11-alertmanager-alerts.json"; then
    echo "Alertmanager sees Stage4NodeHighCPU"
    AM_FOUND=true
    break
  fi

  sleep 10
done

if [ "${AM_FOUND}" != "true" ]; then
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