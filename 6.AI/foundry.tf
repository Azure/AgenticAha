# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##########################################################################################################
# Microsoft Foundry (https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry?view=foundry) #
##########################################################################################################

variable aiFoundry {
  type = object({
    enable = bool
    name   = string
    highBusinessImpact = object({
      enable = bool
    })
    projects = list(object({
      enable = bool
      name   = string
      highBusinessImpact = object({
        enable = bool
      })
    }))
  })
}

resource azurerm_ai_foundry main {
  count                          = var.aiFoundry.enable ? 1 : 0
  name                           = var.aiFoundry.name
  resource_group_name            = azurerm_resource_group.ai_foundry[0].name
  location                       = azurerm_resource_group.ai_foundry[0].location
  key_vault_id                   = data.azurerm_key_vault.main.id
  storage_account_id             = data.azurerm_storage_account.main.id
  application_insights_id        = var.applicationInsights.enable ? data.azurerm_application_insights.main[0].id : null
  container_registry_id          = var.containerRegistry.enable ? data.azurerm_container_registry.main[0].id : null
  high_business_impact_enabled   = var.aiFoundry.highBusinessImpact.enable
  primary_user_assigned_identity = data.azurerm_user_assigned_identity.main.id
  public_network_access          = "Disabled"
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_ai_foundry_project main {
  for_each = {
    for project in var.aiFoundry.projects : project.name => project if var.aiFoundry.enable && project.enable
  }
  name                         = each.value.name
  location                     = azurerm_ai_foundry.main[0].location
  ai_services_hub_id           = azurerm_ai_foundry.main[0].id
  high_business_impact_enabled = each.value.highBusinessImpact.enable
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_endpoint ai_foundry {
  count               = var.aiFoundry.enable ? 1 : 0
  name                = lower(azurerm_ai_foundry.main[0].name)
  resource_group_name = azurerm_ai_foundry.main[0].resource_group_name
  location            = azurerm_ai_foundry.main[0].location
  subnet_id           = data.azurerm_subnet.ai.id
  private_service_connection {
    name                           = azurerm_ai_foundry.main[0].name
    private_connection_resource_id = azurerm_ai_foundry.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "amlworkspace"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_ml[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_ml[0].id
    ]
  }
}
