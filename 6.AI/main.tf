# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">=1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.57.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
    }
  }
  backend azurerm {
    key              = "6.AI"
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
    subnetName        = string
    resourceGroupName = string
  })
}

variable storageAccount {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable applicationInsights {
  type = object({
    enable            = bool
    name              = string
    resourceGroupName = string
  })
}

variable containerRegistry {
  type = object({
    enable            = bool
    name              = string
    resourceGroupName = string
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../0.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state image {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.foundation.outputs.subscriptionId
    resource_group_name  = data.terraform_remote_state.foundation.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.foundation.outputs.storage.account.name
    container_name       = data.terraform_remote_state.foundation.outputs.storage.containerName.terraformState
    key                  = "2.Image"
    use_azuread_auth     = true
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

data azurerm_virtual_network main {
  name                 = var.virtualNetwork.name
  resource_group_name  = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet ai {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

data azurerm_storage_account main {
  name                = var.storageAccount.name
  resource_group_name = var.storageAccount.resourceGroupName
}

data azurerm_application_insights main {
  count               = var.applicationInsights.enable ? 1 : 0
  name                = var.applicationInsights.name
  resource_group_name = var.applicationInsights.resourceGroupName
}

data azurerm_container_registry main {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = var.containerRegistry.name
  resource_group_name = var.containerRegistry.resourceGroupName
}

resource azurerm_resource_group ai {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group ai_ml {
  count    = var.aiMachineLearning.enable ? 1 : 0
  name     = "${azurerm_resource_group.ai.name}.ML"
  location = azurerm_resource_group.ai.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group ai_foundry {
  count    = var.aiFoundry.enable ? 1 : 0
  name     = "${azurerm_resource_group.ai.name}.Foundry"
  location = azurerm_resource_group.ai.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group ai_search {
  count    = var.aiSearch.enable ? 1 : 0
  name     = "${azurerm_resource_group.ai.name}.Search"
  location = azurerm_resource_group.ai.location
  tags = {
    Module = basename(path.cwd)
  }
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone ai_ml {
  count               = var.aiMachineLearning.enable || var.aiFoundry.enable ? 1 : 0
  name                = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.ai_ml[0].name
}

resource azurerm_private_dns_zone ai_ml_notebook {
  count               = var.aiMachineLearning.enable ? 1 : 0
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = azurerm_resource_group.ai_ml[0].name
}

resource azurerm_private_dns_zone_virtual_network_link ai_ml {
  count               = var.aiMachineLearning.enable || var.aiFoundry.enable ? 1 : 0
  name                  = "ai-ml"
  resource_group_name   = azurerm_private_dns_zone.ai_ml[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_ml[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_ml_notebook {
  count                 = var.aiMachineLearning.enable ? 1 : 0
  name                  = "ai-ml-notebook"
  resource_group_name   = azurerm_private_dns_zone.ai_ml_notebook[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_ml_notebook[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

output ai {
  value = {
    services = var.aiServices.enable ? {
      id = azurerm_ai_services.main[0].id
    } : null
    machineLearning = var.aiMachineLearning.enable ? {
      workspace = {
        id = azurerm_machine_learning_workspace.main[0].id
      }
    } : null
    foundry = var.aiFoundry.enable ? {
      id = azurerm_ai_foundry.main[0].id
      workspace = {
        id = azurerm_ai_foundry.main[0].workspace_id
      }
      discovery = {
        url = azurerm_ai_foundry.main[0].discovery_url
      }
      projects = [
        for project in azurerm_ai_foundry_project.main : {
          id        = project.id
          projectId = project.project_id
        }
      ]
    } : null
    search = var.aiSearch.enable ? {
      id = azurerm_search_service.main[0].id
    } : null
  }
}
