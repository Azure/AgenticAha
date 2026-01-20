# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################################################################################################
# Machine Learning (https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) #
#################################################################################################################

variable aiMachineLearning {
  type = object({
    enable = bool
    workspace = object({
      name   = string
      tier   = string
      type   = string
    })
  })
}

resource azurerm_machine_learning_workspace main {
  count                          = var.aiMachineLearning.enable ? 1 : 0
  name                           = var.aiMachineLearning.workspace.name
  resource_group_name            = azurerm_resource_group.ai_ml[0].name
  location                       = azurerm_resource_group.ai_ml[0].location
  sku_name                       = var.aiMachineLearning.workspace.tier
  kind                           = var.aiMachineLearning.workspace.type
  key_vault_id                   = data.azurerm_key_vault.main.id
  storage_account_id             = data.azurerm_storage_account.main.id
  primary_user_assigned_identity = data.azurerm_user_assigned_identity.main.id
  application_insights_id        = var.applicationInsights.enable ? data.azurerm_application_insights.main[0].id : null
  container_registry_id          = var.containerRegistry.enable ? data.azurerm_container_registry.main[0].id : null
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_storage_container ai_ml_workspace {
  count              = var.aiMachineLearning.enable ? 1 : 0
  name               = "ai-ml-workspace"
  storage_account_id = data.azurerm_storage_account.main.id
}

resource azurerm_machine_learning_datastore_datalake_gen2 main {
  count                = var.aiMachineLearning.enable ? 1 : 0
  name                 = var.aiMachineLearning.workspace.name
  workspace_id         = azurerm_machine_learning_workspace.main[0].id
  storage_container_id = azurerm_storage_container.ai_ml_workspace[0].id
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_endpoint ai_ml_workspace {
  count               = var.aiMachineLearning.enable ? 1 : 0
  name                = lower(azurerm_machine_learning_workspace.main[0].name)
  resource_group_name = azurerm_machine_learning_workspace.main[0].resource_group_name
  location            = azurerm_machine_learning_workspace.main[0].location
  subnet_id           = data.azurerm_subnet.ai.id
  private_service_connection {
    name                           = azurerm_machine_learning_workspace.main[0].name
    private_connection_resource_id = azurerm_machine_learning_workspace.main[0].id
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
