# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###########################################################################################
# NetApp CVO (https://marketplace.microsoft.com/product/netapp.netapp-ontap-cloud-direct) #
###########################################################################################

netAppCVO = {
  enable = false
  name   = "NetApp-CVO"
  resourceGroup = {
    name     = "CVO"
    location = "CentralUS"
  }
  machine = {
    namePrefix = "cvo"
    size       = "Standard_E8ds_v5"
  }
  highAvailability = {
    zone = "1"
  }
}

###################################################################################################
# NetApp Files Cache Volumes (https://learn.microsoft.com/azure/azure-netapp-files/cache-volumes) #
###################################################################################################

netAppFiles = {
  accountName       = "aihpc"
  capacityPoolName  = "flex"
  resourceGroupName = "HPC.Storage.NetAppFiles"
  volumeDestruction = {
    prevent = false
  }
  cacheVolumes = [
    {
      enable         = false
      name           = "cache1"
      path           = "cache1"
      sizeGiB        = 50
      tpGiBps        = 12.5
      readWrite      = false
      allowedClients = "0.0.0.0/0"
      enabledProtocols = [
        "NFSv3"
      ]
      origin = {
        clusterName = "cvo"
        vServerName = "vs1"
        volumeName  = "vs1_root"
        addresses = [
          "10.3.193.5",
          "10.3.193.18"
        ]
      }
    },
    {
      enable         = false
      name           = "cache2"
      path           = "cache2"
      sizeGiB        = 50
      tpGiBps        = 12.5
      readWrite      = false
      allowedClients = "0.0.0.0/0"
      enabledProtocols = [
        "NFSv3"
      ]
      origin = {
        clusterName = "cvo"
        vServerName = "vs1"
        volumeName  = "vs1_root"
        addresses = [
          "10.3.193.5",
          "10.3.193.18"
        ]
      }
    },
    {
      enable         = false
      name           = "cache3"
      path           = "cache3"
      sizeGiB        = 50
      tpGiBps        = 12.5
      readWrite      = true
      allowedClients = "0.0.0.0/0"
      enabledProtocols = [
        "NFSv3"
      ]
      origin = {
        clusterName = "cvo"
        vServerName = "vs1"
        volumeName  = "vs1_root"
        addresses = [
          "10.3.193.5",
          "10.3.193.18"
        ]
      }
    }
  ]
}

#########################
# Dependency References #
#########################

managedIdentity = { # https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview
  name              = "aihpc"
  resourceGroupName = "HPC.Identity"
}

keyVault = { # https://learn.microsoft.com/azure/key-vault/general/overview
  name              = "aihpc"
  resourceGroupName = "HPC"
  secretName = {
    adminUsername = "adminUsername"
    adminPassword = "adminPassword"
  }
}

virtualNetworkStorage = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Storage"
  resourceGroupName = "HPC.Network.CentralUS"
  securityGroupName = "HPC-CentralUS-Storage"
}

virtualNetworkCache = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "StorageANF"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}
