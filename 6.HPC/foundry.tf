# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##########################################################################################################
# Microsoft Foundry (https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry?view=foundry) #
#                   (https://learn.microsoft.com/azure/ai-foundry/concepts/architecture?view=foundry)    #
##########################################################################################################

variable foundry {
  type = object({
    enable = bool
    name   = string
    tier   = string
    subDomain = object({
      name = string
    })
    projects = list(object({
      enable      = bool
      name        = string
      displayName = string
      description = string
    }))
  })
}

resource azurerm_cognitive_account foundry {
  count                         = var.foundry.enable ? 1 : 0
  name                          = var.foundry.name
  resource_group_name           = azurerm_resource_group.ai_foundry[0].name
  location                      = azurerm_resource_group.ai_foundry[0].location
  sku_name                      = var.foundry.tier
  custom_subdomain_name         = var.foundry.subDomain.name
  kind                          = "AIServices"
  project_management_enabled    = true
  public_network_access_enabled = false
  local_auth_enabled            = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_injection {
    subnet_id = data.azurerm_subnet.ai_agent[0].id
    scenario  = "agent"
  }
  storage {
    storage_account_id = data.azurerm_storage_account.main.id
    identity_client_id = data.azurerm_user_assigned_identity.main.client_id
   }
}

resource azurerm_cognitive_account_project foundry {
  for_each = {
    for project in var.foundry.projects : project.name => project if project.enable && var.foundry.enable
  }
  name                 = each.value.name
  display_name         = each.value.displayName != "" ? each.value.displayName : null
  description          = each.value.description != "" ? each.value.description : null
  location             = azurerm_cognitive_account.foundry[0].location
  cognitive_account_id = azurerm_cognitive_account.foundry[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
}

###################################################################################################################
# Network Security Perimeter (https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts) #
###################################################################################################################

resource azurerm_network_security_perimeter_association foundry {
  count                                 = var.foundry.enable ? 1 : 0
  name                                  = "${azurerm_cognitive_account.foundry[0].name}-foundry"
  resource_id                           = azurerm_cognitive_account.foundry[0].id
  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.main.id
  access_mode                           = var.networkSecurityPerimeter.resourceAccessMode
}

# ###############################################################################################
# # Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
# ###############################################################################################

resource azurerm_private_dns_zone ai_cognitive {
  count               = var.foundry.enable ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.ai_foundry[0].name
}

resource azurerm_private_dns_zone ai_services {
  count               = var.foundry.enable ? 1 : 0
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.ai_foundry[0].name
}

resource azurerm_private_dns_zone ai_open {
  count               = var.foundry.enable ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.ai_foundry[0].name
}

resource azurerm_private_dns_zone_virtual_network_link ai_cognitive {
  count                 = var.foundry.enable ? 1 : 0
  name                  = "ai-cognitive"
  resource_group_name   = azurerm_private_dns_zone.ai_cognitive[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_cognitive[0].name
  virtual_network_id    = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].id
}

resource azurerm_private_dns_zone_virtual_network_link ai_services {
  count                 = var.foundry.enable ? 1 : 0
  name                  = "ai-services"
  resource_group_name   = azurerm_private_dns_zone.ai_services[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services[0].name
  virtual_network_id    = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].id
}

resource azurerm_private_dns_zone_virtual_network_link ai_open {
  count                 = var.foundry.enable ? 1 : 0
  name                  = "ai-open"
  resource_group_name   = azurerm_private_dns_zone.ai_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_open[0].name
  virtual_network_id    = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].id
}

resource azurerm_private_endpoint foundry {
  count               = var.foundry.enable ? 1 : 0
  name                = lower(azurerm_cognitive_account.foundry[0].name)
  resource_group_name = azurerm_cognitive_account.foundry[0].resource_group_name
  location            = azurerm_cognitive_account.foundry[0].location
  subnet_id           = data.azurerm_subnet.ai_core.id
  private_service_connection {
    name                           = azurerm_cognitive_account.foundry[0].name
    private_connection_resource_id = azurerm_cognitive_account.foundry[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_cognitive[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_cognitive[0].id,
      azurerm_private_dns_zone.ai_services[0].id,
      azurerm_private_dns_zone.ai_open[0].id
    ]
  }
}
