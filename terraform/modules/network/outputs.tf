output "subnet_id" {
  description = "Subnet ID."
  value       = azurerm_subnet.this.id
}

output "nsg_name" {
  description = "NSG name."
  value       = azurerm_network_security_group.this.name
}

output "vnet_name" {
  description = "VNet name."
  value       = azurerm_virtual_network.this.name
}
