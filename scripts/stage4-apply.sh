#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

RELEASE="${RELEASE:-kube-prometheus-stack}"
NAMESPACE="${NAMESPACE:-monitoring}"
CHART="${CHART:-prometheus-community/kube-prometheus-stack}"
CHART_VERSION="${CHART_VERSION:-82.10.1}"

VALUES_FILE="/opt/k8s-tf-azure/observability/stage4/values.yaml"
RULE_FILE="/opt/k8s-tf-azure/observability/stage4/node-high-cpu-alert.yaml"

echo "== Ensure namespace =="
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "== Ensure Helm repo =="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community

echo "== Install/upgrade kube-prometheus-stack =="
helm upgrade --install "${RELEASE}" "${CHART}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --version "${CHART_VERSION}" \
  -f "${VALUES_FILE}" \
  --wait \
  --timeout 20m

echo "== Wait for main workloads =="
kubectl rollout status deployment/"${RELEASE}"-operator -n "${NAMESPACE}" --timeout=300s
kubectl rollout status deployment/"${RELEASE}"-kube-state-metrics -n "${NAMESPACE}" --timeout=300s
kubectl rollout status deployment/"${RELEASE}"-grafana -n "${NAMESPACE}" --timeout=300s
kubectl rollout status daemonset/"${RELEASE}"-prometheus-node-exporter -n "${NAMESPACE}" --timeout=300s

echo "== Apply custom PrometheusRule =="
kubectl apply -f "${RULE_FILE}"

echo "== Current monitoring pods =="
kubectl get pods -n "${NAMESPACE}" -o wide

echo "== Current monitoring services =="
kubectl get svc -n "${NAMESPACE}"

echo "== Grafana NodePort =="
kubectl get svc "${RELEASE}-grafana" -n "${NAMESPACE}" \
  -o jsonpath='{.spec.ports[0].nodePort}'
echo

echo "== Grafana admin password command =="
echo "kubectl get secret -n ${NAMESPACE} ${RELEASE}-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo"