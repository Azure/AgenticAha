# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################
# AI Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
####################################################################################

variable search {
  type = object({
    enable         = bool
    name           = string
    tier           = string
    hostingMode    = string
    replicaCount   = number
    partitionCount = number
  })
}

resource azurerm_search_service main {
  count               = var.search.enable ? 1 : 0
  name                = var.search.name
  resource_group_name = azurerm_resource_group.ai_search[0].name
  location            = azurerm_resource_group.ai_search[0].location
  sku                 = var.search.tier
  hosting_mode        = var.search.hostingMode
  replica_count       = var.search.replicaCount
  partition_count     = var.search.partitionCount
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_rule_bypass_option = "AzureServices"
}

###################################################################################################################
# Network Security Perimeter (https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts) #
###################################################################################################################

resource azurerm_network_security_perimeter_association search {
  count                                 = var.search.enable ? 1 : 0
  name                                  = "${azurerm_search_service.main[0].name}-search"
  resource_id                           = azurerm_search_service.main[0].id
  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.main.id
  access_mode                           = var.networkSecurityPerimeter.resourceAccessMode
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone search {
  count               = var.search.enable && var.search.tier != "free" ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.ai_search[0].name
}

resource azurerm_private_dns_zone_virtual_network_link search {
  count                 = var.search.enable && var.search.tier != "free" ? 1 : 0
  name                  = "ai-search"
  resource_group_name   = azurerm_private_dns_zone.search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].id
}

resource azurerm_private_endpoint search {
  count               = var.search.enable && var.search.tier != "free" ? 1 : 0
  name                = lower(azurerm_search_service.main[0].name)
  resource_group_name = azurerm_search_service.main[0].resource_group_name
  location            = azurerm_search_service.main[0].location
  subnet_id           = data.azurerm_subnet.ai_core.id
  private_service_connection {
    name                           = azurerm_search_service.main[0].name
    private_connection_resource_id = azurerm_search_service.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.search[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.search[0].id
    ]
  }
}
