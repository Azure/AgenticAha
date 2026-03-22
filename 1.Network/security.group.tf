# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

########################################################################################################################
# Virtual Network Security Groups (https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview) #
########################################################################################################################

resource azurerm_network_security_group main {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name != "AzureBastionSubnet"
  }
  name                = each.value.key
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  security_rule {
    name                       = "AllowOutARM"
    priority                   = 3100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureResourceManager"
    destination_port_range     = "*"
  }
  security_rule {
    name                       = "AllowOutStorage"
    priority                   = 3000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Storage"
    destination_port_range     = "*"
  }
  dynamic security_rule {
    for_each = each.value.name == "DMZ" ? [1] : []
    content {
      name                       = "AllowInGateway"
      priority                   = 350
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "20001-23000"
    }
  }
  dynamic security_rule {
    for_each = each.value.name == "DMZ" ? [1] : []
    content {
      name                       = "AllowInHTTP"
      priority                   = 340
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "80"
    }
  }
  dynamic security_rule {
    for_each = each.value.name == "DMZ" ? [1] : []
    content {
      name                       = "AllowInHTTPS"
      priority                   = 320
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
    }
  }
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_subnet_network_security_group_association main {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name != "AzureBastionSubnet"
  }
  subnet_id                 = "${each.value.virtualNetwork.id}/subnets/${each.value.name}"
  network_security_group_id = azurerm_network_security_group.main[each.value.key].id
  depends_on = [
    azurerm_subnet.main
  ]
}
