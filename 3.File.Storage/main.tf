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
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.8.0"
    }
  }
  backend azurerm {
    key              = "3.File.Storage"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    netapp {
      prevent_volume_destruction             = true
      delete_backups_on_backup_vault_destroy = false
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
    subnetNameNetApp  = string
    resourceGroupName = string
    extendedZone = object({
      enable   = bool
      name     = string
      location = string
    })
    privateDNS = object({
      zoneName          = string
      resourceGroupName = string
    })
  })
}

variable activeDirectory {
  type = object({
    enable = bool
    domain = object({
      name = string
    })
    machine = object({
      name              = string
      resourceGroupName = string
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

data azurerm_location main {
  location = data.azurerm_virtual_network.main.location
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

data azurerm_key_vault_key data_encryption {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_resource_group dns {
  name = var.virtualNetwork.privateDNS.resourceGroupName
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet storage {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

data azurerm_network_interface active_directory {
  count                = var.activeDirectory.enable ? 1 : 0
  name                 = var.activeDirectory.machine.name
  resource_group_name  = var.activeDirectory.machine.resourceGroupName
}

locals {
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
      ip = var.activeDirectory.enable ? data.azurerm_network_interface.active_directory[0].ip_configuration[0].private_ip_address : null
    })
  })
}

resource azurerm_resource_group storage {
  count    = length(local.storageAccounts) > 0 ? 1 : 0
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record netapp_src {
  count               = var.netAppFiles.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-netapp-src"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azurerm_netapp_volume.main : volume.mount_ip_addresses[0] if volume.location == azurerm_resource_group.netapp[0].location
  ])
}

resource azurerm_private_dns_a_record netapp_dst {
  count               = var.netAppFiles.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-netapp-dst"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azurerm_netapp_volume.main : volume.mount_ip_addresses[0] if volume.location != azurerm_resource_group.netapp[0].location
  ])
}

resource azurerm_private_dns_a_record lustre {
  count               = var.managedLustre.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-lustre"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_managed_lustre_file_system.main[0].mgs_address
  ]
}

output privateDNS {
  value = {
    netAppFiles = var.netAppFiles.enable ? {
      source = {
        fqdn    = azurerm_private_dns_a_record.netapp_src[0].fqdn
        records = length(azurerm_private_dns_a_record.netapp_src[0].records) > 0 ? azurerm_private_dns_a_record.netapp_src[0].records : null
      }
      destination = {
        fqdn    = azurerm_private_dns_a_record.netapp_dst[0].fqdn
        records = length(azurerm_private_dns_a_record.netapp_dst[0].records) > 0 ? azurerm_private_dns_a_record.netapp_dst[0].records : null
      }
    } : null
    managedLustre = var.managedLustre.enable ? {
      fqdn    = azurerm_private_dns_a_record.lustre[0].fqdn
      records = length(azurerm_private_dns_a_record.lustre[0].records) > 0 ? azurerm_private_dns_a_record.lustre[0].records : null
    } : null
  }
}
