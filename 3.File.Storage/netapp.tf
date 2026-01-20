# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

variable netAppFiles {
  type = object({
    enable = bool
    name   = string
    kerberos = object({
      enable = bool
    })
    capacityPools = list(object({
      enable  = bool
      name    = string
      sizeTiB = number
      tpMiBps = number
      coolAccess = object({
        enable = bool
        period = object({
          days = number
        })
        policy = object({
          tiering   = string
          retrieval = string
        })
      })
      volumes = list(object({
        enable      = bool
        name        = string
        path        = string
        sizeGiB     = number
        tpMiBps     = number
        permissions = number
        kerberos = object({
          enable = bool
        })
        largeVolume = object({
          enable = bool
        })
        vmWareSolution = object({
          enable = bool
        })
        replication = object({
          enable    = bool
          frequency = string
          regions   = list(string)
        })
        network = object({
          features  = string
          protocols = list(string)
        })
        exportPolicies = list(object({
          ruleIndex      = number
          ownerMode      = string
          readOnly       = bool
          readWrite      = bool
          rootAccess     = bool
          allowedClients = list(string)
        }))
      }))
    }))
    backup = object({
      enable = bool
      name   = string
      policy = object({
        enable = bool
        name   = string
        retention = object({
          daily   = number
          weekly  = number
          monthly = number
        })
      })
    })
  })
}

locals {
  netAppRegions = var.netAppFiles.enable ? distinct(concat([azurerm_resource_group.netapp[0].location], flatten([
    for capacityPool in var.netAppFiles.capacityPools : [
      for volume in capacityPool.volumes : volume.replication.enable ? volume.replication.regions : [] if volume.enable
    ] if capacityPool.enable
  ]))) : []
  netAppAccounts = [
    for region in local.netAppRegions : merge(var.netAppFiles, {
      key  = region != azurerm_resource_group.netapp[0].location ? "${var.netAppFiles.name}-${region}" : var.netAppFiles.name
      name = region != azurerm_resource_group.netapp[0].location ? "${var.netAppFiles.name}-${region}" : var.netAppFiles.name
      resourceGroup = {
        name     = azurerm_resource_group.netapp[0].name
        location = region
      }
    })
  ]
  netAppPools = flatten([
    for account in local.netAppAccounts : [
      for capacityPool in account.capacityPools : merge(capacityPool, {
        key           = "${account.key}-${capacityPool.name}"
        resourceGroup = account.resourceGroup
        accountName   = account.name
      }) if capacityPool.enable
    ]
  ])
  netAppVolumes = flatten([
    for capacityPool in local.netAppPools : [
      for volume in capacityPool.volumes : merge(volume, {
        key           = "${capacityPool.key}-${volume.name}"
        resourceGroup = capacityPool.resourceGroup
        poolName      = capacityPool.name
        coolAccess    = capacityPool.coolAccess
        accountName   = capacityPool.accountName
      }) if volume.enable && (capacityPool.resourceGroup.location == azurerm_resource_group.netapp[0].location || volume.replication.enable)
    ]
  ])
}

