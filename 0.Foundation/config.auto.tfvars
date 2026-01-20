# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

subscriptionId  = "" # REQUIRED
defaultLocation = "SouthCentralUS" # Set from "az account list-locations --query [].name"

#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

storage = {
  account = {
    type        = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    redundancy  = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    performance = "Standard"
  }
  encryption = {
    infrastructure = {
      enable = true
    }
    service = {
      customKey = {
        enable = false
      }
    }
  }
}

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
  enableTrustedServices       = true
  enablePurgeProtection       = false
  utcExpirationDateTime       = "2099-12-31T23:59:59Z"
  softDeleteRetentionDays     = 90
  secrets = [
    {
      name  = "AdminUsername"
      value = "hpcadmin"
    },
    {
      name  = "AdminPassword"
      value = "P@ssword123456"
    },
    {
      name  = "ServiceUsername"
      value = "hpcservice"
    },
    {
      name  = "ServicePassword"
      value = "P@ssword123456"
    }
  ]
  keys = [
    {
      name = "DataEncryption"
      type = "RSA"
      size = 4096
      operations = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
    }
  ]
  certificates = [
  ]
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

monitor = {
  name = "aihpc"
  logAnalytics = {
    workspace = {
      tier = "PerGB2018"
    }
  }
  applicationInsights = {
    type = "web"
  }
  monitorWorkspace = {
    ingestAlert = {
      enable    = false
      name      = "Monitor Workspace Ingest"
      severity  = 2  # Warning
      threshold = 90 # Percent
    }
  }
  grafanaDashboard = {
    tier    = "Standard"
    version = 11
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
    enable = true
  }
}
