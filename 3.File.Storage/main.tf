# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.65.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.8.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
  }
  backend azurerm {
    key              = "3.File.Storage"
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
      delete_backups_on_backup_vault_destroy = false
    }
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

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
  })
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

variable networkSecurityPerimeter {
  type = object({
    name               = string
    profileName        = string
    resourceGroupName  = string
    resourceAccessMode = string
  })
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    subnetNameANF     = string
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

data azurerm_subscription current {}

data azurerm_client_config current {}

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

data azurerm_resource_group dns {
  name = var.virtualNetwork.privateDNS.resourceGroupName
}

data azurerm_network_security_perimeter main {
  name                = var.networkSecurityPerimeter.name
  resource_group_name = var.networkSecurityPerimeter.resourceGroupName
}

data azurerm_network_security_perimeter_profile main {
  name                          = var.networkSecurityPerimeter.profileName
  network_security_perimeter_id = data.azurerm_network_security_perimeter.main.id
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

resource azurerm_resource_group netapp_files {
  count    = var.netAppFiles.enable ? 1 : 0
  name     = "${var.resourceGroupName}.NetAppFiles"
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group lustre_files {
  count    = var.lustreFiles.enable ? 1 : 0
  name     = "${var.resourceGroupName}.LustreFiles"
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record netapp_files {
  count               = var.netAppFiles.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-netappfiles"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azurerm_netapp_volume.main : volume.mount_ip_addresses[0] if volume.location == azurerm_resource_group.netapp_files[0].location
  ])
}

resource azurerm_private_dns_a_record netapp_files_replication {
  count               = var.netAppFiles.enable && length(local.anfVolumesReplication) > 0 ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-netappfiles-replication"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azurerm_netapp_volume.main : volume.mount_ip_addresses[0] if volume.location != azurerm_resource_group.netapp_files[0].location
  ])
}

resource azurerm_private_dns_a_record lustre_files {
  count               = var.lustreFiles.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-lustrefiles"
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
      fqdn    = azurerm_private_dns_a_record.netapp_files[0].fqdn
      records = length(azurerm_private_dns_a_record.netapp_files[0].records) > 0 ? azurerm_private_dns_a_record.netapp_files[0].records : null
      replication = length(local.anfVolumesReplication) > 0 ? {
        fqdn    = azurerm_private_dns_a_record.netapp_files_replication[0].fqdn
        records = length(azurerm_private_dns_a_record.netapp_files_replication[0].records) > 0 ? azurerm_private_dns_a_record.netapp_files_replication[0].records : null
      } : null
    } : null
    lustreFiles = var.lustreFiles.enable ? {
      fqdn    = azurerm_private_dns_a_record.lustre_files[0].fqdn
      records = length(azurerm_private_dns_a_record.lustre_files[0].records) > 0 ? azurerm_private_dns_a_record.lustre_files[0].records : null
    } : null
  }
}
