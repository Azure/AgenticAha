# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Job.Manager"

###############################################################################################
# CycleCloud Workspace for Slurm (https://learn.microsoft.com/azure/cyclecloud/overview-ccws) #
###############################################################################################

ccws = {
  enable            = true
  deploymentName    = "CycleCloud Slurm Workspace"
  resourceGroupName = "HPC.CycleCloud.Slurm"
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "JobManagerXL"
    size   = "Standard_D4as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      versionId         = "1.0.0"
      galleryName       = "aihpc"
      definitionName    = "LnxX"
      resourceGroupName = "HPC.Image.Gallery"
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "cse.sh"
        parameters = {
          autoScale = {
            enable                   = false
            resourceGroupName        = "HPC.Job.Cluster"
            jobManagerName           = "Slurm"
            jobClusterName           = "JobClusterXLCA"
            jobClusterNodeLimit      = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
    }
    monitor = {
      enable = true
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
    name   = "JobManagerXW"
    size   = "Standard_D4as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      versionId         = "1.0.0"
      galleryName       = "aihpc"
      definitionName    = "WinServer"
      resourceGroupName = "HPC.Image.Gallery"
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "cse.ps1"
        parameters = {
          autoScale = {
            enable                   = false
            resourceGroupName        = "HPC.Job.Cluster"
            jobManagerName           = "Slurm"
            jobClusterName           = "JobClusterXWCA"
            jobClusterNodeLimit      = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
    }
    monitor = {
      enable = true
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
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "job"
  ttlSeconds = 300
}

########################
# Brownfield Resources #
########################

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Cluster"
  edgeZoneName      = "" # "LosAngeles"
  resourceGroupName = "HPC.Network.SouthCentralUS" # "HPC.Network.WestUS.LosAngeles"
}

privateDNS = {
  zoneName          = "azure.hpc"
  resourceGroupName = "HPC.Network"
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
