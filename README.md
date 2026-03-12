# k8s-tf-azure

Implementation for the **DevOps Home Assignment - K8s and TF on Azure**.

This repository provisions a lightweight Azure environment for a **single-node kubeadm-based Kubernetes cluster** and stages the Stage 2 Kubernetes installation scripts directly onto the VM.

## What this repo includes

- Terraform for Azure infrastructure
- A minimal network layout: Resource Group, VNet, subnet, NSG
- One Ubuntu Linux VM
- SSH restricted to your CIDR
- Stage 2 Kubernetes installation scripts uploaded automatically to the VM after provisioning
- A short Stage 2 runbook for what to run and what proof to capture

## Design choices

- **Single VM**: enough for a kubeadm single-node cluster.
- **Ubuntu 22.04 LTS**: common and stable choice for kubeadm.
- **Single subnet**: enough for this scope and keeps networking clear.
- **NSG attached to the subnet**: simple and easy to reason about.
- **SSH restricted to your IP/CIDR**: better than leaving port 22 open broadly.
- **Scripts uploaded by Terraform**: reduces copy/paste mistakes while keeping the actual cluster installation explicit and easy to demonstrate.
- **No extra services**: no load balancer, no jump host, no autoscaling, no extras the assignment did not ask for.

## Suggested repo layout

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
docs/
  stage2-runbook.md
```

## Prerequisites

- Azure subscription
- Azure CLI installed
- Terraform installed
- An SSH key pair

## How to use

1. Log in to Azure:

```powershell
az login
```

2. Move into the Terraform directory:

```powershell
cd terraform
```

3. Create your own variables file from the example:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

4. Edit `terraform.tfvars` and set:

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

- `/opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh`
- `/opt/k8s-tf-azure/scripts/stage2-init-cluster.sh`

## Stage 2 execution

SSH into the VM and run:

```bash
/opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh
/opt/k8s-tf-azure/scripts/stage2-init-cluster.sh
```

See `docs/stage2-runbook.md` for the exact flow and the expected proof.

## Capture apply output for submission

```powershell
terraform apply -auto-approve *>&1 | Tee-Object -FilePath apply-output.txt
```

## Notes

- Do **not** commit `terraform.tfvars`, `terraform.tfstate`, `.terraform/`, or `tfplan`.
- The NSG currently allows only SSH inbound from your chosen CIDR. Later stages can extend the same NSG for Grafana NodePort access.
