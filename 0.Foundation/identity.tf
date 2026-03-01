# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

variable managedIdentity {
  type = object({
    name = string
  })
}

resource azurerm_user_assigned_identity main {
  name                = var.managedIdentity.name
  resource_group_name = azurerm_resource_group.foundation_identity.name
  location            = azurerm_resource_group.foundation_identity.location
}

resource azurerm_role_assignment contributor {
  role_definition_name = "Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#contributor
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
}
