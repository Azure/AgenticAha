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
    key              = "7.VDI"
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

module fileSystem {
  source = "../3.File.Storage/FileSystem"
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
      sshKeyPublic  = string
    })
  })
}

variable monitor {
  type = object({
    workspace = object({
      logAnalytics = object({
        name              = string
        resourceGroupName = string
      })
    })
  })
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    edgeZoneName      = string
    resourceGroupName = string
  })
}

variable activeDirectory {
  type = object({
    enable = bool
    domain = object({
      name = string
    })
    machine = object({
      name = string
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
  })
}

variable computeGallery {
  type = object({
    name              = string
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

data azurerm_key_vault_secret ssh_key_public {
  name         = var.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_log_analytics_workspace main {
  name                = var.monitor.workspace.logAnalytics.name
  resource_group_name = var.monitor.workspace.logAnalytics.resourceGroupName
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet vdi {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

data azurerm_shared_image_gallery main {
  name                = var.computeGallery.name
  resource_group_name = var.computeGallery.resourceGroupName
}

resource azurerm_resource_group vdi {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group vdi_thinlinc {
  count    = var.thinLinc.enable ? 1 : 0
  name     = "${var.resourceGroupName}.ThinLinc"
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group vdi_avd {
  count    = var.virtualDesktop.enable ? 1 : 0
  name     = "${var.resourceGroupName}.AVD"
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}
