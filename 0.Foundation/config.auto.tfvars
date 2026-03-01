# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

subscriptionId = "" # REQUIRED
hubRegion      = "SouthCentralUS" # Set from "az account list-locations --query [].name"

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

managedIdentity = {
  name = "aihpc"
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

keyVault = {
  name                        = "aihpc"
  type                        = "standard"
  enableForDeployment         = true
  enableForDiskEncryption     = true
  enableForTemplateDeployment = true
  enablePurgeProtection       = false
  utcExpirationDateTime       = "2099-12-31T23:59:59Z"
  softDeleteRetentionDays     = 90
  sshKeySizeBits              = 2048
  secrets = [
    {
      name  = "AdminUsername"
      value = "hpcadmin"
    },
    {
      name  = "AdminPassword"
      value = "P@ssword123456"
    }
  ]
}

#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

storage = {
  account = {
    type        = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    redundancy  = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    performance = "Standard"
  }
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

monitor = {
  name = "aihpc"
  workspace = {
    logAnalytics = {
      tier = "PerGB2018"
    }
    ingestAlert = {
      enable    = false
      name      = "Monitor Workspace Ingest"
      severity  = 2  # Warning
      threshold = 90 # Percent
    }
  }
  appInsights = {
    type = "web"
  }
  grafanaDashboard = {
    tier    = "Standard"
    version = 12
  }
  dataRetention = {
    days = 90
  }
}

#########################################################################
# Policy (https://learn.microsoft.com/azure/governance/policy/overview) #
#########################################################################

policy = {
  denyPasswordAuthLinux = {
    enable = false
  }
}
