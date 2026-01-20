# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################
# Virtual Network Manager (https://learn.microsoft.com/azure/virtual-network-manager/overview) #
################################################################################################

variable virtualNetworkManager {
  type = object({
    enable   = bool
    name     = string
    features = list(string)
    groups = list(object({
      enable       = bool
      name         = string
      description  = string
    }))
  })
}

resource azurerm_network_manager main {
  count               = var.virtualNetworkManager.enable ? 1 : 0
  name                = var.virtualNetworkManager.name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  scope_accesses      = var.virtualNetworkManager.features
  scope {
    subscription_ids = [
      data.azurerm_subscription.current.id
    ]
  }
}

resource azurerm_network_manager_network_group main {
  for_each = {
    for networkGroup in var.virtualNetworkManager.groups : networkGroup.name => networkGroup if networkGroup.enable && var.virtualNetworkManager.enable
  }
  name               = each.value.name
  description        = each.value.description
  network_manager_id = azurerm_network_manager.main[0].id
}

resource azurerm_network_manager_static_member main {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if virtualNetwork.enable && var.virtualNetworkManager.enable
  }
  name                      = each.value.key
  network_group_id          = azurerm_network_manager_network_group.main[each.value.groupName].id
  target_virtual_network_id = each.value.id
  depends_on = [
    azurerm_virtual_network.main
  ]
}
