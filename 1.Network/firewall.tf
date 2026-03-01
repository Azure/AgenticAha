# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##################################################################
# Firewall (https://learn.microsoft.com/azure/firewall/overview) #
##################################################################

variable firewall {
  type = object({
    enable = bool
    name   = string
    tier   = string
    virtualWAN = object({
      enable = bool
    })
  })
}

resource azurerm_firewall_policy main {
  count               = var.firewall.enable ? 1 : 0
  name                = var.firewall.name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  sku                 = var.firewall.tier
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_firewall_policy_rule_collection_group main {
  count              = var.firewall.enable ? 1 : 0
  name               = azurerm_firewall_policy.main[0].name
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 1000
  network_rule_collection {
    name     = "Outbound"
    action   = "Allow"
    priority = 1000
    rule {
      name                  = "AllowInternet"
      protocols             = ["TCP","UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["*"]
    }
  }
}

############################
# Virtual Network Firewall #
############################

resource azurerm_public_ip virtual_network {
  count               = var.firewall.enable && !var.firewall.virtualWAN.enable ? 1 : 0
  name                = var.firewall.name
  resource_group_name = local.virtualNetwork.resourceGroup.name
  location            = local.virtualNetwork.resourceGroup.location
  sku                 = "Standard"
  allocation_method   = "Static"
  depends_on = [
    azurerm_resource_group.network
  ]
  lifecycle {
    ignore_changes = [
      ip_tags
    ]
  }
}

resource azurerm_firewall virtual_network {
  count               = var.firewall.enable && !var.firewall.virtualWAN.enable ? 1 : 0
  name                = var.firewall.name
  resource_group_name = azurerm_public_ip.virtual_network[0].resource_group_name
  location            = azurerm_public_ip.virtual_network[0].location
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  sku_tier            = var.firewall.tier
  sku_name            = "AZFW_VNet"
  ip_configuration {
    name      = "ipConfig"
    subnet_id = "${local.virtualNetwork.id}/subnets/AzureFirewallSubnet"
  }
  management_ip_configuration {
    name                 = "ipConfigManagement"
    subnet_id            = "${local.virtualNetwork.id}/subnets/AzureFirewallManagementSubnet"
    public_ip_address_id = azurerm_public_ip.virtual_network[0].id
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.main
  ]
}

########################
# Virtual WAN Firewall #
########################

resource azurerm_firewall virtual_wan {
  count               = var.firewall.enable && var.firewall.virtualWAN.enable && var.virtualWAN.enable ? 1 : 0
  name                = var.firewall.name
  resource_group_name = azurerm_virtual_wan.main[0].resource_group_name
  location            = azurerm_virtual_wan.main[0].location
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  sku_tier            = var.firewall.tier
  sku_name            = "AZFW_Hub"
  virtual_hub {
    virtual_hub_id = azurerm_virtual_hub.main[local.virtualNetwork.hubName].id
  }
}
