# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################
# Microsoft Fabric (https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview) #
################################################################################################

variable msFabric {
  type = object({
    capacity = object({
      enable   = bool
      name     = string
      size     = string
      location = string
    })
    workspace = object({
      enable = bool
      name   = string
      capacity = object({
        id = string
      })
    })
  })
}

data fabric_capacities main {
  depends_on = [
    azurerm_fabric_capacity.main
  ]
}

data fabric_workspaces main {
  depends_on = [
    fabric_workspace.main
  ]
}

resource azurerm_fabric_capacity main {
  count               = var.msFabric.capacity.enable ? 1 : 0
  name                = var.msFabric.capacity.name
  resource_group_name = azurerm_resource_group.data.name
  location            = var.msFabric.capacity.location
  sku {
    name = var.msFabric.capacity.size
    tier = "Fabric"
  }
  administration_members = [
    data.azurerm_user_assigned_identity.main.principal_id
  ]
}

resource fabric_workspace main {
  count        = var.msFabric.workspace.enable ? 1 : 0
  display_name = var.msFabric.workspace.name
  capacity_id  = var.msFabric.workspace.capacity.id
  identity = {
    type = "SystemAssigned"
  }
}

output msFabric {
  value = {
    capacities = data.fabric_capacities.main.values
    workspaces = data.fabric_workspaces.main.values
  }
}
