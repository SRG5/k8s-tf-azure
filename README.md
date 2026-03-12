# k8s-tf-azure

Implementation for the **DevOps Home Assignment – K8s and Terraform on Azure**.

This repository provisions a lightweight Azure environment for a **single-node kubeadm-based Kubernetes cluster**, uploads the required Stage 2 and Stage 3 assets to the VM, and documents the execution flow and proof files used for submission.

## Current status

Completed:
- **Stage 1** – Azure infrastructure with Terraform
- **Stage 2** – Kubernetes installation on the VM with `kubeadm` and Calico
- **Stage 3** – Namespace isolation with workloads and `NetworkPolicy`

Planned next:
- **Stage 4** – Observability with Prometheus, Grafana, and Alertmanager

## What this repo includes

- Terraform for Azure infrastructure
- Resource Group, VNet, subnet, and NSG
- One Ubuntu Linux VM
- SSH restricted to a chosen CIDR
- Automatic upload of Stage 2 scripts to the VM
- Automatic upload of Stage 3 manifests and scripts to the VM
- Runbooks and proof files for Stage 2 and Stage 3

## Design choices

- **Single VM**: enough for a single-node kubeadm cluster for this assignment
- **Ubuntu 22.04 LTS**: stable and common for Kubernetes tooling
- **Single subnet + NSG**: simple network model and easy to reason about
- **SSH restricted to one CIDR**: avoids exposing port 22 broadly
- **Terraform uploads assets but does not execute them**: keeps infrastructure provisioning separate from Kubernetes execution and makes the demo flow explicit
- **Calico**: used as the CNI and enables `NetworkPolicy` enforcement

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

kubernetes/
  stage3/
    00-namespaces.yaml
    10-app1.yaml
    20-app2.yaml
    30-network-policies.yaml

docs/
  stage2-runbook.md
  stage2-proof/
  stage3-runbook.md
  stage3-proof/
```

## Prerequisites

- Azure subscription
- Azure CLI installed
- Terraform installed
- SSH key pair

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

The Stage 3 proof demonstrates both required outcomes:
- same-namespace traffic allowed (`Hello from app1`) 
- cross-namespace traffic blocked (`curl_exit_code=28`) citeturn563732view1turn563732view0

## Notes

- Do **not** commit `terraform.tfvars`, `terraform.tfstate`, `.terraform/`, or `tfplan`
- The NSG currently allows only SSH inbound from the configured CIDR
- The same NSG can be extended in Stage 4 for restricted Grafana access
