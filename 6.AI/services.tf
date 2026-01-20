# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

variable aiServices {
  type = object({
    enable = bool
    name   = string
    tier   = string
    domain = object({
      name = string
      fqdn = list(string)
    })
  })
}

resource azurerm_ai_services main {
  count                        = var.aiServices.enable ? 1 : 0
  name                         = var.aiServices.name
  resource_group_name          = azurerm_resource_group.ai.name
  location                     = azurerm_resource_group.ai.location
  sku_name                     = var.aiServices.tier
  fqdns                        = length(var.aiServices.domain.fqdn) > 0 ? var.aiServices.domain.fqdn : null
  custom_subdomain_name        = var.aiServices.domain.name != "" ? var.aiServices.domain.name : var.aiServices.name
  local_authentication_enabled = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_acls {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  storage {
    storage_account_id = data.azurerm_storage_account.main.id
    identity_client_id = data.azurerm_user_assigned_identity.main.client_id
  }
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone ai_services_open {
  count               = var.aiServices.enable ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.ai.name
}

resource azurerm_private_dns_zone ai_services_cognitive {
  count               = var.aiServices.enable ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.ai.name
}

resource azurerm_private_dns_zone_virtual_network_link ai_services_open {
  count                 = var.aiServices.enable ? 1 : 0
  name                  = "ai-services-open"
  resource_group_name   = azurerm_private_dns_zone.ai_services_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services_open[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_services_cognitive {
  count                 = var.aiServices.enable ? 1 : 0
  name                  = "ai-services-cognitive"
  resource_group_name   = azurerm_private_dns_zone.ai_services_cognitive[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services_cognitive[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_endpoint ai_services_open {
  count               = var.aiServices.enable ? 1 : 0
  name                = "${lower(azurerm_ai_services.main[0].name)}-${azurerm_private_dns_zone_virtual_network_link.ai_services_open[0].name}"
  resource_group_name = azurerm_ai_services.main[0].resource_group_name
  location            = azurerm_ai_services.main[0].location
  subnet_id           = data.azurerm_subnet.ai.id
  private_service_connection {
    name                           = azurerm_ai_services.main[0].name
    private_connection_resource_id = azurerm_ai_services.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_services_open[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_services_open[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_services_cognitive {
  count               = var.aiServices.enable ? 1 : 0
  name                = "${lower(azurerm_ai_services.main[0].name)}-${azurerm_private_dns_zone_virtual_network_link.ai_services_cognitive[0].name}"
  resource_group_name = azurerm_ai_services.main[0].resource_group_name
  location            = azurerm_ai_services.main[0].location
  subnet_id           = data.azurerm_subnet.ai.id
  private_service_connection {
    name                           = azurerm_ai_services.main[0].name
    private_connection_resource_id = azurerm_ai_services.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_services_cognitive[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_services_cognitive[0].id
    ]
  }
  depends_on = [
    azurerm_private_endpoint.ai_services_open
  ]
}
