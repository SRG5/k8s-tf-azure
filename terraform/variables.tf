variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
  default     = "rg-k8s-tf-azure-dev"
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
  default     = "vnet-k8s-tf-azure-dev"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet."
  type        = string
  default     = "snet-k8s-node"
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet."
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "nsg_name" {
  description = "Name of the NSG."
  type        = string
  default     = "nsg-k8s-node"
}

variable "vm_name" {
  description = "Name of the Linux VM."
  type        = string
  default     = "vm-k8s-node-01"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_E2ads_v7"
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key_path" {
  description = "Path to your public SSH key file on the machine running Terraform."
  type        = string
}

variable "admin_ssh_private_key_path" {
  description = "Path to your private SSH key file on the machine running Terraform. Used only to upload Stage 2 scripts to the VM."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to the VM, for example 203.0.113.10/32."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default = {
    project     = "k8s-tf-azure"
    environment = "dev"
    managed_by  = "terraform"
  }
}

variable "grafana_nodeport_enabled" {
  description = "Whether to allow inbound access to the Grafana NodePort from ssh_allowed_cidr."
  type        = bool
  default     = false
}

variable "grafana_nodeport" {
  description = "Grafana NodePort exposed by kube-prometheus-stack."
  type        = number
  default     = 32000
}