# k8s-tf-azure

Implementation for the **DevOps Home Assignment – K8s and Terraform on Azure**.

This repository provisions a lightweight Azure environment for a **single-node kubeadm-based Kubernetes cluster**, uploads the required Stage 2, Stage 3, and Stage 4 assets to the VM, and documents the execution flow and proof files used for submission.

## Current status

Completed:
- **Stage 1** – Azure infrastructure with Terraform
- **Stage 2** – Kubernetes installation on the VM with `kubeadm` and Calico
- **Stage 3** – Namespace isolation with workloads and `NetworkPolicy`
- **Stage 4** – Observability with Prometheus, Grafana, and Alertmanager

## What this repo includes

- Terraform for Azure infrastructure
- Resource Group, VNet, subnet, and NSG
- One Ubuntu Linux VM
- SSH restricted to a chosen CIDR
- Optional Grafana NodePort access restricted to the same CIDR
- Automatic upload of Stage 2 scripts to the VM
- Automatic upload of Stage 3 manifests and scripts to the VM
- Automatic upload of Stage 4 observability assets and scripts to the VM
- Runbooks and proof files for Stage 2, Stage 3, and Stage 4

## Design choices

- **Single VM**: enough for a single-node kubeadm cluster for this assignment
- **Ubuntu 22.04 LTS**: stable and common for Kubernetes tooling
- **Single subnet + NSG**: simple network model and easy to reason about
- **SSH restricted to one CIDR**: avoids exposing port 22 broadly
- **Grafana NodePort restricted to one CIDR**: keeps observability access limited to the operator IP
- **Terraform uploads assets but does not execute them**: keeps infrastructure provisioning separate from Kubernetes execution and makes the demo flow explicit
- **Calico**: used as the CNI and enables `NetworkPolicy` enforcement
- **kube-prometheus-stack via Helm**: simple way to deploy Prometheus, Grafana, Alertmanager, and node-exporter together

## Repository layout

```text
terraform/
  versions.tf
  providers.tf
  variables.tf
  main.tf
  outputs.tf
  terraform.tfvars.example
  modules/
    network/
    linux_vm/

scripts/
  stage2-install-prereqs.sh
  stage2-init-cluster.sh
  stage3-apply.sh
  stage3-verify.sh
  stage4-apply.sh
  stage4-trigger-cpu.sh
  stage4-verify.sh

kubernetes/
  stage3/
    00-namespaces.yaml
    10-app1.yaml
    20-app2.yaml
    30-network-policies.yaml

observability/
  stage4/
    values.yaml
    node-high-cpu-alert.yaml

docs/
  stage2-runbook.md
  stage2-proof/
  stage3-runbook.md
  stage3-proof/
  stage4-runbook.md
  stage4-proof/
```

## Prerequisites

- Azure subscription
- Azure CLI installed
- Terraform installed
- SSH key pair
- Helm available on the VM during Stage 2 and Stage 4 execution

## How to use

1. Log in to Azure:

```powershell
az login
```

2. Move into the Terraform directory:

```powershell
cd terraform
```

3. Create your variables file from the example:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

4. Edit `terraform.tfvars` and set at least:
- `subscription_id`
- `ssh_allowed_cidr`
- `admin_ssh_public_key_path`
- `admin_ssh_private_key_path`

5. Run Terraform:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Terraform provisions the infrastructure and uploads the required Stage 2, Stage 3, and Stage 4 assets to the VM.

## What Terraform uploads to the VM

After the VM is created, Terraform uploads:

### Stage 2
- `/opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh`
- `/opt/k8s-tf-azure/scripts/stage2-init-cluster.sh`

### Stage 3
- `/opt/k8s-tf-azure/kubernetes/stage3/00-namespaces.yaml`
- `/opt/k8s-tf-azure/kubernetes/stage3/10-app1.yaml`
- `/opt/k8s-tf-azure/kubernetes/stage3/20-app2.yaml`
- `/opt/k8s-tf-azure/kubernetes/stage3/30-network-policies.yaml`
- `/opt/k8s-tf-azure/scripts/stage3-apply.sh`
- `/opt/k8s-tf-azure/scripts/stage3-verify.sh`

### Stage 4
- `/opt/k8s-tf-azure/observability/stage4/values.yaml`
- `/opt/k8s-tf-azure/observability/stage4/node-high-cpu-alert.yaml`
- `/opt/k8s-tf-azure/scripts/stage4-apply.sh`
- `/opt/k8s-tf-azure/scripts/stage4-trigger-cpu.sh`
- `/opt/k8s-tf-azure/scripts/stage4-verify.sh`

Terraform does **not** execute these scripts automatically.

## Stage 2 summary

Stage 2 installs Kubernetes components on the VM, initializes the cluster with `kubeadm`, installs Calico, and removes the control-plane taint so workloads can run on the single node.

See:
- `docs/stage2-runbook.md`
- `docs/stage2-proof/`

## Stage 3 summary

Stage 3 creates two namespaces:
- `app1`
- `app2`

Each namespace includes:
- a dedicated `ServiceAccount`
- an `nginx` workload
- a `Service`
- unique content so the response can identify the namespace

`NetworkPolicy` is then applied so that:
- traffic **within the same namespace is allowed**
- traffic **between namespaces is blocked**

Verification is done with `curl` from temporary test pods.

See:
- `docs/stage3-runbook.md`
- `docs/stage3-proof/`

## Stage 4 summary

Stage 4 installs `kube-prometheus-stack` with Helm using minimal custom values.

It includes:
- Grafana exposed through `NodePort`
- NSG restriction so Grafana is accessible only from the configured operator CIDR
- a custom `PrometheusRule` for node high CPU
- a controlled CPU burner workload to trigger the alert
- verification that the alert appears in both Prometheus/Grafana and Alertmanager

See:
- `docs/stage4-runbook.md`
- `docs/stage4-proof/`

## Notes

- Do **not** commit `terraform.tfvars`, `terraform.tfstate`, `.terraform/`, or `tfplan`
- Terraform handles infrastructure creation and asset upload only
- Kubernetes and Helm execution steps are run manually on the VM for explicit verification
- Grafana access is intended to be restricted to the configured CIDR through the NSG
