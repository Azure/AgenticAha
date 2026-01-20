# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###########################################################
# Microsoft Discovery (https://aka.ms/MicrosoftDiscovery) #
###########################################################

variable discovery {
  type = object({
    enable   = bool
    name     = string
    location = string
  })
}

resource azurerm_resource_group discovery {
  count    = var.discovery.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Discovery"
  location = var.discovery.location # data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azapi_resource discovery_storage {
  count     = var.discovery.enable ? 1 : 0
  name      = var.discovery.name
  type      = "Microsoft.Discovery/storages@2025-07-01-preview"
  parent_id = azurerm_resource_group.discovery[0].id
  location  = azurerm_resource_group.discovery[0].location
  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     data.azurerm_user_assigned_identity.main.id
  #   ]
  # }
  body = {
    properties = {
      store = {
        kind = "AzureNetApp"
      }
      subnetId = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/HPC.Network.${var.discovery.location}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetwork.name}/subnets/${var.virtualNetwork.subnetNameNetApp}"
    }
  }
  schema_validation_enabled = false
}
