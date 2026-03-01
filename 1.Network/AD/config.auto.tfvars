# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.AD"

#################################################################################################################################################
# Active Directory (https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview) #
#################################################################################################################################################

activeDirectory = {
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name = "WinAD"
    size = "Standard_D2as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "MicrosoftWindowsServer"
      product   = "WindowsServer"
      name      = "2025-Datacenter"
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
    }
  }
}

activeDirectoryClient = {
  enable = false
  domain = {
    name       = "azure.hpc"
    serverName = "WinAD"
  }
  machine = {
    name = "WinADClient"
    size = "Standard_D2as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "MicrosoftWindowsDesktop"
      product   = "Windows-11"
      name      = "Win11-25H2-Pro"
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
  }
}

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "AD"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}
