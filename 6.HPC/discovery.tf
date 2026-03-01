# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###########################################################
# Microsoft Discovery (https://aka.ms/MicrosoftDiscovery) #
###########################################################

variable discovery {
  type = object({
    enable = bool
    name   = string
    region = object({
      hub = string
      spoke = list(object({
        enable   = bool
        location = string
      }))
    })
    sharedStorage = object({
      enable = bool
    })
  })
}

resource azurerm_role_assignment discovery_contributor {
  count                = var.discovery.enable ? 1 : 0
  role_definition_name = "Microsoft Discovery Platform Contributor (Preview)"
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_resource_group.ai_discovery[0].id
}

resource azurerm_storage_container discovery_output {
  count              = var.discovery.enable ? 1 : 0
  name               = "discoveryoutputs"
  storage_account_id = data.azurerm_storage_account.main.id
}

resource azapi_resource discovery_storage {
  count     = var.discovery.enable && var.discovery.sharedStorage.enable ? 1 : 0
  name      = var.discovery.name
  type      = "Microsoft.Discovery/storages@2025-07-01-preview"
  parent_id = azurerm_resource_group.ai_discovery[0].id
  location  = azurerm_resource_group.ai_discovery[0].location
  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     data.azurerm_user_assigned_identity.main.id
  #   ]
  # }
  body = {
    properties = {
      store = {
        kind = "AzureNetApp"
      }
      subnetId = data.azurerm_subnet.ai_discovery_storage[0].id
    }
  }
  schema_validation_enabled = false
}

resource azapi_resource discovery_compute {
  count     = var.discovery.enable ? 1 : 0
  name      = var.discovery.name
  type      = "Microsoft.Discovery/supercomputers@2025-07-01-preview"
  parent_id = azurerm_resource_group.ai_discovery[0].id
  location  = azurerm_resource_group.ai_discovery[0].location
  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     data.azurerm_user_assigned_identity.main.id
  #   ]
  # }
  body = {
    properties = {
      identities = {
        clusterIdentity = {
          id = data.azurerm_user_assigned_identity.main.id
        }
        kubeletIdentity = {
          id = data.azurerm_user_assigned_identity.main.id
        }
        workloadIdentities = {
          "${data.azurerm_user_assigned_identity.main.id}" = {}
        }
      }
      subnetId = data.azurerm_subnet.ai_discovery_compute[0].id
    }
  }
  schema_validation_enabled = false
  timeouts {
    create = "60m"
  }
}
