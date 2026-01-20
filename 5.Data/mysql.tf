# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

############################################################################################
# MySQL Flexible Server (https://learn.microsoft.com/azure/mysql/flexible-server/overview) #
############################################################################################

variable mySQL {
  type = object({
    enable  = bool
    name    = string
    type    = string
    version = string
    authentication = object({
      sql = object({
        enable = bool
      })
      activeDirectory = object({
        enable = bool
      })
    })
    storage = object({
      sizeGB = number
      iops   = number
      autoGrow = object({
        enabled = bool
      })
      ioScaling = object({
        enabled = bool
      })
    })
    backup = object({
      retentionDays = number
      geoRedundant = object({
        enable = bool
      })
      vault = object({
        enable     = bool
        name       = string
        type       = string
        redundancy = string
        softDelete = string
        retention = object({
          days = number
        })
        crossRegion = object({
          enable = bool
        })
      })
    })
    highAvailability = object({
      enable = bool
      mode   = string
    })
    maintenanceWindow = object({
      enable    = bool
      dayOfWeek = number
      start = object({
        hour   = number
        minute = number
      })
    })
    databases = list(object({
      enable    = bool
      name      = string
      charset   = string
      collation = string
    }))
  })
}

resource azurerm_mysql_flexible_server main {
  count                        = var.mySQL.enable ? 1 : 0
  name                         = var.mySQL.name
  resource_group_name          = azurerm_resource_group.data_sql[0].name
  location                     = azurerm_resource_group.data_sql[0].location
  sku_name                     = var.mySQL.type
  version                      = var.mySQL.version
  backup_retention_days        = var.mySQL.backup.retentionDays
  geo_redundant_backup_enabled = var.mySQL.backup.geoRedundant.enable
  administrator_login          = var.mySQL.authentication.sql.enable ? data.azurerm_key_vault_secret.admin_username.value : null
  administrator_password       = var.mySQL.authentication.sql.enable ? data.azurerm_key_vault_secret.admin_password.value : null
  delegated_subnet_id          = data.azurerm_subnet.data_mysql[0].id
  private_dns_zone_id          = azurerm_private_dns_zone.mysql[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  storage {
    size_gb            = var.mySQL.storage.sizeGB
    iops               = var.mySQL.storage.ioScaling.enabled ? null : var.mySQL.storage.iops
    auto_grow_enabled  = var.mySQL.storage.autoGrow.enabled
    io_scaling_enabled = var.mySQL.storage.ioScaling.enabled
  }
  dynamic maintenance_window {
    for_each = var.mySQL.maintenanceWindow.enable ? [1] : []
    content {
      day_of_week  = var.mySQL.maintenanceWindow.dayOfWeek
      start_hour   = var.mySQL.maintenanceWindow.start.hour
      start_minute = var.mySQL.maintenanceWindow.start.minute
    }
  }
  dynamic high_availability {
    for_each = var.mySQL.highAvailability.enable ? [1] : []
    content {
      mode = var.mySQL.highAvailability.mode
    }
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]
}

resource azurerm_mysql_flexible_server_firewall_rule main {
  count               = var.mySQL.enable ? 1 : 0
  name                = "AllowCurrentIP"
  resource_group_name = azurerm_resource_group.data_sql[0].name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  start_ip_address    = jsondecode(data.http.client_address.response_body).ip
  end_ip_address      = jsondecode(data.http.client_address.response_body).ip
}

resource azurerm_mysql_flexible_server_active_directory_administrator main {
  count       = var.mySQL.enable && var.mySQL.authentication.activeDirectory.enable ? 1 : 0
  tenant_id   = data.azurerm_user_assigned_identity.main.tenant_id
  server_id   = azurerm_mysql_flexible_server.main[0].id
  identity_id = data.azurerm_user_assigned_identity.main.id
  object_id   = data.azurerm_user_assigned_identity.main.principal_id
  login       = data.azurerm_user_assigned_identity.main.client_id
}

resource azurerm_mysql_flexible_database main {
  for_each = {
    for database in var.mySQL.databases : database.name => database if database.enable && var.mySQL.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.data_sql[0].name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  charset             = each.value.charset
  collation           = each.value.collation
}

#######################################################################################
# Private DNS Zone (https://learn.microsoft.com/azure/dns/private-dns-privatednszone) #
#######################################################################################

resource azurerm_private_dns_zone mysql {
  count               = var.mySQL.enable ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.data_sql[0].name
}

resource azurerm_private_dns_zone_virtual_network_link mysql {
  count                 = var.mySQL.enable ? 1 : 0
  name                  = "mysql"
  resource_group_name   = azurerm_private_dns_zone.mysql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

#################################################################################
# Backup Vault (https://learn.microsoft.com/azure/backup/backup-vault-overview) #
#################################################################################

resource azurerm_data_protection_backup_vault mysql {
  count                        = var.mySQL.enable && var.mySQL.backup.vault.enable ? 1 : 0
  name                         = var.mySQL.backup.vault.name
  resource_group_name          = azurerm_mysql_flexible_server.main[0].resource_group_name
  location                     = azurerm_mysql_flexible_server.main[0].location
  datastore_type               = var.mySQL.backup.vault.type
  redundancy                   = var.mySQL.backup.vault.redundancy
  soft_delete                  = var.mySQL.backup.vault.softDelete
  retention_duration_in_days   = var.mySQL.backup.vault.retention.days
  cross_region_restore_enabled = var.mySQL.backup.vault.crossRegion.enable
  identity {
    type = "SystemAssigned"
  }
}

output mySQL {
  value = var.mySQL.enable ? {
    fqdn = azurerm_mysql_flexible_server.main[0].fqdn
    zone = azurerm_mysql_flexible_server.main[0].zone
    highAvailability = var.mySQL.highAvailability.enable ? {
      mode        = azurerm_mysql_flexible_server.main[0].high_availability[0].mode
      standbyZone = azurerm_mysql_flexible_server.main[0].high_availability[0].standby_availability_zone
    } : null
    authentication = var.mySQL.authentication
  } : null
}
