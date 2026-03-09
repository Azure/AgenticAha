# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

variable hubVirtualNetworks {
  type = list(object({
    enable       = bool
    name         = string
    hubName      = string
    groupName    = string
    location     = string
    addressSpace = list(string)
    dnsAddresses = list(string)
    subnets = list(object({
      name             = string
      addressSpace     = list(string)
      serviceEndpoints = list(string)
      serviceDelegation = object({
        service = string
        actions = list(string)
      })
    }))
  }))
}

variable spokeVirtualNetworks {
  type = list(object({
    enable    = bool
    hubName   = string
    groupName = string
    location  = string
    addressSpace = object({
      search  = string
      replace = string
    })
    extendedZone = object({
      enable   = bool
      name     = string
      location = string
    })
    routeTable = object({
      enable = bool
      routes = list(object({
        enable         = bool
        name           = string
        addressPrefix  = string
        nextHopType    = string
        nextHopAddress = string
      }))
    })
  }))
}

locals {
  virtualNetwork  = local.virtualNetworks[0]
  virtualNetworks = concat([
    for virtualNetwork in var.hubVirtualNetworks : merge(virtualNetwork, {
      key      = "${virtualNetwork.name}-${virtualNetwork.location}"
      id       = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.location}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      location = virtualNetwork.location
      resourceGroup = {
        id       = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.location}"
        name     = "${var.resourceGroupName}.${virtualNetwork.location}"
        location = virtualNetwork.location
      }
      extendedZone = null
    }) if virtualNetwork.enable
  ], local.spokeVirtualNetworks)
  spokeVirtualNetworks = [
    for virtualNetwork in var.spokeVirtualNetworks : merge(var.hubVirtualNetworks[0], {
      key        = "${var.hubVirtualNetworks[0].name}-${virtualNetwork.location}${virtualNetwork.extendedZone.enable ? "-${virtualNetwork.extendedZone.name}" : ""}"
      id         = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.location}${virtualNetwork.extendedZone.enable ? ".${virtualNetwork.extendedZone.name}" : ""}/providers/Microsoft.Network/virtualNetworks/${var.hubVirtualNetworks[0].name}"
      location   = virtualNetwork.location
      hubName    = virtualNetwork.hubName
      groupName  = virtualNetwork.groupName
      routeTable = virtualNetwork.routeTable
      addressSpace = [
        replace(var.hubVirtualNetworks[0].addressSpace[0], virtualNetwork.addressSpace.search, virtualNetwork.addressSpace.replace)
      ]
      subnets = [
        for subnet in var.hubVirtualNetworks[0].subnets : merge(subnet, {
          addressSpace = [
            replace(subnet.addressSpace[0], virtualNetwork.addressSpace.search, virtualNetwork.addressSpace.replace)
          ]
        })
      ]
      resourceGroup = {
        id       = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.location}${virtualNetwork.extendedZone.enable ? ".${virtualNetwork.extendedZone.name}" : ""}"
        name     = "${var.resourceGroupName}.${virtualNetwork.location}${virtualNetwork.extendedZone.enable ? ".${virtualNetwork.extendedZone.name}" : ""}"
        location = virtualNetwork.location
      }
      extendedZone = virtualNetwork.extendedZone
    }) if virtualNetwork.enable
  ]
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key            = "${virtualNetwork.key}-${subnet.name}"
        location       = virtualNetwork.location
        resourceGroup  = virtualNetwork.resourceGroup
        virtualNetwork = virtualNetwork
      })
    ]
  ])
  virtualNetworksSubnetStorage = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Storage"
  ]
  virtualNetworksSubnetsSecurity = [
    for subnet in local.virtualNetworksSubnets : subnet if !contains(["GatewaySubnet","AzureFirewallSubnet","AzureFirewallManagementSubnet"], subnet.name)
  ]
}

resource azurerm_virtual_network main {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  edge_zone           = each.value.extendedZone != null && each.value.extendedZone.name != "" ? each.value.extendedZone.name : null
  address_space       = each.value.addressSpace
  dns_servers         = each.value.dnsAddresses
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_subnet main {
  for_each = {
    for subnet in local.virtualNetworksSubnets : subnet.key => subnet
  }
  name                                          = each.value.name
  resource_group_name                           = each.value.resourceGroup.name
  virtual_network_name                          = each.value.virtualNetwork.name
  address_prefixes                              = each.value.addressSpace
  service_endpoints                             = length(each.value.serviceEndpoints) > 0 ? each.value.serviceEndpoints : null
  private_endpoint_network_policies             = "Enabled"
  private_link_service_network_policies_enabled = true
  default_outbound_access_enabled               = false
  dynamic delegation {
    for_each = each.value.serviceDelegation != null ? [1] : []
    content {
      name = each.value.name
      service_delegation {
        name    = each.value.serviceDelegation.service
        actions = each.value.serviceDelegation.actions
      }
    }
  }
  depends_on = [
    azurerm_virtual_network.main
  ]
}

output virtualNetwork {
  value = {
    name          = local.virtualNetwork.name
    resourceGroup = local.virtualNetwork.resourceGroup
  }
}

output extendedZones {
  value = [
    for virtualNetwork in local.spokeVirtualNetworks : {
      name     = virtualNetwork.extendedZone.name
      location = virtualNetwork.extendedZone.location
    } if virtualNetwork.extendedZone.enable
  ]
}
