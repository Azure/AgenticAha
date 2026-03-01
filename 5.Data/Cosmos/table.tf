# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################
# Cosmos DB Table (https://learn.microsoft.com/azure/cosmos-db/table/overview) #
################################################################################

variable table {
  type = object({
    enable = bool
    account = object({
      name = string
    })
    tables = list(object({
      enable     = bool
      name       = string
      throughput = number
    }))
  })
}

resource azurerm_cosmosdb_table tables {
  for_each = {
    for table in var.table.tables : table.name => table if table.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.main["table"].resource_group_name
  account_name        = azurerm_cosmosdb_account.main["table"].name
  throughput          = each.value.throughput
}

resource azurerm_private_dns_zone table {
  count               = var.table.enable ? 1 : 0
  name                = "privatelink.table.cosmos.azure.com"
  resource_group_name = azurerm_cosmosdb_account.main["table"].resource_group_name
}

resource azurerm_private_dns_zone_virtual_network_link table {
  count                 = var.table.enable ? 1 : 0
  name                  = "table"
  resource_group_name   = azurerm_private_dns_zone.table[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.table[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_endpoint table {
  count               = var.table.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.main["table"].name
  resource_group_name = azurerm_cosmosdb_account.main["table"].resource_group_name
  location            = azurerm_cosmosdb_account.main["table"].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.main["table"].name
    private_connection_resource_id = azurerm_cosmosdb_account.main["table"].id
    is_manual_connection           = false
    subresource_names = [
      "Table"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.table[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.table[0].id
    ]
  }
}

resource azurerm_private_endpoint table_sql {
  count               = var.table.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.main["table"].name
  resource_group_name = azurerm_cosmosdb_account.main["table"].resource_group_name
  location            = azurerm_cosmosdb_account.main["table"].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.main["table"].name
    private_connection_resource_id = azurerm_cosmosdb_account.main["table"].id
    is_manual_connection           = false
    subresource_names = [
      "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.sql.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.sql.id
    ]
  }
}
