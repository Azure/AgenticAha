# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable bulkLoad {
  type = object({
    mount = object({
      type    = string
      path    = string
      target  = string
      options = string
    })
    machine = object({
      name = string
      size = string
      image = object({
        publisher = string
        product   = string
        name      = string
        version   = string
      })
      osDisk = object({
        storageType = string
        cachingMode = string
        sizeGB      = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshKeyPublic = string
        passwordAuth = object({
          disable = bool
        })
      })
    })
    network = object({
      acceleration = object({
        enable = bool
      })
    })
  })
}

locals {
  bulkLoad = merge(var.bulkLoad, {
    machine = merge(var.bulkLoad.machine, {
      adminLogin = merge(var.bulkLoad.machine.adminLogin, {
        userName     = var.bulkLoad.machine.adminLogin.userName != "" ? var.bulkLoad.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.bulkLoad.machine.adminLogin.userPassword != "" ? var.bulkLoad.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.bulkLoad.machine.adminLogin.sshKeyPublic != "" ? var.bulkLoad.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
}

resource azurerm_network_interface storage_bulk_load {
  name                = var.bulkLoad.machine.name
  resource_group_name = azurerm_resource_group.storage_bulk_load.name
  location            = azurerm_resource_group.storage_bulk_load.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.storage.id
  }
  accelerated_networking_enabled = var.bulkLoad.network.acceleration.enable
}

 resource azurerm_linux_virtual_machine storage_bulk_load {
  name                            = var.bulkLoad.machine.name
  resource_group_name             = azurerm_resource_group.storage_bulk_load.name
  location                        = azurerm_resource_group.storage_bulk_load.location
  size                            = var.bulkLoad.machine.size
  admin_username                  = local.bulkLoad.machine.adminLogin.userName
  admin_password                  = local.bulkLoad.machine.adminLogin.userPassword
  disable_password_authentication = local.bulkLoad.machine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.storage_bulk_load.id
  ]
  os_disk {
    storage_account_type = var.bulkLoad.machine.osDisk.storageType
    caching              = var.bulkLoad.machine.osDisk.cachingMode
    disk_size_gb         = var.bulkLoad.machine.osDisk.sizeGB > 0 ? var.bulkLoad.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = local.bulkLoad.machine.image.publisher
    offer     = local.bulkLoad.machine.image.product
    sku       = local.bulkLoad.machine.image.name
    version   = local.bulkLoad.machine.image.version
  }
  dynamic admin_ssh_key {
    for_each = local.bulkLoad.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.bulkLoad.machine.adminLogin.userName
      public_key = local.bulkLoad.machine.adminLogin.sshKeyPublic
    }
  }
}

resource azurerm_virtual_machine_extension storage_bulk_load {
  name                       = "BulkLoad"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.storage_bulk_load.id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("cse.sh", {
        bulkLoadMount = var.bulkLoad.mount
      })
    )
  })
  timeouts {
    create = "90m"
  }
}
