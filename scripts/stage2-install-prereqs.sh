#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/stage2-proof"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/00-stage2-install-prereqs.log") 2>&1

echo "== Disable swap now and persistently =="
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

echo "== Kernel modules and sysctl for Kubernetes networking =="
cat <<'EOM' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOM

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOM' | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOM

sudo sysctl --system

echo "== Install containerd =="
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd

echo "== Add Kubernetes repo and install kubelet/kubeadm/kubectl =="
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

echo "== Versions =="
containerd --version || true
kubeadm version
kubectl version --client

printf '\n== Binary checks ==\n'
which containerd || true
which kubelet || true
which kubeadm || true
which kubectl || true
systemctl is-active containerd || true
