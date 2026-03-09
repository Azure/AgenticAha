# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################################
# Virtual WAN VPN Gateway (https://learn.microsoft.com/azure/virtual-wan/connect-virtual-network-gateway-vwan) #
################################################################################################################

resource azurerm_vpn_gateway main {
  for_each = {
    for connection in var.virtualWAN.vpnGateway.connections : connection.name => connection if var.virtualWAN.enable && var.virtualWAN.vpnGateway.enable && connection.siteToSite.enable && connection.enable
  }
  name                = "${var.virtualWAN.vpnGateway.name}-${each.value.name}"
  resource_group_name = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location            = azurerm_virtual_hub.main[each.value.hubName].location
  virtual_hub_id      = azurerm_virtual_hub.main[each.value.hubName].id
  scale_unit          = each.value.scaleUnits
}

resource azurerm_vpn_site main {
  for_each = {
    for connection in var.virtualWAN.vpnGateway.connections : connection.name => connection if var.virtualWAN.enable && var.virtualWAN.vpnGateway.enable && connection.siteToSite.enable && connection.enable
  }
  name                = "${var.virtualWAN.vpnGateway.name}-${each.value.name}"
  resource_group_name = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location            = azurerm_virtual_hub.main[each.value.hubName].location
  virtual_wan_id      = azurerm_virtual_wan.main[0].id
  address_cidrs       = each.value.siteToSite.addressSpace
  dynamic link {
    for_each = each.value.siteToSite.link.enable ? [1] : []
    content {
      name       = "default"
      fqdn       = each.value.fqdn != "" ? each.value.fqdn : null
      ip_address = each.value.address != "" ? each.value.address : null
      dynamic bgp {
        for_each = each.value.siteToSite.bgp.enable ? [1] : []
        content {
          asn             = each.value.siteToSite.bgp.asn
          peering_address = each.value.siteToSite.bgp.peering.address
        }
      }
    }
  }
}

################################################################################################################
# Virtual WAN VPN Gateway Point-to-Site (https://learn.microsoft.com/azure/virtual-wan/point-to-site-concepts) #
################################################################################################################

resource azurerm_vpn_server_configuration main {
  for_each = {
    for connection in var.virtualWAN.vpnGateway.connections : connection.name => connection if var.virtualWAN.enable && var.virtualWAN.vpnGateway.enable && connection.pointToSite.enable && connection.enable
  }
  name                     = "${var.virtualWAN.vpnGateway.name}-${each.value.name}"
  resource_group_name      = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location                 = azurerm_virtual_hub.main[each.value.hubName].location
  vpn_protocols            = ["OpenVPN"]
  vpn_authentication_types = ["AAD"]
  azure_active_directory_authentication {
    tenant   = "https://login.microsoftonline.com/${data.azurerm_subscription.current.tenant_id}"
    issuer   = "https://sts.windows.net/${data.azurerm_subscription.current.tenant_id}/"
    audience = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8" # Azure VPN Client
  }
}

resource azurerm_point_to_site_vpn_gateway main {
  for_each = {
    for connection in var.virtualWAN.vpnGateway.connections : connection.name => connection if var.virtualWAN.enable && var.virtualWAN.vpnGateway.enable && connection.pointToSite.enable && connection.enable
  }
  name                        = "${var.virtualWAN.vpnGateway.name}-${each.value.name}"
  resource_group_name         = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location                    = azurerm_virtual_hub.main[each.value.hubName].location
  virtual_hub_id              = azurerm_virtual_hub.main[each.value.hubName].id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.main[each.value.name].id
  scale_unit                  = each.value.scaleUnits
  connection_configuration {
    name = var.virtualWAN.vpnGateway.name
    vpn_client_address_pool {
      address_prefixes = each.value.pointToSite.client.addressSpace
    }
  }
}
