# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##########################################################################################
# ANF Cache Volumes (https://learn.microsoft.com/azure/azure-netapp-files/cache-volumes) #
##########################################################################################

cacheVolumes = [
  {
    enable  = true
    name    = "CacheData"
    path    = "cachedata"
    size    = 53687091200
    tpMibps = 1
    protocols = [
      "NFSv3"
    ]
    origin = {
      clusterName = "CVO"
      vServerName = "vs1"
      volumeName  = "data1"
      addresses = [
        "10.3.193.11"
      ]
    }
  }
]

########################
# Brownfield Resources #
########################

virtualNetworkStorage = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Storage"
  resourceGroupName = "HPC.Network.CentralUS"
}

virtualNetworkCache = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "StorageNetApp"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}

netAppFiles = { # https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction
  accountName       = "ANF"
  capacityPoolName  = "Flex"
  resourceGroupName = "HPC.Storage.NetApp"
}
