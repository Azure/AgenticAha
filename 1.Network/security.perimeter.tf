###################################################################################################################
# Network Security Perimeter (https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts) #
###################################################################################################################

variable networkSecurityPerimeter {
  type = object({
    name        = string
    profileName = string
    keyVault = object({
      enable     = bool
      accessMode = string
    })
    storageAccount = object({
      enable     = bool
      accessMode = string
    })
    logAnalytics = object({
      enable     = bool
      accessMode = string
    })
    appInsights = object({
      enable     = bool
      accessMode = string
    })
    diagnosticSetting = object({
      enable = bool
      name   = string
      log = object({
        category = string
      })
    })
  })
}

resource azurerm_network_security_perimeter main {
  name                = var.networkSecurityPerimeter.name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_network_security_perimeter_profile main {
  name                          = var.networkSecurityPerimeter.profileName
  network_security_perimeter_id = azurerm_network_security_perimeter.main.id
}

resource azurerm_network_security_perimeter_access_rule main {
  name                                  = "AllowInClient"
  direction                             = "Inbound"
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.main.id
  address_prefixes = [
    "${jsondecode(data.http.client_address.response_body).ip}/32"
  ]
}

resource azurerm_network_security_perimeter_association key_vault {
  count                                 = var.networkSecurityPerimeter.keyVault.enable ? 1 : 0
  name                                  = "${data.azurerm_key_vault.main.name}-key-vault"
  resource_id                           = data.azurerm_key_vault.main.id
  access_mode                           = var.networkSecurityPerimeter.keyVault.accessMode
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.main.id
}

resource azurerm_network_security_perimeter_association storage_account {
  count                                 = var.networkSecurityPerimeter.storageAccount.enable ? 1 : 0
  name                                  = "${data.azurerm_storage_account.main.name}-storage-account"
  resource_id                           = data.azurerm_storage_account.main.id
  access_mode                           = var.networkSecurityPerimeter.storageAccount.accessMode
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.main.id
}

resource azurerm_network_security_perimeter_association log_analytics {
  count                                 = var.networkSecurityPerimeter.logAnalytics.enable ? 1 : 0
  name                                  = "${data.azurerm_log_analytics_workspace.main.name}-log-analytics"
  resource_id                           = data.azurerm_log_analytics_workspace.main.id
  access_mode                           = var.networkSecurityPerimeter.logAnalytics.accessMode
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.main.id
}

resource azurerm_network_security_perimeter_association app_insights {
  count                                 = var.networkSecurityPerimeter.appInsights.enable ? 1 : 0
  name                                  = "${data.azurerm_application_insights.main.name}-app-insights"
  resource_id                           = data.azurerm_application_insights.main.id
  access_mode                           = var.networkSecurityPerimeter.appInsights.accessMode
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.main.id
}

resource azurerm_monitor_diagnostic_setting network_security_perimeter {
  count                          = var.networkSecurityPerimeter.diagnosticSetting.enable ? 1 : 0
  name                           = var.networkSecurityPerimeter.diagnosticSetting.name
  target_resource_id             = azurerm_network_security_perimeter.main.id
  log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"
  enabled_log {
    category = var.networkSecurityPerimeter.diagnosticSetting.log.category
  }
}
