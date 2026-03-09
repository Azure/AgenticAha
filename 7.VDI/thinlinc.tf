# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###############################################################################
# Cendio ThinLinc (https://marketplace.microsoft.com/product/cendio.thinlinc) #
###############################################################################

variable thinLinc {
  type = object({
    enable = bool
    name   = string
    size   = string
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
}

locals {
  thinLinc = merge(var.thinLinc, {
    adminLogin = merge(var.thinLinc.adminLogin, {
      userName     = var.thinLinc.adminLogin.userName != "" ? var.thinLinc.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
      userPassword = var.thinLinc.adminLogin.userPassword != "" ? var.thinLinc.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      sshKeyPublic = var.thinLinc.adminLogin.sshKeyPublic != "" ? var.thinLinc.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
    })
  })
}

resource azurerm_network_interface thinlinc {
  count               = var.thinLinc.enable ? 1 : 0
  name                = var.thinLinc.name
  resource_group_name = azurerm_resource_group.vdi_thinlinc[0].name
  location            = azurerm_resource_group.vdi_thinlinc[0].location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.vdi.id
  }
  accelerated_networking_enabled = true
}

 resource azurerm_linux_virtual_machine thinlinc {
  count                           = var.thinLinc.enable ? 1 : 0
  name                            = var.thinLinc.name
  resource_group_name             = azurerm_resource_group.vdi_thinlinc[0].name
  location                        = azurerm_resource_group.vdi_thinlinc[0].location
  size                            = var.thinLinc.size
  admin_username                  = local.thinLinc.adminLogin.userName
  admin_password                  = local.thinLinc.adminLogin.userPassword
  disable_password_authentication = local.thinLinc.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.thinlinc[0].id
  ]
  os_disk {
    storage_account_type = var.thinLinc.osDisk.storageType
    caching              = var.thinLinc.osDisk.cachingMode
    disk_size_gb         = var.thinLinc.osDisk.sizeGB > 0 ? var.thinLinc.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = var.thinLinc.image.publisher
    offer     = var.thinLinc.image.product
    sku       = var.thinLinc.image.name
    version   = var.thinLinc.image.version
  }
  plan {
    publisher = lower(var.thinLinc.image.publisher)
    product   = lower(var.thinLinc.image.product)
    name      = lower(var.thinLinc.image.name)
  }
  dynamic admin_ssh_key {
    for_each = local.thinLinc.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.thinLinc.adminLogin.userName
      public_key = local.thinLinc.adminLogin.sshKeyPublic
    }
  }
}
