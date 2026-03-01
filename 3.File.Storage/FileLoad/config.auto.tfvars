# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Storage.FileLoad"

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

fileLoad = {
  mount = {
    type    = "nfs" # "lustre"
    path    = "/mnt/shared"
    target  = "10.0.194.4:/shared" # 10.0.193.24@tcp:/lustrefs
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
    sshKeyPublic  = "sshKeyPublic"
  }
}

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Storage"
  resourceGroupName = "HPC.Network.SouthCentralUS"
  privateDNS = {
    zoneName          = "azure.hpc"
    resourceGroupName = "HPC.Network"
  }
}
