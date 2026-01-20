# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Storage"

###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

storageAccounts = [
  {
    enable               = true
    name                 = "aihpc1"           # Name must be globally unique (lowercase alphanumeric)
    type                 = "BlockBlobStorage" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    tier                 = "Premium"          # https://learn.microsoft.com/azure/storage/common/storage-account-overview#performance-tiers
    redundancy           = "LRS"              # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    enableHttpsOnly      = true               # https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer
    enableBlobNfsV3      = true               # https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support
    enableLargeFileShare = false              # https://learn.microsoft.com/azure/storage/files/storage-how-to-create-file-share#advanced
    privateEndpointTypes = [ # https://learn.microsoft.com/azure/storage/common/storage-private-endpoints
      "blob"
    ]
    blobContainers = [ # https://learn.microsoft.com/azure/storage/blobs/storage-blobs-introduction
      {
        enable = true
        name   = "storage"
      }
    ]
    fileShares = [ # https://learn.microsoft.com/azure/storage/files/storage-files-introduction
    ]
    extendedZone = {
      enable = false
    }
  },
  {
    enable               = true
    name                 = "aihpc2"      # Name must be globally unique (lowercase alphanumeric)
    type                 = "FileStorage" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    tier                 = "Premium"     # https://learn.microsoft.com/azure/storage/common/storage-account-overview#performance-tiers
    redundancy           = "LRS"         # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    enableHttpsOnly      = true          # https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer
    enableBlobNfsV3      = false         # https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support
    enableLargeFileShare = true          # https://learn.microsoft.com/azure/storage/files/storage-how-to-create-file-share#advanced
    privateEndpointTypes = [ # https://learn.microsoft.com/azure/storage/common/storage-private-endpoints
      "file"
    ]
    blobContainers = [ # https://learn.microsoft.com/azure/storage/blobs/storage-blobs-introduction
    ]
    fileShares = [ # https://learn.microsoft.com/azure/storage/files/storage-files-introduction
      {
        enable         = false
        name           = "storage"
        sizeGB         = 5120
        accessTier     = "Premium"
        accessProtocol = "NFS"
      }
    ]
    extendedZone = {
      enable = false
    }
  }
]

#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

netAppFiles = {
  enable = true
  name   = "ANF"
  kerberos = {
    enable = false
  }
  capacityPools = [
    {
      enable  = true
      name    = "Flex"
      sizeTiB = 1
      tpMiBps = 128
      coolAccess = {
        enable = true
        period = {
          days = 31
        }
        policy = {
          tiering   = "Auto"
          retrieval = "Default"
        }
      }
      volumes = [
        {
          enable      = true
          name        = "Shared"
          path        = "shared"
          sizeGiB     = 512
          tpMiBps     = 32
          permissions = 777
          kerberos = {
            enable = false
          }
          largeVolume = {
            enable = false
          }
          vmWareSolution = {
            enable = false
          }
          replication = {
            enable    = false
            frequency = "daily"
            regions = [
              "CentralUS",
              # "EastUS",
              # "EastUS2"
            ]
          }
          network = {
            features = "Standard"
            protocols = [
              "NFSv3",
              # "NFSv4.1",
              # "CIFS"
            ]
          }
          exportPolicies = [
            {
              ruleIndex  = 1
              ownerMode  = "Restricted"
              readOnly   = false
              readWrite  = true
              rootAccess = true
              allowedClients = [
                "0.0.0.0/0"
              ]
            }
          ]
        }
      ]
    }
  ]
  backup = {
    enable = false
    name   = "ANF"
    policy = {
      enable = true
      name   = "Default"
      retention = {
        daily   = 2
        weekly  = 1
        monthly = 1
      }
    }
  }
}

##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

managedLustre = {
  enable  = false
  name    = "aihpc"
  type    = "AMLFS-Durable-Premium-40" # https://learn.microsoft.com/azure/azure-managed-lustre/create-file-system-resource-manager#file-system-type-and-size-options
  sizeTiB = 48
  blobStorage = {
    enable            = true
    accountName       = "aihpc1"
    resourceGroupName = "HPC.Storage"
    containerName = {
      archive = "lustre"
      logging = "lustre-logging"
    }
    importPrefix = "/"
  }
  maintenanceWindow = {
    dayOfWeek    = "Sunday"
    utcStartTime = "00:00"
  }
  encryption = {
    enable = false
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "storage"
  ttlSeconds = 300
}

###########################################################
# Microsoft Discovery (https://aka.ms/MicrosoftDiscovery) #
###########################################################

discovery = {
  enable   = false
  name     = "aihpc"
  location = "EastUS"
}

########################
# Brownfield Resources #
########################

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Storage"
  subnetNameNetApp  = "StorageNetApp"
  resourceGroupName = "HPC.Network.SouthCentralUS"
  extendedZone = {
    enable   = false
    name     = "LosAngeles"
    location = "WestUS"
  }
  privateDNS = {
    zoneName          = "azure.hpc"
    resourceGroupName = "HPC.Network"
  }
}

activeDirectory = { # https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview
  enable = false
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name              = "WinAD"
    resourceGroupName = "HPC.AD"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
