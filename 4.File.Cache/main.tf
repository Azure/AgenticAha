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
  backend azurerm {
    key              = "4.File.Cache"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    netapp {
      prevent_volume_destruction             = var.netAppFiles.volumeDestruction.prevent
      delete_backups_on_backup_vault_destroy = true
    }
    template_deployment {
      delete_nested_items_during_deletion = true
    }
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

variable managedIdentity {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable keyVault {
  type = object({
    name              = string
    resourceGroupName = string
    secretName = object({
      adminUsername = string
      adminPassword = string
    })
  })
}

variable virtualNetworkStorage {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
    securityGroupName = string
  })
}

variable virtualNetworkCache {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

data azurerm_subscription current {}

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../0.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity main {
  name                = var.managedIdentity.name
  resource_group_name = var.managedIdentity.resourceGroupName
}

data azurerm_key_vault main {
  name                = var.keyVault.name
  resource_group_name = var.keyVault.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  name         = var.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret admin_password {
  name         = var.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.main.id
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

data azurerm_network_security_group storage {
  name                = var.virtualNetworkStorage.securityGroupName
  resource_group_name = data.azurerm_virtual_network.storage.resource_group_name
}

data azurerm_resource_group cache {
  name = var.netAppFiles.resourceGroupName
}
