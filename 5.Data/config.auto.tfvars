# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Data"

############################################################################################
# MySQL Flexible Server (https://learn.microsoft.com/azure/mysql/flexible-server/overview) #
############################################################################################

mySQL = {
  enable  = true
  name    = "aihpc"
  type    = "GP_Standard_D2ads_v5" # https://learn.microsoft.com/azure/mysql/flexible-server/concepts-service-tiers-storage
  version = "8.4"
  authentication = {
    sql = {
      enable = true
    }
    activeDirectory = {
      enable = true
    }
  }
  storage = {
    sizeGB = 20
    iops   = 0
    autoGrow = {
      enabled = true
    }
    ioScaling = {
      enabled = true
    }
  }
  backup = {
    retentionDays = 7
    geoRedundant = {
      enable = false
    }
    vault = {
      enable     = false
      name       = "Default"
      type       = "VaultStore"
      redundancy = "LocallyRedundant"
      softDelete = "On"
      retention = {
        days = 14
      }
      crossRegion = {
        enable = false
      }
    }
  }
  highAvailability = {
    enable = false
    mode   = "ZoneRedundant"
  }
  maintenanceWindow = {
    enable    = false
    dayOfWeek = 0
    start = {
      hour   = 0
      minute = 0
    }
  }
  databases = [
    {
      enable    = false
      name      = ""
      charset   = "utf8"
      collation = "utf8_general_ci"
    }
  ]
}

################################################################################################
# Microsoft Fabric (https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview) #
################################################################################################

msFabric = {
  capacity = {
    enable   = false
    name     = "aihpc"
    size     = "F2"
    location = "CentralUS"
  }
  workspace = {
    enable = true
    name   = "aihpc"
    capacity = {
      id = "cc5bfcb0-13fc-47b7-88c0-9f4c07a4af33"
    }
  }
}

###################################################################
# Microsoft Purview (https://learn.microsoft.com/purview/purview) #
###################################################################

msPurview = {
  enable = false
  name   = "aihpc"
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
  resourceGroupName = "HPC.Network.SouthCentralUS"
  subnetName = {
    data  = "Data"
    mySQL = "DataMySQL"
  }
}
