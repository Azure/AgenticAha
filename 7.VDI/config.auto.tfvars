# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.VDI"

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "VDIUserXLGN"
    size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      marketplace = {
        publisher = "AlmaLinux"
        offer     = "AlmaLinux-HPC"
        sku       = "9-HPC-Gen2"
        version   = "Latest"
      }
      custom = {
        enable         = false
        definitionName = "x64Lnx"
        versionId      = "3.0.0"
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 1024
      hibernation = {
        enable = false
      }
    }
    extension = {
      avdHost = {
        enable   = false
        poolName = "aihpc"
      }
      custom = {
        enable   = false
        fileName = "cse.sh"
        parameters = {
        }
      }
    }
    monitor = {
      enable = false
      metric = {
        category = "AllMetrics"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = true
      }
    }
  },
  {
    enable = false
    name   = "VDIUserXLGA"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      marketplace = {
        publisher = "AlmaLinux"
        offer     = "AlmaLinux-HPC"
        sku       = "9-HPC-Gen2"
        version   = "Latest"
      }
      custom = {
        enable         = false
        definitionName = "x64Lnx"
        versionId      = "3.1.0"
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 1024
      hibernation = {
        enable = false
      }
    }
    extension = {
      avdHost = {
        enable   = false
        poolName = "aihpc"
      }
      custom = {
        enable   = false
        fileName = "cse.sh"
        parameters = {
        }
      }
    }
    monitor = {
      enable = false
      metric = {
        category = "AllMetrics"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = true
      }
    }
  },
  {
    enable = false
    name   = "VDIUserAL"
    size   = "Standard_E32ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      marketplace = {
        publisher = "AlmaLinux"
        offer     = "AlmaLinux-ARM"
        sku       = "9-ARM-Gen2"
        version   = "Latest"
      }
      custom = {
        enable         = false
        definitionName = "a64Lnx"
        versionId      = "3.0.0"
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 1024
      hibernation = {
        enable = false
      }
    }
    extension = {
      avdHost = {
        enable   = false
        poolName = "aihpc"
      }
      custom = {
        enable   = false
        fileName = "cse.sh"
        parameters = {
        }
      }
    }
    monitor = {
      enable = false
      metric = {
        category = "AllMetrics"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = true
      }
    }
  },
  {
    enable = false
    name   = "VDIUserXWGN"
    size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      marketplace = {
        publisher = "MicrosoftWindowsDesktop"
        offer     = "Windows-11"
        sku       = "Win11-25H2-Pro"
        version   = "Latest"
      }
      custom = {
        enable         = false
        definitionName = "x64WinClient"
        versionId      = "3.0.0"
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 1024
      hibernation = {
        enable = false
      }
    }
    extension = {
      avdHost = {
        enable   = true
        poolName = "aihpc"
      }
      custom = {
        enable   = false
        fileName = "cse.ps1"
        parameters = {
        }
      }
    }
    monitor = {
      enable = false
      metric = {
        category = "AllMetrics"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = false
      }
    }
  },
  {
    enable = false
    name   = "VDIUserXWGA"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      marketplace = {
        publisher = "MicrosoftWindowsDesktop"
        offer     = "Windows-11"
        sku       = "Win11-25H2-Pro"
        version   = "Latest"
      }
      custom = {
        enable         = false
        definitionName = "x64WinClient"
        versionId      = "3.1.0"
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 1024
      hibernation = {
        enable = false
      }
    }
    extension = {
      avdHost = {
        enable   = true
        poolName = "aihpc"
      }
      custom = {
        enable   = false
        fileName = "cse.ps1"
        parameters = {
        }
      }
    }
    monitor = {
      enable = false
      metric = {
        category = "AllMetrics"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = false
      }
    }
  },
  {
    enable = false
    name   = "VDIUserAW"
    size   = "Standard_E32ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      marketplace = {
        publisher = "MicrosoftWindowsDesktop"
        offer     = "Windows11Preview-ARM64"
        sku       = "Win11-25H2-Pro"
        version   = "Latest"
      }
      custom = {
        enable         = false
        definitionName = "a64WinClient"
        versionId      = "3.0.0"
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 1024
      hibernation = {
        enable = false
      }
    }
    extension = {
      avdHost = {
        enable   = true
        poolName = "aihpc"
      }
      custom = {
        enable   = false
        fileName = "cse.ps1"
        parameters = {
        }
      }
    }
    monitor = {
      enable = false
      metric = {
        category = "AllMetrics"
      }
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
]

###############################################################################
# Cendio ThinLinc (https://marketplace.microsoft.com/product/cendio.thinlinc) #
###############################################################################

thinLinc = {
  enable = false
  name   = "aihpc"
  size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
  image = {
    publisher = "Cendio"
    product   = "ThinLinc"
    name      = "ThinLinc-AlmaLinux-9"
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

################################################################################
# Virtual Desktop (https://learn.microsoft.com/azure/virtual-desktop/overview) #
################################################################################

virtualDesktop = {
  enable = true
  workspace = {
    name        = "aihpc"
    displayName = "AI HPC Workspace"
    description = ""
  }
  hostPool = {
    name        = "aihpc"
    displayName = "AI HPC Host Pool"
    description = ""
    userShared = {
      enable      = false
      maxSessions = 3
    }
    assignmentType = {
      personal = "Automatic"
      pooled   = "BreadthFirst"
    }
    startMachine = {
      onConnect = true
    }
    testEnvironment = {
      enable = true
    }
    rdp = {
      properties = ""
    }
    expiration = {
      hours = 720
    }
  }
  appGroups = [
    {
      enable      = true
      name        = "aihpc-desktop"
      displayName = "AI HPC Desktop"
      description = ""
      type        = "Desktop"
      apps = [
        {
          enable      = false
          name        = ""
          displayName = ""
          description = ""
          filePath    = ""
          commandLine = {
            policy    = "Allow"
            arguments = ""
          }
          showInPortal = {
            enable = true
          }
        }
      ]
    },
    {
      enable      = false
      name        = "aihpc-app"
      displayName = "AI HPC App"
      description = ""
      type        = "RemoteApp"
      apps = [
        {
          enable      = false
          name        = ""
          displayName = ""
          description = ""
          filePath    = ""
          commandLine = {
            policy    = "Allow"
            arguments = ""
          }
          showInPortal = {
            enable = true
          }
        }
      ]
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
    sshKeyPublic  = "sshKeyPublic"
  }
}

monitor = { # https://learn.microsoft.com/azure/azure-monitor/monitor-overview
  workspace = {
    logAnalytics = {
      name              = "aihpc"
      resourceGroupName = "HPC.Monitor"
    }
  }
}

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "VDI"
  edgeZoneName      = "" # "LosAngeles"
  resourceGroupName = "HPC.Network.SouthCentralUS" # "HPC.Network.WestUS.LosAngeles"
}

activeDirectory = { # https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview
  enable = false
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name = "WinAD"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}

computeGallery = { # https://learn.microsoft.com/azure/virtual-machines/compute-galleries
  name              = "aihpc"
  resourceGroupName = "HPC.Image.Gallery"
}
