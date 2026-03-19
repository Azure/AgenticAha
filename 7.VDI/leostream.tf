# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################################
# Leostream Platform (https://marketplace.microsoft.com/product/leostreamcorp1748546752602.leostream_platform) #
################################################################################################################

variable leostream {
  type = object({
    enable = bool
    name   = string
    contact = object({
      name  = string
      email = string
    })
    broker = object({
      size = string
    })
    desktop = object({
      type = string
      size = string
    })
    adminLogin = object({
      userPassword = string
    })
  })
}

locals {
  adminLogin = merge(var.leostream.adminLogin, {
    userPassword = var.leostream.adminLogin.userPassword != "" ? var.leostream.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  })
}

resource azurerm_resource_group_template_deployment leostream {
  count               = var.leostream.enable ? 1 : 0
  name                = var.leostream.name
  resource_group_name = azurerm_resource_group.vdi_leostream[0].name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    contactName = {
      value = var.leostream.contact.name
    }
    adminEmail = {
      value = var.leostream.contact.email
    }
    linuxVmSize = {
      value = var.leostream.broker.size
    }
    desktopVmSize = {
      value = var.leostream.desktop.size
    }
    desktopImageType = {
      value = var.leostream.desktop.type
    }
    adminPassword = {
      value = local.adminLogin.userPassword
    }
    leoAdminPassword = {
      value = local.adminLogin.userPassword
    }
    vnetNewOrExisting = {
      value = "existing"
    }
    vnetresourceGroup = {
      value = data.azurerm_virtual_network.main.resource_group_name
    }
    leostreamVnet = {
      value = {
        name = data.azurerm_virtual_network.main.name
        subnets = {
          subnet1 = {
            name          = data.azurerm_subnet.vdi.name
            addressPrefix = data.azurerm_subnet.vdi.address_prefixes[0]
          }
          subnet2 = {
            name          = data.azurerm_subnet.vdi_dmz.name
            addressPrefix = data.azurerm_subnet.vdi_dmz.address_prefixes[0]
          }
        }
      }
    }
  })
  template_content = file("leostream.json")
  lifecycle {
    ignore_changes = all
  }
}

output leostream {
  value = var.leostream.enable ? {
    loginUrl = jsondecode(azurerm_resource_group_template_deployment.leostream[0].output_content)["admin Login URL"].value
    adminUsername = {
      desktop = jsondecode(azurerm_resource_group_template_deployment.leostream[0].output_content)["desktop Admin Username"].value
      gateway = jsondecode(azurerm_resource_group_template_deployment.leostream[0].output_content)["gateway Admin Username"].value
      broker  = jsondecode(azurerm_resource_group_template_deployment.leostream[0].output_content)["connection Broker Admin Username"].value
    }
    quickstartGuide = jsondecode(azurerm_resource_group_template_deployment.leostream[0].output_content)["quickstart Guide"].value
  } : null
}
