# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Data"

############################################################################################
# MySQL Flexible Server (https://learn.microsoft.com/azure/mysql/flexible-server/overview) #
############################################################################################

mySQL = {
  enable  = true
  name    = "aihpc"
  type    = "B_Standard_B1ms" # https://learn.microsoft.com/azure/mysql/flexible-server/concepts-service-tiers-storage
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

######################################################################################
# Fabric (https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview) #
######################################################################################

fabric = {
  enable = false
  workspace = {
    name = "aihpc"
  }
  capacity = {
    name   = "aihpc"
    size   = "F2"
  }
}

#########################################################
# Purview (https://learn.microsoft.com/purview/purview) #
#########################################################

purview = {
  enable = false
  name   = "aihpc"
}

########################
# Brownfield Resources #
########################

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  resourceGroupName = "HPC.Network.SouthCentralUS"
  subnetName = {
    data  = "Data"
    mySQL = "DataMySQL"
  }
}
