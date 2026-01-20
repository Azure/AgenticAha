# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.AI"

####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

aiServices = {
  enable = true
  name   = "aihpc"
  tier   = "S0"
  domain = {
    name = ""
    fqdn = [
    ]
  }
}

#################################################################################################################
# Machine Learning (https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) #
#################################################################################################################

aiMachineLearning = {
  enable = true
  workspace = {
    name = "aihpc"
    tier = "Basic"
    type = "Default"
  }
}

##########################################################################################################
# Microsoft Foundry (https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry?view=foundry) #
##########################################################################################################

aiFoundry = {
  enable = true
  name   = "aihpc"
  highBusinessImpact = {
    enable = false
  }
  projects = [
    {
      enable = true
      name   = "aihpc0"
      highBusinessImpact = {
        enable = false
      }
    }
  ]
}

####################################################################################
# AI Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
####################################################################################

aiSearch = {
  enable         = true
  name           = "aihpc"
  tier           = "free"
  hostingMode    = "default"
  replicaCount   = 1
  partitionCount = 1
  sharedPrivateAccess = {
    enable = false
  }
}

########################
# Brownfield Resources #
########################

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "AI"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}

storageAccount = { # https://learn.microsoft.com/azure/storage/common/storage-account-overview
  name              = "aihpc0"
  resourceGroupName = "HPC"
}

applicationInsights = { # https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview
  enable            = true
  name              = "aihpc"
  resourceGroupName = "HPC.Monitor"
}

containerRegistry = { # https://learn.microsoft.com/azure/container-registry/container-registry-intro
  enable            = true
  name              = "aihpc"
  resourceGroupName = "HPC.Image.Registry"
}
