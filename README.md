# k8s-tf-azure

Stage 1 of the **DevOps Home Assignment - K8s and TF on Azure**.

This repository starts with a minimal Terraform project that provisions a lightweight Azure environment for a **single-node kubeadm-based Kubernetes cluster**.

## What this stage provisions

- Azure Resource Group
- Azure Virtual Network (VNet)
- One subnet
- One Network Security Group (NSG)
- One Ubuntu Linux VM (`Standard_B2ms` by default)
- SSH access restricted to a CIDR you provide
- Public IP for administrative access

## Design choices

The assignment asks for a lightweight kubeadm-based environment with a VM, VNet, subnets, NSGs, and SSH access. This implementation stays deliberately small and focused:

- **Single VM**: enough for a kubeadm single-node cluster.
- **Ubuntu 22.04 LTS**: common and stable choice for kubeadm.
- **Single subnet**: enough for this scope and keeps networking clear.
- **NSG attached to the subnet**: simple and easy to reason about.
- **SSH restricted to your IP/CIDR**: better than leaving port 22 open broadly.
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
```

## Prerequisites

- Azure subscription
- Azure CLI installed
- Terraform installed
- An SSH key pair

## Generate an SSH key (Windows PowerShell example)

```powershell
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\k8s_tf_azure
```

This creates:

- private key: `C:\Users\<you>\\.ssh\\k8s_tf_azure`
- public key: `C:\Users\<you>\\.ssh\\k8s_tf_azure.pub`

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
- `ssh_allowed_cidr` (example: `203.0.113.10/32`)
- `admin_ssh_public_key_path`

5. Run Terraform:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Capture apply output for submission

The assignment asks for **Terraform apply output**. In PowerShell you can capture it like this:

```powershell
terraform apply -auto-approve *>&1 | Tee-Object -FilePath apply-output.txt
```

## Outputs you will use

After apply, Terraform prints:

- VM public IP
- SSH command
- Resource group name
- NSG name

## SSH into the VM

```powershell
ssh -i $env:USERPROFILE\.ssh\k8s_tf_azure azureuser@<PUBLIC_IP>
```

## Notes

- This project does **not** generate private SSH keys with Terraform. That would place sensitive material in Terraform state, which is a bad practice for a simple assignment.
- The NSG currently allows only SSH inbound from your chosen CIDR. Later stages can extend the same NSG for Grafana NodePort access.
