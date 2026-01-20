# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

######################################################################################
# Fabric (https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview) #
######################################################################################

variable fabric {
  type = object({
    enable = bool
    capacity = object({
      name = string
      size = string
    })
    workspace = object({
      name = string
    })
  })
}

resource azurerm_fabric_capacity main {
  count               = var.fabric.enable ? 1 : 0
  name                = var.fabric.capacity.name
  resource_group_name = azurerm_resource_group.data_fabric[0].name
  location            = azurerm_resource_group.data_fabric[0].location
  sku {
    name = var.fabric.capacity.size
    tier = "Fabric"
  }
  administration_members = [
    data.azuread_user.current.mail
  ]
}

resource fabric_workspace main {
  count        = var.fabric.enable ? 1 : 0
  display_name = var.fabric.workspace.name
  capacity_id  = azurerm_fabric_capacity.main[0].id
  identity = {
    type = "SystemAssigned"
  }
}
