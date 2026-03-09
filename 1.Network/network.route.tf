# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

######################################################################################
# Route Table (https://learn.microsoft.com/azure/virtual-network/manage-route-table) #
######################################################################################

locals {
  userDefinedRouteTables = [
    for virtualNetwork in local.spokeVirtualNetworks : merge(virtualNetwork.routeTable, {
      key            = virtualNetwork.key
      virtualNetwork = virtualNetwork
    }) if virtualNetwork.routeTable.enable
  ]
  userDefinedRouteTableSubnets = flatten([
    for routeTable in local.userDefinedRouteTables : [
      for subnet in routeTable.virtualNetwork.subnets : merge(subnet, {
        key            = "${routeTable.virtualNetwork.key}-${subnet.name}"
        virtualNetwork = routeTable.virtualNetwork
      }) if !contains(["GatewaySubnet","AzureBastionSubnet","AzureFirewallSubnet","AzureFirewallManagementSubnet"], subnet.name)
    ]
  ])
}

resource azurerm_route_table main {
  for_each = {
    for routeTable in local.userDefinedRouteTables : routeTable.key => routeTable if !var.virtualWAN.enable
  }
  name                = each.value.key
  location            = each.value.virtualNetwork.resourceGroup.location
  resource_group_name = each.value.virtualNetwork.resourceGroup.name
  dynamic route {
    for_each = {
      for route in each.value.routes : route.name => route if route.enable
    }
    content {
      name                   = route.value.name
      address_prefix         = route.value.addressPrefix
      next_hop_type          = route.value.nextHopType
      next_hop_in_ip_address = route.value.nextHopType == "VirtualAppliance" && route.value.nextHopAddress == "" ? azurerm_firewall.virtual_network[0].ip_configuration[0].private_ip_address : route.value.nextHopAddress
    }
  }
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_subnet_route_table_association main {
  for_each = {
    for subnet in local.userDefinedRouteTableSubnets : subnet.key => subnet if !var.virtualWAN.enable
  }
  subnet_id      = "${each.value.virtualNetwork.id}/subnets/${each.value.name}"
  route_table_id = "${each.value.virtualNetwork.resourceGroup.id}/providers/Microsoft.Network/routeTables/${each.value.virtualNetwork.key}"
  depends_on = [
    azurerm_subnet.main,
    azurerm_route_table.main
  ]
}
