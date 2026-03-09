# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###############################################################################################
# CycleCloud Workspace for Slurm (https://learn.microsoft.com/azure/cyclecloud/overview-ccws) #
###############################################################################################

variable ccWorkspace {
  type = object({
    enable = bool
    entraId = object({
      enable = bool
      app = object({
        clientId = string
      })
    })
    cycleCloud = object({
      cluster = object({
        name = string
      })
      machine = object({
        name = string
        size = string
      })
    })
    loginNode = object({
      size     = string
      maxNodes = number
      image = object({
        type = string
        custom = object({
          enable         = bool
          definitionName = string
          versionId      = string
        })
      })
    })
    scheduler = object({
      size = string
      image = object({
        type = string
        custom = object({
          enable         = bool
          definitionName = string
          versionId      = string
        })
      })
    })
    slurm = object({
      version = string
      partition = object({
        hpc = object({
          nodeSize = string
          maxNodes = number
          image = object({
            type = string
            custom = object({
              enable         = bool
              definitionName = string
              versionId      = string
            })
          })
        })
        htc = object({
          nodeSize = string
          maxNodes = number
          useSpot  = bool
          image = object({
            type = string
            custom = object({
              enable         = bool
              definitionName = string
              versionId      = string
            })
          })
        })
        gpu = object({
          nodeSize = string
          maxNodes = number
          image = object({
            type = string
            custom = object({
              enable         = bool
              definitionName = string
              versionId      = string
            })
          })
        })
      })
      jobAccounting = object({
        enable = bool
        mySql = object({
          fqdn = string
        })
       })
       healthCheck = object({
         enable = bool
       })
      startCluster = bool
    })
    openOnDemand = object({
      enable       = bool
      size         = string
      userDomain   = string
      startCluster = bool
      image = object({
        type = string
        custom = object({
          enable         = bool
          definitionName = string
          versionId      = string
        })
      })
    })
    netAppFiles = object({
      address      = string
      exportPath   = string
      mountOptions = string
    })
    initMachine = object({
      size = string
      image = object({
        publisher = string
        product   = string
        name      = string
        version   = string
      })
      osDisk = object({
        storageType = string
        cachingMode = string
        sizeGB      = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshKeyPublic = string
        passwordAuth = object({
          disable = bool
        })
      })
      autoDelete = object({
        enable = bool
      })
    })
  })
}

