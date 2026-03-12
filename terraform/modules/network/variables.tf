variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet."
  type        = list(string)
}

variable "subnet_name" {
  description = "Subnet name."
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet."
  type        = list(string)
}

variable "nsg_name" {
  description = "Network Security Group name."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to access the VM over SSH."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}

variable "grafana_nodeport_enabled" {
  description = "Whether to allow inbound access to the Grafana NodePort."
  type        = bool
  default     = false
}

variable "grafana_nodeport" {
  description = "Grafana NodePort value."
  type        = number
  default     = 32000
}