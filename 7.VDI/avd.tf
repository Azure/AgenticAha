# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################
# Virtual Desktop (https://learn.microsoft.com/azure/virtual-desktop/overview) #
################################################################################

variable virtualDesktop {
  type = object({
    enable = bool
    workspace = object({
      name        = string
      displayName = string
      description = string
    })
    hostPool = object({
      name        = string
      displayName = string
      description = string
      userShared = object({
        enable      = bool
        maxSessions = number
      })
      assignmentType = object({
        personal = string
        pooled   = string
      })
      startMachine = object({
        onConnect = bool
      })
      testEnvironment = object({
        enable = bool
      })
      rdp = object({
        properties = string
      })
      expiration = object({
        hours = number
      })
    })
    appGroups = list(object({
      enable      = bool
      name        = string
      displayName = string
      description = string
      type        = string
      apps = list(object({
        enable      = bool
        name        = string
        displayName = string
        description = string
        filePath    = string
        commandLine = object({
          policy    = string
          arguments = string
        })
        showInPortal = object({
          enable = bool
        })
      }))
    }))
  })
}

locals {
  apps = flatten([
    for appGroup in var.virtualDesktop.appGroups : [
      for app in appGroup.apps : merge(app, {
        appGroupName = appGroup.name
      }) if app.enable
    ] if appGroup.enable && var.virtualDesktop.enable
  ])
}

resource azurerm_virtual_desktop_workspace main {
  count               = var.virtualDesktop.enable ? 1 : 0
  name                = var.virtualDesktop.workspace.name
  resource_group_name = azurerm_resource_group.vdi_avd[0].name
  location            = azurerm_resource_group.vdi_avd[0].location
  friendly_name       = var.virtualDesktop.workspace.displayName != "" ? var.virtualDesktop.workspace.displayName : null
  description         = var.virtualDesktop.workspace.description != "" ? var.virtualDesktop.workspace.description : null
}

resource azurerm_virtual_desktop_host_pool main {
  count                            = var.virtualDesktop.enable ? 1 : 0
  name                             = var.virtualDesktop.hostPool.name
  resource_group_name              = azurerm_resource_group.vdi_avd[0].name
  location                         = azurerm_resource_group.vdi_avd[0].location
  friendly_name                    = var.virtualDesktop.hostPool.displayName != "" ? var.virtualDesktop.hostPool.displayName : null
  description                      = var.virtualDesktop.hostPool.description != "" ? var.virtualDesktop.hostPool.description : null
  type                             = var.virtualDesktop.hostPool.userShared.enable ? "Pooled" : "Personal"
  load_balancer_type               = var.virtualDesktop.hostPool.userShared.enable ? var.virtualDesktop.hostPool.assignmentType.pooled : "Persistent"
  maximum_sessions_allowed         = var.virtualDesktop.hostPool.userShared.enable ? var.virtualDesktop.hostPool.userShared.maxSessions : null
  personal_desktop_assignment_type = !var.virtualDesktop.hostPool.userShared.enable ? var.virtualDesktop.hostPool.assignmentType.personal : null
  validate_environment             = var.virtualDesktop.hostPool.testEnvironment.enable
  start_vm_on_connect              = var.virtualDesktop.hostPool.startMachine.onConnect
  custom_rdp_properties            = var.virtualDesktop.hostPool.rdp.properties
}

resource azurerm_virtual_desktop_host_pool_registration_info main {
  count           = var.virtualDesktop.enable ? 1 : 0
  hostpool_id     = azurerm_virtual_desktop_host_pool.main[0].id
  expiration_date = timeadd(timestamp(), "${var.virtualDesktop.hostPool.expiration.hours}h")
}

resource azurerm_virtual_desktop_application_group main {
  for_each = {
    for appGroup in var.virtualDesktop.appGroups : appGroup.name => appGroup if appGroup.enable && var.virtualDesktop.enable
  }
  name                         = each.value.name
  default_desktop_display_name = each.value.displayName != "" ? each.value.displayName : each.value.name
  description                  = each.value.description != "" ? each.value.description : null
  resource_group_name          = azurerm_resource_group.vdi_avd[0].name
  location                     = azurerm_resource_group.vdi_avd[0].location
  type                         = each.value.type
  host_pool_id                 = azurerm_virtual_desktop_host_pool.main[0].id
}

