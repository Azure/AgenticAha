# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

variable privateDNS {
  type = object({
    zone = object({
      name = string
      autoRegistration = object({
        enable = bool
      })
    })
    resolver = object({
      enable = bool
      name   = string
      inbound = object({
        enable = bool
        name   = string
        subnet = object({
          name = string
        })
      })
      outbound = object({
        enable = bool
        name   = string
        subnet = object({
          name = string
        })
      })
    })
  })
}

resource azurerm_role_assignment private_dns_zone_contributor {
  role_definition_name = "Private DNS Zone Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/networking#private-dns-zone-contributor
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_private_dns_zone.main.id
}

resource azurerm_private_dns_zone main {
  name                = var.privateDNS.zone.name
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link main {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = each.value.key
  resource_group_name   = azurerm_private_dns_zone.main.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = each.value.id
  registration_enabled  = var.privateDNS.zone.autoRegistration.enable
  depends_on = [
    azurerm_virtual_network.main
  ]
}

##############################################################################################
# Private DNS Resolver (https://learn.microsoft.com/azure/dns/dns-private-resolver-overview) #
##############################################################################################

resource azurerm_private_dns_resolver main {
  count               = var.privateDNS.resolver.enable ? 1 : 0
  name                = var.privateDNS.resolver.name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  virtual_network_id  = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_private_dns_resolver_inbound_endpoint main {
  count                   = var.privateDNS.resolver.enable && var.privateDNS.resolver.inbound.enable ? 1 : 0
  name                    = var.privateDNS.resolver.inbound.name
  private_dns_resolver_id = azurerm_private_dns_resolver.main[0].id
  location                = azurerm_private_dns_resolver.main[0].location
  ip_configurations {
    subnet_id                    = "${azurerm_private_dns_resolver.main[0].virtual_network_id}/subnets/${var.privateDNS.resolver.inbound.subnet.name}"
    private_ip_allocation_method = "Dynamic"
  }
}

resource azurerm_private_dns_resolver_outbound_endpoint main {
  count                   = var.privateDNS.resolver.enable && var.privateDNS.resolver.outbound.enable ? 1 : 0
  name                    = var.privateDNS.resolver.outbound.name
  private_dns_resolver_id = azurerm_private_dns_resolver.main[0].id
  location                = azurerm_private_dns_resolver.main[0].location
  subnet_id               = "${azurerm_private_dns_resolver.main[0].virtual_network_id}/subnets/${var.privateDNS.resolver.outbound.subnet.name}"
}
