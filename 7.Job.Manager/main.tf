# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.57.0"
    }
  }
  backend azurerm {
    key              = "7.Job.Manager"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
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

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
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

variable privateDNS {
  type = object({
    zoneName          = string
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

data azurerm_subscription current {}

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

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet job_manager {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group ccws {
  count    = var.ccws.enable ? 1 : 0
  name     = var.ccws.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group job_manager {
  count    = !var.ccws.enable ? 1 : 0
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_private_dns_a_record job_manager {
  for_each = {
    for virtualMachine in var.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = lower(var.dnsRecord.name)
  resource_group_name = var.privateDNS.resourceGroupName
  zone_name           = var.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_network_interface.job_manager[each.value.name].private_ip_address
  ]
}
