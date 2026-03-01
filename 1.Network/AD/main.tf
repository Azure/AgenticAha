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
    key              = "1.Network.AD"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    virtual_machine {
      delete_os_disk_on_deletion            = true
      skip_shutdown_and_force_delete        = false
      detach_implicit_data_disk_on_deletion = false
    }
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

variable resourceGroupName {
  type = string
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

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../../0.Foundation/terraform.tfstate"
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

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet active_directory {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

locals {
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
}

resource azurerm_resource_group active_directory {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}
