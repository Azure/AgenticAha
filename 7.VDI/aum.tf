# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##############################################################################
# Update Manager (https://learn.microsoft.com/azure/update-manager/overview) #
##############################################################################

variable updateManager {
  type = object({
    enable = bool
    name   = string
    guestPatch = object({
      window = object({
        timeZone      = string
        duration      = string
        recurrence    = string
        startDateTime = string
      })
      userMode = object({
        classifications = object({
          linux   = list(string)
          windows = list(string)
        })
        reboot = string
      })
    })
  })
}

resource azurerm_maintenance_configuration guest {
  count                    = var.updateManager.enable ? 1 : 0
  name                     = "${var.updateManager.name}-guest"
  resource_group_name      = azurerm_resource_group.vdi_update_manager[0].name
  location                 = azurerm_resource_group.vdi_update_manager[0].location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"
  window {
    time_zone       = var.updateManager.guestPatch.window.timeZone
    duration        = var.updateManager.guestPatch.window.duration
    recur_every     = var.updateManager.guestPatch.window.recurrence
    start_date_time = var.updateManager.guestPatch.window.startDateTime
  }
  install_patches {
    linux {
      classifications_to_include = var.updateManager.guestPatch.userMode.classifications.linux
    }
    windows {
      classifications_to_include = var.updateManager.guestPatch.userMode.classifications.windows
    }
    reboot = var.updateManager.guestPatch.userMode.reboot
  }
}

resource azurerm_maintenance_configuration image {
  count               = var.updateManager.enable ? 1 : 0
  name                = "${var.updateManager.name}-image"
  resource_group_name = azurerm_resource_group.vdi_update_manager[0].name
  location            = azurerm_resource_group.vdi_update_manager[0].location
  scope               = "OSImage"
}

resource azurerm_maintenance_configuration host {
  count               = var.updateManager.enable ? 1 : 0
  name                = "${var.updateManager.name}-host"
  resource_group_name = azurerm_resource_group.vdi_update_manager[0].name
  location            = azurerm_resource_group.vdi_update_manager[0].location
  scope               = "Host"
}

resource azurerm_maintenance_assignment_virtual_machine vdi {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.updateManager.enable
  }
  maintenance_configuration_id = azurerm_maintenance_configuration.guest[0].id
  virtual_machine_id           = "${azurerm_resource_group.vdi.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  location                     = each.value.location
  depends_on = [
    azurerm_linux_virtual_machine.vdi,
    azurerm_windows_virtual_machine.vdi
  ]
}
