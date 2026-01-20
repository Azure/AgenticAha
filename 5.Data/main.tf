# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.57.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.7.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "~>1.7.0"
    }
  }
  backend azurerm {
    key              = "5.Data"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

variable resourceGroupName {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    resourceGroupName = string
    subnetName = object({
      data  = string
      mySQL = string
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config current {}

data azuread_user current {
  object_id = data.azurerm_client_config.current.object_id
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

data azurerm_key_vault main {
  name                = data.terraform_remote_state.foundation.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet data {
  name                 = var.virtualNetwork.subnetName.data
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

data azurerm_subnet data_mysql {
  count                = var.mySQL.enable ? 1 : 0
  name                 = var.virtualNetwork.subnetName.mySQL
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group data {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group data_sql {
  count    = var.mySQL.enable ? 1 : 0
  name     = "${var.resourceGroupName}.SQL"
  location = azurerm_resource_group.data.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group data_fabric {
  count    = var.fabric.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Fabric"
  location = azurerm_resource_group.data.location
  tags = {
    Module = basename(path.cwd)
  }
}
