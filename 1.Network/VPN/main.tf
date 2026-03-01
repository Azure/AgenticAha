# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.62.0"
    }
  }
}

provider azurerm {
  features {
  }
  subscription_id = var.subscriptionId
}

variable subscriptionId {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable ipAddressPrefix {
  type = object({
    name              = string
    resourceGroupName = string
    activeActive = object({
      enable = bool
    })
  })
}

data azurerm_subscription current {}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet gateway {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

data azurerm_public_ip_prefix gateway {
  name                = var.ipAddressPrefix.name
  resource_group_name = var.ipAddressPrefix.resourceGroupName
}

data azurerm_resource_group network {
  name = data.azurerm_virtual_network.main.resource_group_name
}
