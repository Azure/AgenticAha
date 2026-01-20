# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################################################################
# Virtual WAN (https://learn.microsoft.com/azure/virtual-wan/virtual-wan-about) #
#################################################################################

variable virtualWAN {
  type = object({
    enable = bool
    name   = string
    type   = string
    hubs = list(object({
      enable       = bool
      name         = string
      type         = string
      location     = string
      addressSpace = string
      router = object({
        preferenceMode = string
        scaleUnit = object({
          minCount = number
        })
        routes = list(object({
          enable         = bool
          name           = string
          addressSpace   = list(string)
          nextHopAddress = string
        }))
        branchToBranch = object({
          enable = bool
        })
      })
    }))
    branchToBranch = object({
      enable = bool
    })
    vpnGateway = object({
      enable  = bool
      name    = string
      connections = list(object({
        enable     = bool
        name       = string
        vwHubName  = string
        scaleUnits = number
        siteToSite = object({
          enable       = bool
          addressSpace = list(string)
          link = object({
            enable  = bool
            fqdn    = string
            address = string
          })
          bgp = object({
            enable = bool
            asn    = number
            peering = object({
              address = string
            })
          })
        })
        pointToSite = object({
          enable = bool
          client = object({
            addressSpace = list(string)
          })
        })
      }))
    })
  })
}

resource azurerm_virtual_wan main {
  count                          = var.virtualWAN.enable ? 1 : 0
  name                           = var.virtualWAN.name
  resource_group_name            = azurerm_resource_group.network.name
  location                       = azurerm_resource_group.network.location
  type                           = var.virtualWAN.type
  allow_branch_to_branch_traffic = var.virtualWAN.branchToBranch.enable
}

resource azurerm_virtual_hub main {
  for_each = {
    for hub in var.virtualWAN.hubs : hub.name => hub if var.virtualWAN.enable && hub.enable
  }
  name                                   = each.value.name
  resource_group_name                    = azurerm_virtual_wan.main[0].resource_group_name
  location                               = each.value.location
  virtual_wan_id                         = azurerm_virtual_wan.main[0].id
  sku                                    = each.value.type
  address_prefix                         = each.value.addressSpace
  hub_routing_preference                 = each.value.router.preferenceMode
  virtual_router_auto_scale_min_capacity = each.value.router.scaleUnit.minCount
  branch_to_branch_traffic_enabled       = each.value.router.branchToBranch.enable
  dynamic route {
    for_each = {
      for route in each.value.router.routes : route.name => route if route.enable
    }
    content {
      address_prefixes    = route.addressSpace
      next_hop_ip_address = route.nextHopAddress
    }
  }
}

resource azurerm_virtual_hub_connection main {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.virtualWAN.enable && virtualNetwork.vwHubName != ""
  }
  name                      = each.value.key
  remote_virtual_network_id = each.value.id
  virtual_hub_id            = azurerm_virtual_hub.main[each.value.vwHubName].id
}
