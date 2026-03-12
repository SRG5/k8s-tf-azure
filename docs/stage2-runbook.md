# Stage 2 Runbook

The assignment asks for Kubernetes installation steps as a script or small README, plus proof of one Ready node, healthy Calico pods, and an explanation of node taints.

## What Terraform does

Terraform uploads these files to the VM after it is created:

- `/opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh`
- `/opt/k8s-tf-azure/scripts/stage2-init-cluster.sh`

It does **not** run them automatically. This keeps Stage 1 as infrastructure only and keeps Stage 2 explicit and easy to demonstrate.

## What to run on the VM

SSH into the VM:

```bash
ssh -i "<private-key-path>" azureuser@<public-ip>
```

Run the prerequisites script:

```bash
/opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh
```

After it finishes, verify binaries:

```bash
which kubeadm
which kubectl
which kubelet
systemctl is-active containerd
```

Then initialize the cluster and install Calico:

```bash
/opt/k8s-tf-azure/scripts/stage2-init-cluster.sh
```

## Expected proofs

```bash
kubectl get nodes -o wide
kubectl get pods -n tigera-operator -o wide
kubectl get pods -n calico-system -o wide
```

## Taints explanation for submission

This is a single-node kubeadm cluster. By default, regular workloads are not scheduled onto a control-plane node. To allow workloads to run on the only node in the cluster, the control-plane `NoSchedule` taint was removed using:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

Without this step, application workloads would remain `Pending` because there is no separate worker node.
