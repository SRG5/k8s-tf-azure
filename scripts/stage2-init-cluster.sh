#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/stage2-proof"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/10-stage2-init-cluster.log") 2>&1

NODE_IP="$(hostname -I | awk '{print $1}')"

echo "== kubeadm init =="
sudo kubeadm init \
  --apiserver-advertise-address="${NODE_IP}" \
  --pod-network-cidr=192.168.0.0/16

echo "== Configure kubeconfig =="
mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
export KUBECONFIG="$HOME/.kube/config"

echo "== Remove control-plane taint for single-node scheduling =="
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "== Install Helm 3 =="
HELM_VERSION="v3.20.1"
cd /tmp
curl -fsSLO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
tar -xzf "helm-${HELM_VERSION}-linux-amd64.tar.gz"
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 "helm-${HELM_VERSION}-linux-amd64.tar.gz"
helm version

echo "== Install Calico via Helm =="
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update
kubectl create namespace tigera-operator --dry-run=client -o yaml | kubectl apply -f -
helm install calico projectcalico/tigera-operator \
  --version v3.31.4 \
  --namespace tigera-operator

echo "== Wait and verify =="
kubectl wait --for=condition=Ready node --all --timeout=300s
kubectl get nodes -o wide | tee "$LOG_DIR/01-kubectl-get-nodes.txt"
kubectl get pods -n tigera-operator -o wide | tee "$LOG_DIR/02-tigera-operator-pods.txt"
kubectl get pods -n calico-system -o wide | tee "$LOG_DIR/03-calico-system-pods.txt"
kubectl describe node "$(kubectl get nodes -o name | sed 's#node/##')" | tee "$LOG_DIR/04-node-describe.txt"
