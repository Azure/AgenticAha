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
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.1.0"
    }
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = var.subscriptionId
  storage_use_azuread = true
}

variable subscriptionId {
  type = string
}

variable defaultLocation {
  type = string
}

locals {
  backendConfig = {
    patternSuffix = "\\s+=\\s+\"([^\"]+)"
  }
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

data azuread_user current {
  object_id = data.azurerm_client_config.current.object_id
}

resource azurerm_resource_group foundation {
  name     = regex("resource_group_name${local.backendConfig.patternSuffix}", file("./backend.config"))[0]
  location = var.defaultLocation
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group foundation_monitor {
  name     = "${azurerm_resource_group.foundation.name}.Monitor"
  location = azurerm_resource_group.foundation.location
  tags = {
    Module = basename(path.cwd)
  }
}

output subscriptionId {
  value = data.azurerm_subscription.current.subscription_id
}

output resourceGroup {
  value = {
    name = azurerm_resource_group.foundation.name
  }
}
