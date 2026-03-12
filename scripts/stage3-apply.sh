#!/usr/bin/env bash
set -euo pipefail

MANIFEST_DIR="/opt/k8s-tf-azure/kubernetes/stage3"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "== Apply namespaces =="
kubectl apply -f "${MANIFEST_DIR}/00-namespaces.yaml"

echo "== Apply workloads =="
kubectl apply -f "${MANIFEST_DIR}/10-app1.yaml"
kubectl apply -f "${MANIFEST_DIR}/20-app2.yaml"

echo "== Wait for deployments =="
kubectl rollout status deployment/app1-nginx -n app1 --timeout=180s
kubectl rollout status deployment/app2-nginx -n app2 --timeout=180s

echo "== Apply network policies =="
kubectl apply -f "${MANIFEST_DIR}/30-network-policies.yaml"

echo "== Current state =="
kubectl get all -n app1
kubectl get all -n app2
kubectl get networkpolicy -n app1
kubectl get networkpolicy -n app2