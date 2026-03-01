# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/overview) #
####################################################################

variable cosmos {
  type = object({
    type = string
    geoLocations = list(object({
      enable = bool
      name   = string
      failover = object({
        priority = number
      })
      zoneRedundant = object({
        enable = bool
      })
    }))
    dataConsistency = object({
      policyLevel = string
      maxStaleness = object({
        intervalSeconds = number
        itemUpdateCount = number
      })
    })
    serverless = object({
      enable = bool
    })
    burstCapacity = object({
      enable = bool
    })
    dataAnalytics = object({
      enable     = bool
      schemaType = string
    })
    aggregationPipeline = object({
      enable = bool
    })
    automaticFailover = object({
      enable = bool
    })
    multiRegionWrite = object({
      enable = bool
    })
    partitionMerge = object({
      enable = bool
    })
    backup = object({
      type              = string
      tier              = string
      retentionHours    = number
      intervalMinutes   = number
      storageRedundancy = string
    })
  })
}

data azuread_service_principal cosmos_db {
  display_name = "Azure Cosmos DB"
}

locals {
  cosmosAccounts = [
    {
      enable = true
      id     = "${azurerm_resource_group.data_cosmos.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.noSQL.account.name}"
      name   = var.noSQL.account.name
      type   = "sql"
    },
    {
      enable = var.mongoDB.enable
      id     = "${azurerm_resource_group.data_cosmos.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.mongoDB.account.name}"
      name   = var.mongoDB.account.name
      type   = "mongo"
    },
    {
      enable = var.table.enable
      id     = "${azurerm_resource_group.data_cosmos.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.table.account.name}"
      name   = var.table.account.name
      type   = "table"
    }
  ]
}

resource azurerm_cosmosdb_account main {
  for_each = {
    for account in local.cosmosAccounts : account.type => account if account.enable
  }
  name                             = each.value.name
  resource_group_name              = azurerm_resource_group.data_cosmos.name
  location                         = azurerm_resource_group.data_cosmos.location
  kind                             = each.value.type == "mongo" ? "MongoDB" : "GlobalDocumentDB"
  mongo_server_version             = each.value.type == "mongo" ? var.mongoDB.account.version : null
  offer_type                       = var.cosmos.type
  burst_capacity_enabled           = var.cosmos.burstCapacity.enable
  analytical_storage_enabled       = var.cosmos.dataAnalytics.enable
  partition_merge_enabled          = var.cosmos.partitionMerge.enable
  multiple_write_locations_enabled = var.cosmos.multiRegionWrite.enable
  automatic_failover_enabled       = var.cosmos.automaticFailover.enable
  public_network_access_enabled    = false
  local_authentication_disabled    = true
  default_identity_type            = "UserAssignedIdentity=${data.azurerm_user_assigned_identity.main.id}"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  consistency_policy {
    consistency_level       = var.cosmos.dataConsistency.policyLevel
    max_staleness_prefix    = var.cosmos.dataConsistency.maxStaleness.itemUpdateCount
    max_interval_in_seconds = var.cosmos.dataConsistency.maxStaleness.intervalSeconds
  }
  backup {
    type                = var.cosmos.backup.type
    tier                = var.cosmos.backup.tier
    retention_in_hours  = var.cosmos.backup.retentionHours
    interval_in_minutes = var.cosmos.backup.intervalMinutes
    storage_redundancy  = var.cosmos.backup.storageRedundancy
  }
  dynamic geo_location {
    for_each = {
      for geoLocation in var.cosmos.geoLocations : geoLocation.name => geoLocation if geoLocation.enable
    }
    content {
      location          = geo_location.value["name"]
      failover_priority = geo_location.value["failover"].priority
      zone_redundant    = geo_location.value["zoneRedundant"].enable
    }
  }
  dynamic analytical_storage {
    for_each = var.cosmos.dataAnalytics.enable ? [1] : []
    content {
      schema_type = var.cosmos.dataAnalytics.schemaType
    }
  }
  dynamic capabilities {
    for_each = var.cosmos.serverless.enable ? ["EnableServerless"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = var.cosmos.aggregationPipeline.enable ? ["EnableAggregationPipeline"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "sql" ? ["EnableNoSQLFullTextSearch", "EnableNoSQLVectorSearch"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "mongo" ? ["EnableMongo", "EnableMongoRoleBasedAccessControl"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "table" ? ["EnableTable"] : []
    content {
      name = capabilities.value
    }
  }
}

###################################################################################################################
# Network Security Perimeter (https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts) #
###################################################################################################################

resource azurerm_network_security_perimeter_association cosmos {
  for_each = {
    for account in local.cosmosAccounts : account.type => account if account.enable
  }
  name                                  = "${azurerm_cosmosdb_account.main[each.value.type].name}-cosmos"
  resource_id                           = azurerm_cosmosdb_account.main[each.value.type].id
  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.main.id
  access_mode                           = var.networkSecurityPerimeter.resourceAccessMode
}
