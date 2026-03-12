#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

LOG_DIR="$HOME/stage3-proof"
mkdir -p "$LOG_DIR"

echo "== Capture current objects =="
kubectl get all -n app1 -o wide | tee "$LOG_DIR/00-app1-objects.txt"
kubectl get all -n app2 -o wide | tee "$LOG_DIR/01-app2-objects.txt"
kubectl get networkpolicy -n app1 -o yaml | tee "$LOG_DIR/02-app1-networkpolicy.yaml"
kubectl get networkpolicy -n app2 -o yaml | tee "$LOG_DIR/03-app2-networkpolicy.yaml"

echo "== Same-namespace traffic should be allowed =="
kubectl run curl-same-app1 \
  -n app1 \
  --image=curlimages/curl \
  --restart=Never \
  --rm -i \
  --command -- \
  curl -sS --max-time 10 http://app1-svc \
  | tee "$LOG_DIR/10-same-namespace-allowed.txt"

echo "== Cross-namespace traffic should be blocked =="
set +e
kubectl run curl-cross-app1-to-app2 \
  -n app1 \
  --image=curlimages/curl \
  --restart=Never \
  --rm -i \
  --command -- \
  curl -sS --connect-timeout 5 --max-time 10 http://app2-svc.app2.svc.cluster.local \
  > "$LOG_DIR/11-cross-namespace-blocked.txt" 2>&1
RC=$?
set -e

echo "curl_exit_code=${RC}" | tee -a "$LOG_DIR/11-cross-namespace-blocked.txt"

if [ "$RC" -eq 0 ]; then
  echo "ERROR: cross-namespace curl unexpectedly succeeded" | tee -a "$LOG_DIR/11-cross-namespace-blocked.txt"
  exit 1
fi

echo "Cross-namespace traffic was blocked as expected."