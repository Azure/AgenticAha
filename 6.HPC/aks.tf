# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable aksAutomatic {
  type = object({
    enable = bool
    name   = string
  })
}

#############################################################################
# AKS Automatic (https://learn.microsoft.com/azure/aks/intro-aks-automatic) #
#############################################################################

# resource azurerm_kubernetes_cluster_automatic main {
#   count               = var.aksAutomatic.enable ? 1 : 0
#   name                = var.aksAutomatic.name
#   resource_group_name = azurerm_resource_group.aks[0].name
#   location            = azurerm_resource_group.aks[0].location
# }
