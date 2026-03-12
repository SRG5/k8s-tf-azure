output "resource_group_name" {
  description = "Resource group name."
  value       = azurerm_resource_group.this.name
}

output "vm_name" {
  description = "Virtual machine name."
  value       = module.linux_vm.vm_name
}

output "vm_public_ip_address" {
  description = "Public IP address of the VM."
  value       = module.linux_vm.public_ip_address
}

output "network_security_group_name" {
  description = "Name of the NSG protecting the subnet."
  value       = module.network.nsg_name
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh -i ${var.admin_ssh_private_key_path} ${var.admin_username}@${module.linux_vm.public_ip_address}"
}

output "stage2_scripts_path" {
  description = "Path on the VM where the Stage 2 scripts were uploaded."
  value       = "/opt/k8s-tf-azure/scripts"
}

output "grafana_url" {
  description = "Grafana URL via NodePort when enabled."
  value       = var.grafana_nodeport_enabled ? "http://${module.linux_vm.public_ip_address}:${var.grafana_nodeport}" : null
}