locals {
  ccwsCluster = {
    resourceGroup = {
      value = "${var.resourceGroupName}.CycleCloud"
    }
    location = {
      value = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].location
    }
    entraIdInfo = {
      value = {
        type              = var.ccWorkspace.entraId.enable ? "enabled" : "disabled"
        clientId          = var.ccWorkspace.entraId.app.clientId
        tenantId          = data.azurerm_client_config.current.tenant_id
        managedIdentityId = data.azurerm_user_assigned_identity.main.id
      }
    }
    adminUsername = {
      value = data.azurerm_key_vault_secret.admin_username.value
    }
    adminPassword = {
      value = data.azurerm_key_vault_secret.admin_password.value
    }
    adminSshPublicKey = {
      value = data.azurerm_key_vault_secret.ssh_key_public.value
    }
    clusterName = {
      value = var.ccWorkspace.cycleCloud.cluster.name
    }
    ccVMName = {
      value = var.ccWorkspace.cycleCloud.machine.name
    }
    ccVMSize = {
      value = var.ccWorkspace.cycleCloud.machine.size
    }
    sharedFilesystem = {
      value = {
        type         = "nfs-existing"
        ipAddress    = var.ccWorkspace.netAppFiles.address
        exportPath   = var.ccWorkspace.netAppFiles.exportPath
        mountOptions = var.ccWorkspace.netAppFiles.mountOptions
      }
    }
    additionalFilesystem = {
      value = {
        type = "disabled"
      }
    }
    network = {
      value = {
        type             = "existing"
        name             = var.virtualNetwork.name
        id               = data.azurerm_virtual_network.main[var.virtualNetwork.resourceGroupName].id
        cyclecloudSubnet = var.virtualNetwork.subnetNameCycle
        computeSubnet    = var.virtualNetwork.subnetNameCluster
      }
    }
    storagePrivateDnsZone = {
      value = {
        type     = "existing"
        id       = data.azurerm_private_dns_zone.main.id
        vnetLink = false
      }
    }
    databaseAdminPassword = {
      value = data.azurerm_key_vault_secret.admin_password.value
    }
    databaseConfig = {
      value = {
        type         = var.ccWorkspace.slurm.jobAccounting.enable ? "fqdn" : "disabled"
        fqdn         = var.ccWorkspace.slurm.jobAccounting.mySql.fqdn
        databaseUser = data.azurerm_key_vault_secret.admin_username.value
      }
    }
    acceptMarketplaceTerms = {
      value = true
    }
    slurmSettings = {
      value = {
        version            = var.ccWorkspace.slurm.version
        startCluster       = var.ccWorkspace.slurm.startCluster
        healthCheckEnabled = var.ccWorkspace.slurm.healthCheck.enable
      }
    }
    schedulerNode = {
      value = {
        sku     = var.ccWorkspace.scheduler.size
        osImage = var.ccWorkspace.scheduler.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${var.ccWorkspace.scheduler.image.custom.definitionName}/versions/${var.ccWorkspace.scheduler.image.custom.versionId}" : var.ccWorkspace.scheduler.image.type
      }
    }
    loginNodes = {
      value = {
        sku          = var.ccWorkspace.loginNode.size
        osImage      = var.ccWorkspace.loginNode.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${var.ccWorkspace.loginNode.image.custom.definitionName}/versions/${var.ccWorkspace.loginNode.image.custom.versionId}" : var.ccWorkspace.loginNode.image.type
        maxNodes     = var.ccWorkspace.loginNode.maxNodes
        initialNodes = 1
      }
    }
    hpc = {
      value = {
        sku      = var.ccWorkspace.slurm.partition.hpc.nodeSize
        osImage  = var.ccWorkspace.slurm.partition.hpc.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${var.ccWorkspace.slurm.partition.hpc.image.custom.definitionName}/versions/${var.ccWorkspace.slurm.partition.hpc.image.custom.versionId}" : var.ccWorkspace.slurm.partition.hpc.image.type
        maxNodes = var.ccWorkspace.slurm.partition.hpc.maxNodes
      }
    }
    htc = {
      value = {
        sku      = var.ccWorkspace.slurm.partition.htc.nodeSize
        osImage  = var.ccWorkspace.slurm.partition.htc.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${var.ccWorkspace.slurm.partition.htc.image.custom.definitionName}/versions/${var.ccWorkspace.slurm.partition.htc.image.custom.versionId}" : var.ccWorkspace.slurm.partition.htc.image.type
        maxNodes = var.ccWorkspace.slurm.partition.htc.maxNodes
        useSpot  = var.ccWorkspace.slurm.partition.htc.useSpot
      }
    }
    gpu = {
      value = {
        sku      = var.ccWorkspace.slurm.partition.gpu.nodeSize
        osImage  = var.ccWorkspace.slurm.partition.gpu.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${var.ccWorkspace.slurm.partition.gpu.image.custom.definitionName}/versions/${var.ccWorkspace.slurm.partition.gpu.image.custom.versionId}" : var.ccWorkspace.slurm.partition.gpu.image.type
        maxNodes = var.ccWorkspace.slurm.partition.gpu.maxNodes
      }
    }
    ood = {
      value = {
        type                 = var.ccWorkspace.entraId.enable && var.ccWorkspace.openOnDemand.enable ? "enabled" : "disabled"
        sku                  = var.ccWorkspace.openOnDemand.size
        osImage              = var.ccWorkspace.openOnDemand.image.custom.enable ? "${data.azurerm_shared_image_gallery.main.id}/images/${var.ccWorkspace.openOnDemand.image.custom.definitionName}/versions/${var.ccWorkspace.openOnDemand.image.custom.versionId}" : var.ccWorkspace.openOnDemand.image.type
        userDomain           = var.ccWorkspace.openOnDemand.userDomain
        appId                = var.ccWorkspace.entraId.app.clientId
        appTenantId          = data.azurerm_client_config.current.tenant_id
        appManagedIdentityId = data.azurerm_user_assigned_identity.main.id
        startCluster         = var.ccWorkspace.openOnDemand.startCluster
        registerEntraIDApp   = false
      }
    }
    monitoring = {
      value = {
        type              = var.monitor.enable ? "enabled" : "disabled"
        dcrId             = data.azurerm_monitor_workspace.main.default_data_collection_rule_id
        ingestionEndpoint = "${data.azurerm_monitor_data_collection_endpoint.main.metrics_ingestion_endpoint}/dataCollectionRules/${data.azurerm_monitor_data_collection_rule.main.immutable_id}/streams/Microsoft-PrometheusMetrics/api/v1/write?api-version=2023-04-24"
      }
    }
    tags = {
      value = {
      }
    }
  }
  ccwsClusters = var.ccWorkspace.enable ? concat([local.ccwsCluster], [
    for spoke in var.virtualNetwork.spokes : merge(local.ccwsCluster, {
      resourceGroup = {
        value = "${local.ccwsCluster.resourceGroup.value}.${spoke.location}"
      }
      location = {
        value = spoke.location
      }
      network = {
        value = merge(local.ccwsCluster.network.value, {
          id = data.azurerm_virtual_network.main[spoke.resourceGroupName].id
        })
      }
      sharedFilesystem = {
        value = merge(local.ccwsCluster.sharedFilesystem.value, {
          ipAddress    = spoke.nfs.enable && spoke.nfs.ipAddress != "" ? spoke.nfs.ipAddress : local.ccwsCluster.sharedFilesystem.value.ipAddress
          exportPath   = spoke.nfs.enable && spoke.nfs.exportPath != "" ? spoke.nfs.exportPath : local.ccwsCluster.sharedFilesystem.value.exportPath
          mountOptions = spoke.nfs.enable && spoke.nfs.mountOptions != "" ? spoke.nfs.mountOptions : local.ccwsCluster.sharedFilesystem.value.mountOptions
        })
      }
    }) if spoke.enable
  ]) : []
  initMachine = merge(var.ccWorkspace.initMachine, {
    adminLogin = merge(var.ccWorkspace.initMachine.adminLogin, {
      userName     = var.ccWorkspace.initMachine.adminLogin.userName != "" ? var.ccWorkspace.initMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
      userPassword = var.ccWorkspace.initMachine.adminLogin.userPassword != "" ? var.ccWorkspace.initMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      sshKeyPublic = var.ccWorkspace.initMachine.adminLogin.sshKeyPublic != "" ? var.ccWorkspace.initMachine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
    })
  })
}

resource terraform_data mysql {
  count = var.ccWorkspace.enable ? 1 : 0
  provisioner local-exec {
    command = "az mysql flexible-server start --resource-group ${var.mySqlFlexibleServer.resourceGroupName} --name ${var.mySqlFlexibleServer.name}"
  }
}

resource local_file ccws {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  filename = "${lower(each.value.resourceGroup.value)}.json"
  content  = jsonencode(each.value)
  depends_on = [
    terraform_data.mysql
  ]
}

resource terraform_data ccws {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  provisioner local-exec {
    interpreter = ["pwsh","-NoProfile","-NonInteractive","-Command"]
    command = <<-PWSH
      & "${path.module}/ccws.create.ps1" -regionName ${each.value.location.value} -resourceGroupName ${each.value.resourceGroup.value} -parameterConfigfile ${local_file.ccws[each.value.resourceGroup.value].filename}
    PWSH
  }
  depends_on = [
    azurerm_resource_group.cyclecloud
  ]
}
