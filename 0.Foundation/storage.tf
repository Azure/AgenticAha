# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

variable storage {
  type = object({
    account = object({
      type        = string
      redundancy  = string
      performance = string
    })
  })
}

locals {
  storage = {
    accountName = regex("storage_account_name${local.backendConfig.patternSuffix}", file("./backend.config"))[0]
    containerName = {
      terraformState = regex("container_name${local.backendConfig.patternSuffix}", file("./backend.config"))[0]
    }
  }
}

resource azurerm_role_assignment storage_blob_data_owner {
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.main.id
}

resource azurerm_role_assignment storage_blob_data_contributor {
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_storage_account.main.id
}

resource azurerm_storage_account main {
  name                              = local.storage.accountName
  resource_group_name               = azurerm_resource_group.foundation.name
  location                          = azurerm_resource_group.foundation.location
  account_kind                      = var.storage.account.type
  account_replication_type          = var.storage.account.redundancy
  account_tier                      = var.storage.account.performance
  infrastructure_encryption_enabled = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }
  network_rules {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  blob_properties {
    cors_rule {
      allowed_origins    = ["https://studio.discovery.microsoft.com","https://vscode.dev","https://*.vscode-cnd.net"]
      allowed_methods    = ["GET","HEAD","PUT","DELETE"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 200
    }
  }
}

resource azurerm_storage_container main {
  for_each = {
    for containerName in local.storage.containerName : containerName => containerName
  }
  name               = each.value
  storage_account_id = azurerm_storage_account.main.id
}
