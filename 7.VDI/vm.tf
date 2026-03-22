# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable virtualMachines {
  type = list(object({
    enable = bool
    name   = string
    size   = string
    count  = number
    image = object({
      marketplace = object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      })
      custom = object({
        enable         = bool
        definitionName = string
        versionId      = string
      })
    })
    osDisk = object({
      type        = string
      storageType = string
      cachingMode = string
      sizeGB      = number
      hibernation = object({
        enable = bool
      })
    })
    extension = object({
      custom = object({
        enable   = bool
        fileName = string
        parameters = object({
        })
      })
      avdHost = object({
        enable   = bool
        poolName = string
      })
    })
    monitor = object({
      enable = bool
      metric = object({
        category = string
      })
    })
    adminLogin = object({
      userName     = string
      userPassword = string
      sshKeyPublic = string
      passwordAuth = object({
        disable = bool
      })
    })
    updateManager = object({
      enable = bool
    })
  }))
}

locals {
  virtualMachines = flatten([
    for virtualMachine in var.virtualMachines : [
      for i in range(virtualMachine.count) : merge(virtualMachine, {
        name     = "${virtualMachine.name}${i}"
        location = data.azurerm_virtual_network.main.location
        edgeZone = var.virtualNetwork.edgeZoneName != "" ? var.virtualNetwork.edgeZoneName : null
        adminLogin = merge(virtualMachine.adminLogin, {
          userName     = virtualMachine.adminLogin.userName != "" ? virtualMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = virtualMachine.adminLogin.userPassword != "" ? virtualMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = virtualMachine.adminLogin.sshKeyPublic != "" ? virtualMachine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
    ] if virtualMachine.enable
  ])
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
}

resource azurerm_network_interface vdi {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.vdi.name
  location            = each.value.location
  edge_zone           = each.value.edgeZone
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.vdi.id
  }
  accelerated_networking_enabled = true
}

resource azurerm_linux_virtual_machine vdi {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if lower(virtualMachine.osDisk.type) == "linux"
  }
  name                                                   = each.value.name
  resource_group_name                                    = azurerm_resource_group.vdi.name
  location                                               = each.value.location
  edge_zone                                              = each.value.edgeZone
  size                                                   = each.value.size
  source_image_id                                        = each.value.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${each.value.image.custom.definitionName}/versions/${each.value.image.custom.versionId}" : null
  admin_username                                         = each.value.adminLogin.userName
  admin_password                                         = each.value.adminLogin.userPassword
  disable_password_authentication                        = each.value.adminLogin.passwordAuth.disable
  bypass_platform_safety_checks_on_user_schedule_enabled = each.value.updateManager.enable
  patch_mode                                             = each.value.updateManager.enable ? "AutomaticByPlatform" : "ImageDefault"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    "${azurerm_resource_group.vdi.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingMode
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  additional_capabilities {
    hibernation_enabled = each.value.osDisk.hibernation.enable
  }
  dynamic source_image_reference {
    for_each = !each.value.image.custom.enable ? [1] : []
    content {
      publisher = each.value.image.marketplace.publisher
      offer     = each.value.image.marketplace.offer
      sku       = each.value.image.marketplace.sku
      version   = each.value.image.marketplace.version
    }
  }
  dynamic plan {
    for_each = !each.value.image.custom.enable ? [1] : []
    content {
      publisher = lower(each.value.image.marketplace.publisher)
      product   = lower(each.value.image.marketplace.offer)
      name      = lower(each.value.image.marketplace.sku)
    }
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshKeyPublic
    }
  }
  depends_on = [
    azurerm_network_interface.vdi
  ]
}

resource azurerm_virtual_machine_extension vdi_initialize_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.extension.custom.enable && lower(virtualMachine.osDisk.type) == "linux"
  }
  name                       = "Custom"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.vdi.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
        fileSystem = module.fileSystem.linux
      }))
    )
  })
  depends_on = [
    azurerm_linux_virtual_machine.vdi
  ]
}

resource azurerm_monitor_diagnostic_setting vdi_monitor_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if lower(virtualMachine.osDisk.type) == "linux" && virtualMachine.monitor.enable
  }
  name                       = each.value.name
  target_resource_id         = "${azurerm_resource_group.vdi.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id
  enabled_metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_linux_virtual_machine.vdi
  ]
}

resource azurerm_windows_virtual_machine vdi {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if lower(virtualMachine.osDisk.type) == "windows"
  }
  name                                                   = each.value.name
  resource_group_name                                    = azurerm_resource_group.vdi.name
  location                                               = each.value.location
  edge_zone                                              = each.value.edgeZone
  size                                                   = each.value.size
  source_image_id                                        = each.value.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${each.value.image.custom.definitionName}/versions/${each.value.image.custom.versionId}" : null
  admin_username                                         = each.value.adminLogin.userName
  admin_password                                         = each.value.adminLogin.userPassword
  bypass_platform_safety_checks_on_user_schedule_enabled = each.value.updateManager.enable
  patch_mode                                             = each.value.updateManager.enable ? "AutomaticByPlatform" : "ImageDefault"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    "${azurerm_resource_group.vdi.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingMode
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  additional_capabilities {
    hibernation_enabled = each.value.osDisk.hibernation.enable
  }
  dynamic source_image_reference {
    for_each = !each.value.image.custom.enable ? [1] : []
    content {
      publisher = each.value.image.marketplace.publisher
      offer     = each.value.image.marketplace.offer
      sku       = each.value.image.marketplace.sku
      version   = each.value.image.marketplace.version
    }
  }
  depends_on = [
    azurerm_network_interface.vdi
  ]
}

resource azurerm_virtual_machine_extension vdi_initialize_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.extension.custom.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                       = "Custom"
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = "1.10"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.vdi.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    commandToExecute = "pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
        activeDirectory = local.activeDirectory
        fileSystem      = module.fileSystem.windows
      })), "UTF-16LE"
    )}"
  })
  depends_on = [
    azurerm_windows_virtual_machine.vdi
  ]
}

resource azurerm_virtual_machine_extension vdi_register_avd_host {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.extension.avdHost.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                       = "AVD"
  type                       = "DSC"
  publisher                  = "Microsoft.Powershell"
  type_handler_version       = "2.77"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.vdi.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.main[0].token
    }
  })
  settings = jsonencode({
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02990.697.zip"
    properties = {
      HostPoolName = each.value.extension.avdHost.poolName
    }
  })
  depends_on = [
    azurerm_virtual_machine_extension.vdi_initialize_windows
  ]
}

resource azurerm_monitor_diagnostic_setting vdi_monitor_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if lower(virtualMachine.osDisk.type) == "windows" && virtualMachine.monitor.enable
  }
  name                       = each.value.name
  target_resource_id         = "${azurerm_resource_group.vdi.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id
  enabled_metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_windows_virtual_machine.vdi
  ]
}
