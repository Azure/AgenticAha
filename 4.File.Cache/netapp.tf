# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##########################################################################################
# ANF Cache Volumes (https://learn.microsoft.com/azure/azure-netapp-files/cache-volumes) #
##########################################################################################

variable cacheVolumes {
  type = list(object({
    enable    = bool
    name      = string
    path      = string
    size      = number
    tpMibps   = number
    protocols = list(string)
    origin = object({
      clusterName = string
      vServerName = string
      volumeName  = string
      addresses   = list(string)
    })
  }))
}

resource azapi_resource cache {
  for_each = {
    for cacheVolume in var.cacheVolumes : cacheVolume.name => cacheVolume if cacheVolume.enable
  }
  name      = each.value.name
  type      = "Microsoft.NetApp/netAppAccounts/capacityPools/caches@2025-09-01-preview"
  parent_id = "${data.azurerm_resource_group.cache.id}/providers/Microsoft.NetApp/netAppAccounts/${var.netAppFiles.accountName}/capacityPools/${var.netAppFiles.capacityPoolName}"
  location  = data.azurerm_resource_group.cache.location
  body = {
    properties = {
      peeringSubnetResourceId = data.azurerm_subnet.storage.id
      cacheSubnetResourceId   = data.azurerm_subnet.cache.id
      filepath                = each.value.path
      size                    = each.value.size
      throughputMibps         = each.value.tpMibps
      protocolTypes           = each.value.protocols
      originClusterInformation = {
        peerClusterName = each.value.origin.clusterName
        peerVserverName = each.value.origin.vServerName
        peerVolumeName  = each.value.origin.volumeName
        peerAddresses   = each.value.origin.addresses
      }
      encryptionKeySource = "Microsoft.NetApp"
    }
  }
}
