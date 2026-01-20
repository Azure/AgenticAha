# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Storage.BulkLoad"

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

bulkLoad = {
  mount = {
    type    = "nfs" # "lustre"
    path    = "/mnt/data"
    target  = "10.0.194.4:/data" # 10.0.193.24@tcp:/lustrefs
    options = "vers=3" # "noatime"
  }
  machine = {
    name = "aihpc"
    size = "Standard_D4as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "AlmaLinux"
      product   = "AlmaLinux-HPC"
      name      = "9-HPC-Gen2"
      version   = "Latest"
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = true
      }
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
  }
}

########################
# Brownfield Resources #
########################

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Storage"
  resourceGroupName = "HPC.Network.SouthCentralUS"
  privateDNS = {
    zoneName          = "azure.hpc"
    resourceGroupName = "HPC.Network"
  }
}
