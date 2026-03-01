# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

######################################################################################################
# Managed Lustre File System (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
######################################################################################################

variable lustreFiles {
  type = object({
    enable  = bool
    name    = string
    type    = string
    sizeTiB = number
    blobStorage = object({
      enable            = bool
      accountName       = string
      resourceGroupName = string
      containerName = object({
        archive = string
        logging = string
      })
      importPrefix = string
    })
    maintenanceWindow = object({
      dayOfWeek    = string
      utcStartTime = string
    })
  })
}

data azuread_service_principal lustre_files {
  count        = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  display_name = "HPC Cache Resource Provider"
}

data azurerm_storage_account lustre_files {
  count               = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  name                = var.lustreFiles.blobStorage.accountName
  resource_group_name = var.lustreFiles.blobStorage.resourceGroupName
}

resource azurerm_role_assignment lustre_storage_account_contributor {
  count                = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  role_definition_name = "Storage Account Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-account-contributor
  principal_id         = data.azuread_service_principal.lustre_files[0].object_id
  scope                = data.azurerm_storage_account.lustre_files[0].id
}

resource azurerm_role_assignment lustre_storage_blob_data_contributor {
  count                = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.lustre_files[0].object_id
  scope                = data.azurerm_storage_account.lustre_files[0].id
}

resource time_sleep lustre_storage_rbac {
  count           = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.lustre_storage_account_contributor,
    azurerm_role_assignment.lustre_storage_blob_data_contributor
  ]
}

resource azurerm_managed_lustre_file_system main {
  count                  = var.lustreFiles.enable ? 1 : 0
  name                   = var.lustreFiles.name
  resource_group_name    = azurerm_resource_group.lustre_files[0].name
  location               = azurerm_resource_group.lustre_files[0].location
  sku_name               = var.lustreFiles.type
  storage_capacity_in_tb = var.lustreFiles.sizeTiB
  subnet_id              = data.azurerm_subnet.storage.id
  zones                  = data.azurerm_location.main.zone_mappings[*].logical_zone
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  maintenance_window {
    day_of_week        = var.lustreFiles.maintenanceWindow.dayOfWeek
    time_of_day_in_utc = var.lustreFiles.maintenanceWindow.utcStartTime
  }
  dynamic hsm_setting {
    for_each = var.lustreFiles.blobStorage.enable ? [1] : []
    content {
      container_id         = azurerm_storage_container.lustre_files[0].id
      logging_container_id = azurerm_storage_container.lustre_logging[0].id
      import_prefix        = var.lustreFiles.blobStorage.importPrefix
    }
  }
  depends_on = [
    azurerm_storage_account.main,
    time_sleep.lustre_storage_rbac
  ]
}

resource azurerm_storage_container lustre_files {
  count              = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  name               = var.lustreFiles.blobStorage.containerName.archive
  storage_account_id = data.azurerm_storage_account.lustre_files[0].id
}

resource azurerm_storage_container lustre_logging {
  count              = var.lustreFiles.enable && var.lustreFiles.blobStorage.enable ? 1 : 0
  name               = var.lustreFiles.blobStorage.containerName.logging
  storage_account_id = data.azurerm_storage_account.lustre_files[0].id
}
