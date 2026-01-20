# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################################
# Virtual Network Peering (https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview) #
################################################################################################################

variable networkPeering {
  type = object({
    enable                      = bool
    allowRemoteNetworkAccess    = bool
    allowRemoteForwardedTraffic = bool
    allowGatewayTransit         = bool
  })
}

resource azurerm_virtual_network_peering hub_to_spoke {
  for_each = {
    for virtualNetwork in local.spokeVirtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                         = "${local.virtualNetwork.key}.${each.value.key}"
  resource_group_name          = local.virtualNetwork.resourceGroup.name
  virtual_network_name         = local.virtualNetwork.name
  remote_virtual_network_id    = each.value.id
  allow_virtual_network_access = var.networkPeering.allowRemoteNetworkAccess
  allow_forwarded_traffic      = var.networkPeering.allowRemoteForwardedTraffic
  allow_gateway_transit        = var.networkPeering.allowGatewayTransit
  use_remote_gateways          = false
  depends_on = [
    azurerm_subnet_network_security_group_association.main
  ]
}

resource azurerm_virtual_network_peering spoke_to_hub {
  for_each = {
    for virtualNetwork in local.spokeVirtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                         = "${each.value.key}.${local.virtualNetwork.key}"
  resource_group_name          = each.value.resourceGroup.name
  virtual_network_name         = each.value.name
  remote_virtual_network_id    = local.virtualNetwork.id
  allow_virtual_network_access = var.networkPeering.allowRemoteNetworkAccess
  allow_forwarded_traffic      = var.networkPeering.allowRemoteForwardedTraffic
  allow_gateway_transit        = var.networkPeering.allowGatewayTransit
  use_remote_gateways          = false
  depends_on = [
    azurerm_subnet_network_security_group_association.main
  ]
}
