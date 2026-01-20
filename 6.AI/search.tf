# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################
# AI Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
####################################################################################

variable aiSearch {
  type = object({
    enable         = bool
    name           = string
    tier           = string
    hostingMode    = string
    replicaCount   = number
    partitionCount = number
    sharedPrivateAccess = object({
      enable = bool
    })
  })
}

resource azurerm_search_service main {
  count               = var.aiSearch.enable ? 1 : 0
  name                = var.aiSearch.name
  resource_group_name = azurerm_resource_group.ai_search[0].name
  location            = azurerm_resource_group.ai_search[0].location
  sku                 = var.aiSearch.tier
  hosting_mode        = var.aiSearch.hostingMode
  replica_count       = var.aiSearch.replicaCount
  partition_count     = var.aiSearch.partitionCount
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_rule_bypass_option = "AzureServices"
  allowed_ips = var.aiSearch.tier != "free" ? [
    jsondecode(data.http.client_address.response_body).ip
  ] : null
}

resource azurerm_search_shared_private_link_service main {
  count              = var.aiSearch.enable && var.aiSearch.sharedPrivateAccess.enable ? 1 : 0
  name               = azurerm_search_service.main[0].name
  search_service_id  = azurerm_search_service.main[0].id
  target_resource_id = data.azurerm_storage_account.main.id
  subresource_name   = "blob"
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone ai_search {
  count               = var.aiSearch.enable && var.aiSearch.tier != "free" ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.ai_search[0].name
}

resource azurerm_private_dns_zone_virtual_network_link ai_search {
  count                 = var.aiSearch.enable && var.aiSearch.tier != "free" ? 1 : 0
  name                  = "ai-search"
  resource_group_name   = azurerm_private_dns_zone.ai_search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_search[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_endpoint ai_search {
  count               = var.aiSearch.enable && var.aiSearch.tier != "free" ? 1 : 0
  name                = lower(azurerm_search_service.main[0].name)
  resource_group_name = azurerm_search_service.main[0].resource_group_name
  location            = azurerm_search_service.main[0].location
  subnet_id           = data.azurerm_subnet.ai.id
  private_service_connection {
    name                           = azurerm_search_service.main[0].name
    private_connection_resource_id = azurerm_search_service.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_search[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_search[0].id
    ]
  }
}