resource azurerm_resource_group netapp {
  count    = var.netAppFiles.enable ? 1 : 0
  name     = "${var.resourceGroupName}.NetApp"
  location = data.azurerm_virtual_network.main.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_netapp_account main {
  for_each = {
    for account in local.netAppAccounts : account.key => account
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.resourceGroup.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  dynamic active_directory {
    for_each = var.activeDirectory.enable ? [1] : []
    content {
      domain           = var.activeDirectory.domain.name
      username         = local.activeDirectory.machine.adminLogin.userName
      password         = local.activeDirectory.machine.adminLogin.userPassword
      smb_server_name  = var.activeDirectory.machine.name
      kerberos_ad_name = var.netAppFiles.kerberos.enable ? var.activeDirectory.machine.name : null
      kerberos_kdc_ip  = var.netAppFiles.kerberos.enable ? local.activeDirectory.machine.ip : null
      dns_servers = [
        local.activeDirectory.machine.ip
      ]
    }
  }
  depends_on = [
    azurerm_resource_group.netapp
  ]
}

resource azurerm_netapp_pool main {
  for_each = {
    for capacityPool in local.netAppPools : capacityPool.key => capacityPool
  }
  name                    = each.value.name
  resource_group_name     = each.value.resourceGroup.name
  location                = each.value.resourceGroup.location
  size_in_tb              = each.value.sizeTiB
  custom_throughput_mibps = each.value.tpMiBps
  cool_access_enabled     = each.value.coolAccess.enable
  account_name            = azurerm_netapp_account.main[each.value.accountName].name
  service_level           = "Flexible"
  qos_type                = "Manual"
}

resource azurerm_netapp_volume main {
  for_each = {
    for volume in local.netAppVolumes : volume.key => volume
  }
  name                            = each.value.name
  resource_group_name             = each.value.resourceGroup.name
  location                        = each.value.resourceGroup.location
  pool_name                       = each.value.poolName
  volume_path                     = each.value.path
  storage_quota_in_gb             = each.value.sizeGiB
  throughput_in_mibps             = each.value.tpMiBps
  kerberos_enabled                = each.value.kerberos.enable
  network_features                = each.value.network.features
  protocols                       = each.value.network.protocols
  large_volume_enabled            = each.value.largeVolume.enable
  azure_vmware_data_store_enabled = each.value.vmWareSolution.enable
  subnet_id                       = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/HPC.Network.${each.value.resourceGroup.location}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetwork.name}/subnets/${var.virtualNetwork.subnetNameNetApp}"
  account_name                    = azurerm_netapp_account.main[each.value.accountName].name
  service_level                   = "Flexible"
  dynamic cool_access {
    for_each = each.value.coolAccess.enable ? [1] : []
    content {
      coolness_period_in_days = each.value.coolAccess.period.days
      tiering_policy          = each.value.coolAccess.policy.tiering
      retrieval_policy        = each.value.coolAccess.policy.retrieval
    }
  }
  dynamic data_protection_replication {
    for_each = each.value.replication.enable && each.value.resourceGroup.location != azurerm_resource_group.netapp[0].location ? [1] : []
    content {
      remote_volume_resource_id = "${azurerm_resource_group.netapp[0].id}/providers/Microsoft.NetApp/netAppAccounts/${var.netAppFiles.name}/capacityPools/${each.value.poolName}/volumes/${each.value.name}"
      remote_volume_location    = azurerm_resource_group.netapp[0].location
      replication_frequency     = each.value.replication.frequency
    }
  }
  dynamic export_policy_rule {
    for_each = each.value.exportPolicies
    content {
      rule_index                     = export_policy_rule.value["ruleIndex"]
      root_access_enabled            = export_policy_rule.value["rootAccess"]
      allowed_clients                = export_policy_rule.value["allowedClients"]
      protocol                       = each.value.network.protocols
      unix_read_only                 = !each.value.kerberos.enable ? export_policy_rule.value["readOnly"] : false
      unix_read_write                = !each.value.kerberos.enable ? export_policy_rule.value["readWrite"] : false
      kerberos_5_read_only_enabled   = each.value.kerberos.enable ? export_policy_rule.value["readOnly"] : false
      kerberos_5_read_write_enabled  = each.value.kerberos.enable ? export_policy_rule.value["readWrite"] : false
      kerberos_5i_read_only_enabled  = each.value.kerberos.enable ? export_policy_rule.value["readOnly"] : false
      kerberos_5i_read_write_enabled = each.value.kerberos.enable ? export_policy_rule.value["readWrite"] : false
      kerberos_5p_read_only_enabled  = each.value.kerberos.enable ? export_policy_rule.value["readOnly"] : false
      kerberos_5p_read_write_enabled = each.value.kerberos.enable ? export_policy_rule.value["readWrite"] : false
    }
  }
  depends_on = [
    azurerm_netapp_pool.main
  ]
}

#################################################################################################
# NetApp Files Backup (https://learn.microsoft.com/azure/azure-netapp-files/backup-introduction #
#################################################################################################

resource azurerm_netapp_backup_vault main {
  count               = var.netAppFiles.enable && var.netAppFiles.backup.enable ? 1 : 0
  name                = var.netAppFiles.backup.name
  resource_group_name = azurerm_netapp_account.main[0].resource_group_name
  location            = azurerm_netapp_account.main[0].location
  account_name        = azurerm_netapp_account.main[0].name
}

resource azurerm_netapp_backup_policy main {
  count                   = var.netAppFiles.enable && var.netAppFiles.backup.enable ? 1 : 0
  name                    = var.netAppFiles.backup.policy.name
  resource_group_name     = azurerm_netapp_account.main[0].resource_group_name
  location                = azurerm_netapp_account.main[0].location
  account_name            = azurerm_netapp_account.main[0].name
  daily_backups_to_keep   = var.netAppFiles.backup.policy.retention.daily
  weekly_backups_to_keep  = var.netAppFiles.backup.policy.retention.weekly
  monthly_backups_to_keep = var.netAppFiles.backup.policy.retention.monthly
  enabled                 = var.netAppFiles.backup.policy.enable
}
