resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "./modules/network"

  location                = var.location
  resource_group_name     = azurerm_resource_group.this.name
  vnet_name               = var.vnet_name
  vnet_address_space      = var.vnet_address_space
  subnet_name             = var.subnet_name
  subnet_address_prefixes = var.subnet_address_prefixes
  nsg_name                = var.nsg_name
  ssh_allowed_cidr        = var.ssh_allowed_cidr
  tags                    = var.tags
}

module "linux_vm" {
  source = "./modules/linux_vm"

  location               = var.location
  resource_group_name    = azurerm_resource_group.this.name
  vm_name                = var.vm_name
  vm_size                = var.vm_size
  admin_username         = var.admin_username
  admin_ssh_public_key   = file(var.admin_ssh_public_key_path)
  subnet_id              = module.network.subnet_id
  tags                   = var.tags
}