resource azurerm_virtual_desktop_workspace_application_group_association main {
  for_each = {
    for appGroup in var.virtualDesktop.appGroups : appGroup.name => appGroup if appGroup.enable && var.virtualDesktop.enable
  }
  application_group_id = azurerm_virtual_desktop_application_group.main[each.value.name].id
  workspace_id         = azurerm_virtual_desktop_workspace.main[0].id
}

resource azurerm_virtual_desktop_application main {
  for_each = {
    for app in local.apps : app.name => app
  }
  name                         = each.value.name
  friendly_name                = each.value.displayName != "" ? each.value.displayName : null
  description                  = each.value.description != "" ? each.value.description : null
  path                         = each.value.filePath
  command_line_argument_policy = each.value.commandLine.policy
  command_line_arguments       = each.value.commandLine.arguments != "" ? each.value.commandLine.arguments : null
  application_group_id         = azurerm_virtual_desktop_application_group.main[each.value.appGroupName].id
  show_in_portal               = each.value.showInPortal.enable
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone virtual_desktop_global {
  count               = var.virtualDesktop.enable ? 1 : 0
  name                = "privatelink-global.wvd.microsoft.com"
  resource_group_name = azurerm_resource_group.vdi_avd[0].name
}

resource azurerm_private_dns_zone virtual_desktop {
  count               = var.virtualDesktop.enable ? 1 : 0
  name                = "privatelink.wvd.microsoft.com"
  resource_group_name = azurerm_resource_group.vdi_avd[0].name
}

resource azurerm_private_dns_zone_virtual_network_link virtual_desktop_global {
  count                 = var.virtualDesktop.enable ? 1 : 0
  name                  = "avd-global"
  resource_group_name   = azurerm_private_dns_zone.virtual_desktop_global[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.virtual_desktop_global[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_dns_zone_virtual_network_link virtual_desktop {
  count                 = var.virtualDesktop.enable ? 1 : 0
  name                  = "avd"
  resource_group_name   = azurerm_private_dns_zone.virtual_desktop[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.virtual_desktop[0].name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_endpoint virtual_desktop_workspace_global {
  count               = var.virtualDesktop.enable ? 1 : 0
  name                = "${lower(azurerm_virtual_desktop_workspace.main[0].name)}-${azurerm_private_dns_zone_virtual_network_link.virtual_desktop_global[0].name}"
  resource_group_name = azurerm_virtual_desktop_workspace.main[0].resource_group_name
  location            = azurerm_virtual_desktop_workspace.main[0].location
  subnet_id           = data.azurerm_subnet.vdi.id
  private_service_connection {
    name                           = azurerm_virtual_desktop_workspace.main[0].name
    private_connection_resource_id = azurerm_virtual_desktop_workspace.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "global"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.virtual_desktop_global[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.virtual_desktop_global[0].id
    ]
  }
}

resource azurerm_private_endpoint virtual_desktop_workspace {
  count               = var.virtualDesktop.enable ? 1 : 0
  name                = "${lower(azurerm_virtual_desktop_workspace.main[0].name)}-${azurerm_private_dns_zone_virtual_network_link.virtual_desktop[0].name}"
  resource_group_name = azurerm_virtual_desktop_workspace.main[0].resource_group_name
  location            = azurerm_virtual_desktop_workspace.main[0].location
  subnet_id           = data.azurerm_subnet.vdi.id
  private_service_connection {
    name                           = azurerm_virtual_desktop_workspace.main[0].name
    private_connection_resource_id = azurerm_virtual_desktop_workspace.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "feed"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.virtual_desktop[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.virtual_desktop[0].id
    ]
  }
}

resource azurerm_private_endpoint virtual_desktop_host_pool {
  count               = var.virtualDesktop.enable ? 1 : 0
  name                = "${lower(azurerm_virtual_desktop_host_pool.main[0].name)}-avd-host"
  resource_group_name = azurerm_virtual_desktop_host_pool.main[0].resource_group_name
  location            = azurerm_virtual_desktop_host_pool.main[0].location
  subnet_id           = data.azurerm_subnet.vdi.id
  private_service_connection {
    name                           = azurerm_virtual_desktop_host_pool.main[0].name
    private_connection_resource_id = azurerm_virtual_desktop_host_pool.main[0].id
    is_manual_connection           = false
    subresource_names = [
      "connection"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.virtual_desktop[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.virtual_desktop[0].id
    ]
  }
}
