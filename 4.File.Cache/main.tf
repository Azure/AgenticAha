# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.57.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.8.0"
    }
  }
  backend azurerm {
    key              = "4.File.Cache"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    netapp {
      prevent_volume_destruction             = false
      delete_backups_on_backup_vault_destroy = true
    }
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

variable virtualNetworkStorage {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

variable virtualNetworkCache {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

variable netAppFiles {
  type = object({
    accountName       = string
    capacityPoolName  = string
    resourceGroupName = string
  })
}

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../0.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity main {
  name                = data.terraform_remote_state.foundation.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_virtual_network storage {
  name                = var.virtualNetworkStorage.name
  resource_group_name = var.virtualNetworkStorage.resourceGroupName
}

data azurerm_virtual_network cache {
  name                = var.virtualNetworkCache.name
  resource_group_name = var.virtualNetworkCache.resourceGroupName
}

data azurerm_subnet storage {
  name                 = var.virtualNetworkStorage.subnetName
  resource_group_name  = data.azurerm_virtual_network.storage.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.storage.name
}

data azurerm_subnet cache {
  name                 = var.virtualNetworkCache.subnetName
  resource_group_name  = data.azurerm_virtual_network.cache.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.cache.name
}

data azurerm_resource_group cache {
  name = var.netAppFiles.resourceGroupName
}
