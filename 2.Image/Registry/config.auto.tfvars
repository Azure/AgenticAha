# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Image.Registry"

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  name = "aihpc"
  tier = "Premium"
  dataEndpoint = {
    enable = true
  }
  zoneRedundancy = {
    enable = false
  }
  quarantinePolicy = {
    enable = false
  }
  exportPolicy = {
    enable = false
  }
  trustPolicy = {
    enable = false
  }
  anonymousPull = {
    enable = false
  }
  adminUser = {
    enable = false
  }
  retentionPolicy = {
    enable = false
    days   = 7
  }
  replicationRegions = [
    {
      name = "WestUS"
      regionEndpoint = {
        enable = true
      }
      zoneRedundancy = {
        enable = false
      }
    }
  ]
  firewallRules = [
    {
      action  = "Allow" # Task Agent
      ipRange = "40.124.64.0/25"
    }
  ]
  tasks = [
    {
      enable = true
      name   = "JobClusterXLC"
      type   = "Linux"
      docker = {
        context = {
          hostUrl     = "https://github.com/Azure/AgenticAha.git"
          accessToken = " "
        }
        filePath    = "2.Image/Registry/Docker/JobClusterXLC"
        imageNames = [
          "job-cluster-xlc"
        ]
        cache = {
          enable = false
        }
      }
      agentPool = {
        enable = false
        name   = "aihpc"
      }
      timeout = {
        seconds = 3600
      }
    },
    {
      enable = true
      name   = "JobClusterXWC"
      type   = "Windows"
      docker = {
        context = {
          hostUrl     = "https://github.com/Azure/AgenticAha.git"
          accessToken = " "
        }
        filePath = "2.Image/Registry/Docker/JobClusterXWC"
        imageNames = [
          "job-cluster-xwc"
        ]
        cache = {
          enable = false
        }
      }
      agentPool = {
        enable = false
        name   = "aihpc"
      }
      timeout = {
        seconds = 3600
      }
    }
  ]
  agentPools =[
    {
      enable = false
      name   = "aihpc"
      type   = "S1"
      count  = 1
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

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Cluster"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}
