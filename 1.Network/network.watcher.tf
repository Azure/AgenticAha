# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################
# Network Watcher (https://learn.microsoft.com/azure/network-watcher/network-watcher-overview) #
################################################################################################

resource azurerm_network_watcher main {
  for_each            = toset(distinct([for virtualNetwork in local.virtualNetworks : virtualNetwork.location]))
  name                = "NetworkWatcher-${each.value}"
  location            = each.value
  resource_group_name = azurerm_resource_group.network.name
}
