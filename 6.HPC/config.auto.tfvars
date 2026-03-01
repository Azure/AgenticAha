# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC"

###############################################################################################
# CycleCloud Workspace for Slurm (https://learn.microsoft.com/azure/cyclecloud/overview-ccws) #
###############################################################################################

ccWorkspace = {
  enable = false
  entraId = {
    enable = false
    app = {
      clientId = "6f74d27f-4199-4893-aae0-110a90ddfaf1"
    }
  }
  netAppFiles = {
    address      = "10.0.194.4"
    exportPath   = "/shared"
    mountOptions = "rw,hard,rsize=262144,wsize=262144,vers=3,tcp,_netdev"
  }
  cycleCloud = {
    name = "ccws"
    size = "Standard_D4as_v5"
  }
  scheduler = {
    size = "Standard_D4as_v5"
    image = {
      type = "almalinux9"
      custom = {
        enable         = false
        definitionName = "x64Lnx"
        versionId      = "1.0.0"
      }
    }
  }
  loginNode = {
    size     = "Standard_NV12ads_A10_v5"
    maxNodes = 3
    image = {
      type = "almalinux9"
      custom = {
        enable         = false
        definitionName = "x64Lnx"
        versionId      = "3.0.0"
      }
    }
  }
  slurm = {
    version = "25.05.2"
    partition = {
      hpc = {
        nodeSize = "Standard_HX176rs"
        maxNodes = 3
        image = {
          type = "almalinux9"
          custom = {
            enable         = false
            definitionName = "x64Lnx"
            versionId      = "2.0.0"
          }
        }
      }
      htc = {
        nodeSize = "Standard_HX176rs"
        maxNodes = 3
        useSpot  = false
        image = {
          type = "almalinux9"
          custom = {
            enable         = false
            definitionName = "x64Lnx"
            versionId      = "2.0.0"
          }
        }
      }
      gpu = {
        nodeSize = "Standard_ND96isr_MI300X_v5"
        maxNodes = 3
        image = {
          type = "almalinux9"
          custom = {
            enable         = false
            definitionName = "x64Lnx"
            versionId      = "2.3.0"
          }
        }
      }
    }
    jobAccounting = {
      enable = true
      mySql = {
        fqdn = "aihpc.mysql.database.azure.com"
      }
    }
    healthCheck = {
      enable = true
    }
    startCluster = false
  }
  openOnDemand = {
    enable       = true
    size         = "Standard_D4as_v5"
    userDomain   = "aihpc.com"
    startCluster = false
    image = {
      type = "almalinux9"
      custom = {
        enable         = false
        definitionName = "x64Lnx"
        versionId      = "1.0.0"
      }
    }
  }
  initMachine = {
    size = "Standard_D4as_v5"
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
    autoDelete = {
      enable = true
    }
  }
}

###########################################################
# Microsoft Discovery (https://aka.ms/MicrosoftDiscovery) #
###########################################################

discovery = {
  enable = false
  name   = "aihpc"
  region = {
    hub = "EastUS2"
    spoke = [
      {
        enable   = false
        location = "EastUS"
      }
    ]
  }
  sharedStorage = {
    enable = false
  }
}

##########################################################################################################
# Microsoft Foundry (https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry?view=foundry) #
#                   (https://learn.microsoft.com/azure/ai-foundry/concepts/architecture?view=foundry)    #
##########################################################################################################

foundry = {
  enable = true
  name    = "aihpc"
  tier    = "S0"
  subDomain = {
    name = "aihpc0"
  }
  projects = [
    {
      enable      = true
      name        = "Project1"
      displayName = "AI Project 1"
      description = ""
    },
    {
      enable      = true
      name        = "Project2"
      displayName = "AI Project 2"
      description = ""
    }
  ]
}

####################################################################################
# AI Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
####################################################################################

search = {
  enable         = true
  name           = "aihpc"
  tier           = "basic"
  hostingMode    = "default"
  replicaCount   = 1
  partitionCount = 1
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
    sshKeyPrivate = "sshKeyPrivate"
  }
}

networkSecurityPerimeter = { # https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts
  name               = "aihpc"
  profileName        = "default"
  resourceGroupName  = "HPC.Network"
  resourceAccessMode = "Enforced"
}

monitor = { # https://learn.microsoft.com/azure/azure-monitor/monitor-overview
  enable = true
  workspace = {
    name              = "aihpc"
    resourceGroupName = "HPC.Monitor"
  }
}

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  resourceGroupName = "HPC.Network.SouthCentralUS"
  subnetNameCycle   = "CycleCloud"
  subnetNameCluster = "Cluster"
  subnetNameAICore  = "AICore"
  subnetNameAIAgent = "AIAgent"
  subnetNameAIDiscovery = {
    storage = "StorageANF"
    compute = "Cluster"
  }
  privateDnsZone = {
    name              = "privatelink.blob.core.windows.net"
    resourceGroupName = "HPC.Network"
  }
  spokes = [
    {
      enable            = false
      resourceGroupName = "HPC.Network.EastUS"
      location          = "EastUS"
      nfs = {
        enable       = false
        ipAddress    = ""
        exportPath   = ""
        mountOptions = "ro,hard,rsize=262144,wsize=262144,vers=3,tcp,_netdev"
      }
    },
    {
      enable            = false
      resourceGroupName = "HPC.Network.EastUS2"
      location          = "EastUS2"
      nfs = {
        enable       = false
        ipAddress    = ""
        exportPath   = ""
        mountOptions = "ro,hard,rsize=262144,wsize=262144,vers=3,tcp,_netdev"
      }
    }
  ]
}

computeGallery = { # https://learn.microsoft.com/azure/virtual-machines/compute-galleries
  name              = "aihpc"
  resourceGroupName = "HPC.Image.Gallery"
}

storageAccount = { # https://learn.microsoft.com/azure/storage/common/storage-account-overview
  name              = "aihpc0"
  resourceGroupName = "HPC"
}
