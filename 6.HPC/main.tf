# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.65.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.7.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.8.0"
    }
  }
  backend azurerm {
    key              = "6.HPC"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
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
      sshKeyPublic  = string
      sshKeyPrivate = string
    })
  })
}

variable monitor {
  type = object({
    enable = bool
    workspace = object({
      name              = string
      resourceGroupName = string
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
    resourceGroupName = string
    subnetNameCycle   = string
    subnetNameCluster = string
    subnetNameAICore  = string
    subnetNameAIAgent = string
    subnetNameAIDiscovery = object({
      storage = string
      compute = string
    })
    privateDnsZone = object({
      name              = string
      resourceGroupName = string
    })
    spokes = list(object({
      enable            = bool
      resourceGroupName = string
      location          = string
      nfs = object({
        enable       = bool
        ipAddress    = string
        exportPath   = string
        mountOptions = string
      })
    }))
  })
}

variable computeGallery {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable storageAccount {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable mySqlFlexibleServer {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

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

data azurerm_key_vault_secret ssh_key_public {
  name         = var.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret ssh_key_private {
  name         = var.keyVault.secretName.sshKeyPrivate
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_monitor_workspace main {
  name                = var.monitor.workspace.name
  resource_group_name = var.monitor.workspace.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint main {
  name                = basename(data.azurerm_monitor_workspace.main.default_data_collection_endpoint_id)
  resource_group_name = split("/", data.azurerm_monitor_workspace.main.default_data_collection_endpoint_id)[4]
}

data azurerm_monitor_data_collection_rule main {
  name                = basename(data.azurerm_monitor_workspace.main.default_data_collection_rule_id)
  resource_group_name = split("/", data.azurerm_monitor_workspace.main.default_data_collection_rule_id)[4]
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
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = var.virtualNetwork.name
  resource_group_name = each.value.resourceGroupName
}

data azurerm_subnet cyclcloud {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                 = var.virtualNetwork.subnetNameCycle
  resource_group_name  = data.azurerm_virtual_network.main[each.value.key].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main[each.value.key].name
}

data azurerm_subnet ai_core {
  name                 = var.virtualNetwork.subnetNameAICore
  resource_group_name  = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].name
}

data azurerm_subnet ai_agent {
  count                = var.foundry.enable ? 1 : 0
  name                 = var.virtualNetwork.subnetNameAIAgent
  resource_group_name  = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].name
}

data azurerm_subnet ai_discovery_storage {
  count                = var.discovery.enable && var.discovery.sharedStorage.enable ? 1 : 0
  name                 = var.virtualNetwork.subnetNameAIDiscovery.storage
  # resource_group_name  = var.virtualNetwork.resourceGroupName
  resource_group_name  = "HPC.Network.${var.discovery.region.hub}"
  virtual_network_name = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].name
}

data azurerm_subnet ai_discovery_compute {
  count                = var.discovery.enable ? 1 : 0
  name                 = var.virtualNetwork.subnetNameAIDiscovery.compute
  # resource_group_name  = var.virtualNetwork.resourceGroupName
  resource_group_name  = "HPC.Network.${var.discovery.region.hub}"
  virtual_network_name = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].name
}

data azurerm_private_dns_zone main {
  name                = var.virtualNetwork.privateDnsZone.name
  resource_group_name = var.virtualNetwork.privateDnsZone.resourceGroupName
}

data azurerm_shared_image_gallery main {
  name                = var.computeGallery.name
  resource_group_name = var.computeGallery.resourceGroupName
}

data azurerm_storage_account main {
  name                = var.storageAccount.name
  resource_group_name = var.storageAccount.resourceGroupName
}

locals {
  virtualNetworks = concat([merge(var.virtualNetwork, {key = var.virtualNetwork.resourceGroupName})], [
    for spoke in var.virtualNetwork.spokes : merge(var.virtualNetwork, {
      key               = spoke.resourceGroupName
      resourceGroupName = spoke.resourceGroupName
      location          = spoke.location
    }) if spoke.enable
  ])
}

resource azurerm_resource_group cyclecloud {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  name     = each.value.resourceGroup.value
  location = each.value.location.value
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group aks {
  count    = var.aksAutomatic.enable ? 1 : 0
  name     = "${var.resourceGroupName}.AKS"
  location = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group ai_discovery {
  count    = var.discovery.enable ? 1 : 0
  name     = "${var.resourceGroupName}.AI.Discovery"
  location = var.discovery.region.hub
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group ai_foundry {
  count    = var.foundry.enable ? 1 : 0
  name     = "${var.resourceGroupName}.AI.Foundry"
  location = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group ai_search {
  count    = var.search.enable ? 1 : 0
  name     = "${var.resourceGroupName}.AI.Search"
  location = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group update_manager {
  count    = var.updateManager.enable ? 1 : 0
  name     = "${var.resourceGroupName}.UpdateManager"
  location = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].location
  tags = {
    Module = basename(path.cwd)
  }
}
