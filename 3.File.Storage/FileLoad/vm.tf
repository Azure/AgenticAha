# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable fileLoad {
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
  })
}

locals {
  fileLoad = merge(var.fileLoad, {
    machine = merge(var.fileLoad.machine, {
      adminLogin = merge(var.fileLoad.machine.adminLogin, {
        userName     = var.fileLoad.machine.adminLogin.userName != "" ? var.fileLoad.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.fileLoad.machine.adminLogin.userPassword != "" ? var.fileLoad.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.fileLoad.machine.adminLogin.sshKeyPublic != "" ? var.fileLoad.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
}

resource azurerm_network_interface storage_file_load {
  name                = var.fileLoad.machine.name
  resource_group_name = azurerm_resource_group.storage_file_load.name
  location            = azurerm_resource_group.storage_file_load.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.storage.id
  }
  accelerated_networking_enabled = true
}

 resource azurerm_linux_virtual_machine storage_file_load {
  name                            = var.fileLoad.machine.name
  resource_group_name             = azurerm_resource_group.storage_file_load.name
  location                        = azurerm_resource_group.storage_file_load.location
  size                            = var.fileLoad.machine.size
  admin_username                  = local.fileLoad.machine.adminLogin.userName
  admin_password                  = local.fileLoad.machine.adminLogin.userPassword
  disable_password_authentication = local.fileLoad.machine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.storage_file_load.id
  ]
  os_disk {
    storage_account_type = var.fileLoad.machine.osDisk.storageType
    caching              = var.fileLoad.machine.osDisk.cachingMode
    disk_size_gb         = var.fileLoad.machine.osDisk.sizeGB > 0 ? var.fileLoad.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = var.fileLoad.machine.image.publisher
    offer     = var.fileLoad.machine.image.product
    sku       = var.fileLoad.machine.image.name
    version   = var.fileLoad.machine.image.version
  }
  plan {
    publisher = lower(var.fileLoad.machine.image.publisher)
    product   = lower(var.fileLoad.machine.image.product)
    name      = lower(var.fileLoad.machine.image.name)
  }
  dynamic admin_ssh_key {
    for_each = local.fileLoad.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.fileLoad.machine.adminLogin.userName
      public_key = local.fileLoad.machine.adminLogin.sshKeyPublic
    }
  }
}

resource azurerm_virtual_machine_extension storage_file_load {
  name                       = "FileLoad"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.storage_file_load.id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("cse.sh", {
        fileLoadMount = var.fileLoad.mount
      })
    )
  })
  timeouts {
    create = "90m"
  }
}
