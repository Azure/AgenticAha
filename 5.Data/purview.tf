# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#########################################################
# Purview (https://learn.microsoft.com/purview/purview) #
#########################################################

variable purview {
  type = object({
    enable = bool
    name   = string
  })
}

resource azurerm_purview_account main {
  count                       = var.purview.enable ? 1 : 0
  name                        = var.purview.name
  resource_group_name         = azurerm_resource_group.data.name
  location                    = azurerm_resource_group.data.location
  managed_resource_group_name = "${azurerm_resource_group.data.name}.Managed"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_private_dns_zone purview {
  count               = var.purview.enable ? 1 : 0
  name                = "privatelink.purview.azure.com"
  resource_group_name = azurerm_resource_group.data.name
}

resource azurerm_private_dns_zone_virtual_network_link purview {
  count                 = var.purview.enable ? 1 : 0
  name                  = "purview"
  resource_group_name   = azurerm_private_dns_zone.purview[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.purview[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_endpoint purview {
  count               = var.purview.enable ? 1 : 0
  name                = "${azurerm_purview_account.main[0].name}-${azurerm_private_dns_zone_virtual_network_link.purview[0].name}"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_purview_account.main[0].name
    private_connection_resource_id = azurerm_purview_account.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.purview[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.purview[0].id
    ]
  }
}

output purview {
  value = var.purview.enable ? {
    id = azurerm_purview_account.main[0].id
  } : null
}
