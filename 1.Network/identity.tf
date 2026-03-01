# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

resource azurerm_user_assigned_identity main {
  for_each = {
    for virtualNetwork in local.spokeVirtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = lower(replace(each.value.key, each.value.name, var.managedIdentity.name))
  resource_group_name = var.managedIdentity.resourceGroupName
  location            = each.value.location
  isolation_scope     = "Regional"
}
