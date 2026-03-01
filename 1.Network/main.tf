# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.62.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
    }
  }
  backend azurerm {
    key              = "1.Network"
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
  })
}

variable storageAccount {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable monitor {
  type = object({
    workspace = object({
      name              = string
      resourceGroupName = string
      logAnalytics = object({
        name              = string
        resourceGroupName = string
      })
    })
    appInsights = object({
      name              = string
      resourceGroupName = string
    })
    grafanaDashboard = object({
      name              = string
      resourceGroupName = string
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
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

data azurerm_storage_account main {
  name                = var.storageAccount.name
  resource_group_name = var.storageAccount.resourceGroupName
}

data azurerm_monitor_workspace main {
  name                = var.monitor.workspace.name
  resource_group_name = var.monitor.workspace.resourceGroupName
}

data azurerm_log_analytics_workspace main {
  name                = var.monitor.workspace.logAnalytics.name
  resource_group_name = var.monitor.workspace.logAnalytics.resourceGroupName
}

data azurerm_application_insights main {
  name                = var.monitor.appInsights.name
  resource_group_name = var.monitor.appInsights.resourceGroupName
}

data azurerm_dashboard_grafana main {
  name                = var.monitor.grafanaDashboard.name
  resource_group_name = var.monitor.grafanaDashboard.resourceGroupName
}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = local.virtualNetwork.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group network_regions {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name     = each.value.resourceGroup.name
  location = each.value.location
  tags = {
    Module = basename(path.cwd)
  }
}
