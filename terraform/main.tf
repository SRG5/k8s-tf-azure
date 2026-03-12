locals {
  stage3_manifest_dir = "${path.module}/../kubernetes/stage3"

  stage3_manifest_files = sort(tolist(fileset(local.stage3_manifest_dir, "**")))

  stage3_artifacts = concat(
    [for f in local.stage3_manifest_files : "${local.stage3_manifest_dir}/${f}"],
    [
      "${path.module}/../scripts/stage3-apply.sh",
      "${path.module}/../scripts/stage3-verify.sh"
    ]
  )
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "time_sleep" "after_resource_group" {
  depends_on      = [azurerm_resource_group.this]
  create_duration = "20s"
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

  depends_on = [time_sleep.after_resource_group]
}

module "linux_vm" {
  source = "./modules/linux_vm"

  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  vm_name              = var.vm_name
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  admin_ssh_public_key = file(var.admin_ssh_public_key_path)
  subnet_id            = module.network.subnet_id
  tags                 = var.tags

  depends_on = [module.network]
}

resource "time_sleep" "after_vm" {
  depends_on      = [module.linux_vm]
  create_duration = "15s"
}

resource "null_resource" "upload_stage2_scripts" {
  depends_on = [time_sleep.after_vm]

  triggers = {
    vm_ip       = module.linux_vm.public_ip_address
    install_sha = filesha256("${path.module}/../scripts/stage2-install-prereqs.sh")
    init_sha    = filesha256("${path.module}/../scripts/stage2-init-cluster.sh")
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    host        = module.linux_vm.public_ip_address
    private_key = file(var.admin_ssh_private_key_path)
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/k8s-tf-azure/scripts",
      "sudo chown -R ${var.admin_username}:${var.admin_username} /opt/k8s-tf-azure"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/stage2-install-prereqs.sh"
    destination = "/opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/stage2-init-cluster.sh"
    destination = "/opt/k8s-tf-azure/scripts/stage2-init-cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/k8s-tf-azure/scripts/stage2-install-prereqs.sh",
      "chmod +x /opt/k8s-tf-azure/scripts/stage2-init-cluster.sh",
      "ls -l /opt/k8s-tf-azure/scripts"
    ]
  }
}

resource "null_resource" "upload_stage3_assets" {
  depends_on = [null_resource.upload_stage2_scripts]

  triggers = {
    vm_ip             = module.linux_vm.public_ip_address
    stage3_bundle_sha = sha256(join("", [for f in local.stage3_artifacts : filesha256(f)]))
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    host        = module.linux_vm.public_ip_address
    private_key = file(var.admin_ssh_private_key_path)
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/k8s-tf-azure/kubernetes",
      "sudo mkdir -p /opt/k8s-tf-azure/scripts",
      "sudo chown -R ${var.admin_username}:${var.admin_username} /opt/k8s-tf-azure"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../kubernetes/stage3"
    destination = "/opt/k8s-tf-azure/kubernetes"
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/stage3-apply.sh"
    destination = "/opt/k8s-tf-azure/scripts/stage3-apply.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/stage3-verify.sh"
    destination = "/opt/k8s-tf-azure/scripts/stage3-verify.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/k8s-tf-azure/scripts/stage3-apply.sh",
      "chmod +x /opt/k8s-tf-azure/scripts/stage3-verify.sh",
      "ls -l /opt/k8s-tf-azure/scripts",
      "find /opt/k8s-tf-azure/kubernetes/stage3 -maxdepth 1 -type f | sort"
    ]
  }
}