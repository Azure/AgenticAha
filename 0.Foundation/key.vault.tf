# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  type = object({
    name                        = string
    type                        = string
    enableForDeployment         = bool
    enableForDiskEncryption     = bool
    enableForTemplateDeployment = bool
    enablePurgeProtection       = bool
    utcExpirationDateTime       = string
    softDeleteRetentionDays     = number
    sshKeySizeBits              = number
    secrets = list(object({
      name  = string
      value = string
    }))
  })
}

data tls_public_key ssh {
  private_key_pem = tls_private_key.ssh.private_key_pem
}

resource azurerm_role_assignment key_vault_reader {
  role_definition_name = "Key Vault Reader" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_key_vault.main.id
}

resource azurerm_role_assignment key_vault_crypto_service_encryption_user {
  role_definition_name = "Key Vault Crypto Service Encryption User" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-crypto-service-encryption-user
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_key_vault.main.id
}

resource azurerm_monitor_diagnostic_setting key_vault {
  name                           = "Key Vault Diagnostic Audit Log"
  target_resource_id             = azurerm_key_vault.main.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"
  enabled_log {
    category = "AuditEvent"
  }
}

resource azurerm_key_vault main {
  name                            = var.keyVault.name
  resource_group_name             = azurerm_resource_group.foundation.name
  location                        = azurerm_resource_group.foundation.location
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.keyVault.type
  enabled_for_deployment          = var.keyVault.enableForDeployment
  enabled_for_disk_encryption     = var.keyVault.enableForDiskEncryption
  enabled_for_template_deployment = var.keyVault.enableForTemplateDeployment
  purge_protection_enabled        = var.keyVault.enablePurgeProtection
  soft_delete_retention_days      = var.keyVault.softDeleteRetentionDays
  rbac_authorization_enabled      = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules = [
      "${jsondecode(data.http.client_address.response_body).ip}/32"
    ]
  }
}

resource azurerm_key_vault_secret main {
  for_each = {
    for secret in var.keyVault.secrets : secret.name => secret
  }
  name            = each.value.name
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.main.id
  expiration_date = var.keyVault.utcExpirationDateTime
}

resource tls_private_key ssh {
  rsa_bits  = var.keyVault.sshKeySizeBits
  algorithm = "RSA"
}

resource azurerm_key_vault_secret ssh_key_private {
  name            = "SSHKeyPrivate"
  value           = tls_private_key.ssh.private_key_pem
  key_vault_id    = azurerm_key_vault.main.id
  expiration_date = var.keyVault.utcExpirationDateTime
}

resource azurerm_key_vault_secret ssh_key_public {
  name            = "SSHKeyPublic"
  value           = trimspace(data.tls_public_key.ssh.public_key_openssh)
  key_vault_id    = azurerm_key_vault.main.id
  expiration_date = var.keyVault.utcExpirationDateTime
}
