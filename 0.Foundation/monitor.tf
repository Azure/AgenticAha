# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  type = object({
    name = string
    logAnalytics = object({
      workspace = object({
        tier = string
      })
    })
    applicationInsights = object({
      type = string
    })
    monitorWorkspace = object({
      ingestAlert = object({
        enable    = bool
        name      = string
        severity  = number
        threshold = number
      })
    })
    grafanaDashboard = object({
      tier    = string
      version = number
    })
    dataRetention = object({
      days = number
    })
  })
}

resource azurerm_role_assignment monitoring_metrics_publisher {
  role_definition_name = "Monitoring Metrics Publisher" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/monitor#monitoring-metrics-publisher
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_monitor_workspace.main.default_data_collection_rule_id
}

resource azurerm_role_assignment monitoring_reader {
  role_definition_name = "Monitoring Reader" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/monitor#monitoring-reader
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_monitor_workspace.main.id
}

resource azurerm_role_assignment monitoring_contributor {
  role_definition_name = "Monitoring Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/monitor#monitoring-contributor
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_monitor_workspace.main.id
}

resource azurerm_role_assignment grafana_admin {
  role_definition_name = "Grafana Admin" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/monitor#grafana-admin
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_dashboard_grafana.main.id
}

resource azurerm_log_analytics_workspace main {
  name                       = var.monitor.name
  resource_group_name        = azurerm_resource_group.foundation_monitor.name
  location                   = azurerm_resource_group.foundation_monitor.location
  sku                        = var.monitor.logAnalytics.workspace.tier
  retention_in_days          = var.monitor.dataRetention.days
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_application_insights main {
  name                       = var.monitor.name
  resource_group_name        = azurerm_resource_group.foundation_monitor.name
  location                   = azurerm_resource_group.foundation_monitor.location
  workspace_id               = azurerm_log_analytics_workspace.main.id
  application_type           = var.monitor.applicationInsights.type
  retention_in_days          = var.monitor.dataRetention.days
  internet_ingestion_enabled = false
  internet_query_enabled     = false
}

resource azurerm_monitor_workspace main {
  name                          = var.monitor.name
  resource_group_name           = azurerm_resource_group.foundation_monitor.name
  location                      = azurerm_resource_group.foundation_monitor.location
  public_network_access_enabled = false
}

resource azurerm_monitor_action_group main {
  name                = var.monitor.name
  short_name          = var.monitor.name
  resource_group_name = azurerm_resource_group.foundation_monitor.name
  email_receiver {
    name                    = data.azuread_user.current.display_name
    email_address           = data.azuread_user.current.mail
    use_common_alert_schema = true
  }
}

resource azurerm_monitor_metric_alert workspace_ingest {
  count               = var.monitor.monitorWorkspace.ingestAlert.enable ? 1 : 0
  name                = var.monitor.monitorWorkspace.ingestAlert.name
  resource_group_name = azurerm_resource_group.foundation_monitor.name
  severity            = var.monitor.monitorWorkspace.ingestAlert.severity
  scopes = [
    azurerm_monitor_workspace.main.id
  ]
  criteria {
    metric_namespace = "Microsoft.Monitor/accounts"
    metric_name      = "ActiveTimeSeriesPercentUtilization"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.monitor.monitorWorkspace.ingestAlert.threshold
  }
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource azurerm_dashboard_grafana main {
  name                          = var.monitor.name
  resource_group_name           = azurerm_resource_group.foundation_monitor.name
  location                      = azurerm_resource_group.foundation_monitor.location
  sku                           = var.monitor.grafanaDashboard.tier
  grafana_major_version         = var.monitor.grafanaDashboard.version
  public_network_access_enabled = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.main.id
  }
}

output monitor {
  value = {
    resourceGroup = {
      name     = azurerm_resource_group.foundation_monitor.name
      location = azurerm_resource_group.foundation_monitor.location
    }
    logAnalytics = {
      id = azurerm_log_analytics_workspace.main.id
    }
    applicationInsights = {
      id   = azurerm_application_insights.main.id
      name = azurerm_application_insights.main.name
    }
    workspace = {
      name = azurerm_monitor_workspace.main.name
      grafanaDashboard = {
        name = azurerm_dashboard_grafana.main.name
      }
    }
  }
}
