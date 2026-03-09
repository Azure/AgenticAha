# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###################################################################################################
# NetApp Files Cache Volumes (https://learn.microsoft.com/azure/azure-netapp-files/cache-volumes) #
###################################################################################################

variable netAppFiles {
  type = object({
    accountName       = string
    capacityPoolName  = string
    resourceGroupName = string
    volumeDestruction = object({
      prevent = bool
    })
    cacheVolumes = list(object({
      enable           = bool
      name             = string
      path             = string
      sizeGiB          = number
      tpGiBps          = number
      readWrite        = bool
      allowedClients   = string
      enabledProtocols = list(string)
      origin = object({
        clusterName = string
        vServerName = string
        volumeName  = string
        addresses   = list(string)
      })
    }))
  })
}

locals {
  cacheVersion = "api-version=2025-12-15-preview"
  cacheVolumes = [
    for cacheVolume in var.netAppFiles.cacheVolumes : merge(cacheVolume, {
      requestUrl = "https://management.azure.com/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.netAppFiles.resourceGroupName}/providers/Microsoft.NetApp/netAppAccounts/${var.netAppFiles.accountName}/capacityPools/${var.netAppFiles.capacityPoolName}/caches/${cacheVolume.name}?${local.cacheVersion}"
      requestBody = {
        location = data.azurerm_resource_group.cache.location
        zones = [
          var.netAppCVO.highAvailability.zone
        ]
        properties = {
          peeringSubnetResourceId = data.azurerm_subnet.cache.id
          cacheSubnetResourceId   = data.azurerm_subnet.cache.id
          filepath                = cacheVolume.path
          size                    = cacheVolume.sizeGiB * pow(1024, 3)
          throughputMibps         = cacheVolume.tpGiBps * 1024
          protocolTypes           = cacheVolume.enabledProtocols
          encryptionKeySource     = "Microsoft.NetApp"
          originClusterInformation = {
            peerClusterName = cacheVolume.origin.clusterName
            peerVserverName = cacheVolume.origin.vServerName
            peerVolumeName  = cacheVolume.origin.volumeName
            peerAddresses   = cacheVolume.origin.addresses
          }
          exportPolicy = {
            rules = [
              {
                ruleIndex           = 1
                unixReadOnly        = !cacheVolume.readWrite
                unixReadWrite       = cacheVolume.readWrite
                allowedClients      = cacheVolume.allowedClients
                nfsv3               = contains(cacheVolume.enabledProtocols, "NFSv3")
                nfsv41              = contains(cacheVolume.enabledProtocols, "NFSv4")
                kerberos5ReadOnly   = false
                kerberos5ReadWrite  = false
                kerberos5iReadOnly  = false
                kerberos5iReadWrite = false
                kerberos5pReadOnly  = false
                kerberos5pReadWrite = false
              }
            ]
          }
        }
      }
    }) if cacheVolume.enable
  ]
}

resource terraform_data cache_volume {
  for_each = {
    for cacheVolume in local.cacheVolumes : cacheVolume.name => cacheVolume
  }
  input = {
    requestUrl = each.value.requestUrl
    readWrite  = each.value.readWrite
  }
  provisioner local-exec {
    interpreter = ["pwsh","-NoProfile","-NonInteractive","-Command"]
    command = <<-PWSH
      & "${path.module}/netappfiles.create.ps1" -cacheRequestUrl ${each.value.requestUrl} -cacheRequestBody '${jsonencode(each.value.requestBody)}'
    PWSH
    when = create
  }
  provisioner local-exec {
    interpreter = ["pwsh","-NoProfile","-NonInteractive","-Command"]
    command = <<-PWSH
      & "${path.module}/netappfiles.destroy.ps1" -cacheRequestUrl ${self.output.requestUrl} -cacheReadWrite ${self.output.readWrite ? "$true" : "$false"}
    PWSH
    when = destroy
  }
  depends_on = [
    azurerm_resource_group_template_deployment.netapp_cvo
  ]
}
