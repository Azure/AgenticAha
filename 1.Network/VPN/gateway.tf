# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#############################################################################################
# VPN Gateway (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
#############################################################################################

variable vpnGateway {
  type = object({
    name       = string
    type       = string
    vpnType    = string
    generation = string
    sharedKey  = string
    enableBgp  = bool
    pointToSite = object({
      enable = bool
      client = object({
        addressSpace = list(string)
      })
    })
  })
}

resource azurerm_public_ip gateway1 {
  name                 = "Gateway1"
  resource_group_name  = data.azurerm_public_ip_prefix.gateway.resource_group_name
  location             = data.azurerm_public_ip_prefix.gateway.location
  sku                  = data.azurerm_public_ip_prefix.gateway.sku
  public_ip_prefix_id  = data.azurerm_public_ip_prefix.gateway.id
  allocation_method    = "Static"
}

resource azurerm_public_ip gateway2 {
  count                = var.ipAddressPrefix.activeActive.enable ? 1 : 0
  name                 = "Gateway2"
  resource_group_name  = data.azurerm_public_ip_prefix.gateway.resource_group_name
  location             = data.azurerm_public_ip_prefix.gateway.location
  sku                  = data.azurerm_public_ip_prefix.gateway.sku
  public_ip_prefix_id  = data.azurerm_public_ip_prefix.gateway.id
  allocation_method    = "Static"
}

resource azurerm_virtual_network_gateway vpn {
  name                = var.vpnGateway.name
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  type                = "Vpn"
  sku                 = var.vpnGateway.type
  vpn_type            = var.vpnGateway.vpnType
  generation          = var.vpnGateway.generation
  enable_bgp          = var.vpnGateway.enableBgp
  active_active       = var.ipAddressPrefix.activeActive.enable
  ip_configuration {
    name                 = "ipConfig1"
    subnet_id            = data.azurerm_subnet.gateway.id
    public_ip_address_id = azurerm_public_ip.gateway1.id
  }
  dynamic ip_configuration {
    for_each = var.ipAddressPrefix.activeActive.enable ? [1] : []
    content {
      name                 = "ipConfig2"
      subnet_id            = data.azurerm_subnet.gateway.id
      public_ip_address_id = azurerm_public_ip.gateway2[0].id
    }
  }
  dynamic vpn_client_configuration {
    for_each = var.vpnGateway.pointToSite.enable ? [1] : []
    content {
      address_space        = var.vpnGateway.pointToSite.client.addressSpace
      vpn_client_protocols = ["OpenVPN"]
      vpn_auth_types       = ["AAD"]
      aad_tenant           = "https://login.microsoftonline.com/${data.azurerm_subscription.current.tenant_id}"
      aad_issuer           = "https://sts.windows.net/${data.azurerm_subscription.current.tenant_id}/"
      aad_audience         = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8" # Azure VPN Client
    }
  }
}
