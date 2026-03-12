variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "vm_name" {
  description = "Linux VM name."
  type        = string
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "Public SSH key content."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the NIC will be created."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
