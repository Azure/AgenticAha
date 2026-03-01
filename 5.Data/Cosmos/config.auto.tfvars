# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Data.Cosmos"

####################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/overview) #
####################################################################

cosmos = {
  type = "Standard"
  geoLocations = [
    {
      enable = true
      name   = "CentralUS"
      failover = {
        priority = 0
      }
      zoneRedundant = {
        enable = false
      }
    }
  ]
  dataConsistency = {
    policyLevel = "Session"
    maxStaleness = {
      intervalSeconds = 5
      itemUpdateCount = 100
    }
  }
  serverless = {
    enable = true
  }
  burstCapacity = {
    enable = false
  }
  dataAnalytics = {
    enable     = false
    schemaType = "FullFidelity"
  }
  aggregationPipeline = {
    enable = false
  }
  automaticFailover = {
    enable = false
  }
  multiRegionWrite = {
    enable = false
  }
  partitionMerge = {
    enable = false
  }
  backup = {
    type              = "Periodic"
    tier              = null
    retentionHours    = 8
    intervalMinutes   = 240
    storageRedundancy = "Geo"
  }
}

noSQL = {
  account = {
    name = "aihpc"
    dedicatedGateway = {
      enable = false
      size   = "Cosmos.D4s"
      count  = 1
    }
  }
  databases = [
    {
      enable = true
      name   = "db1"
      throughput = {
        requestUnits = null
        autoScale = {
          enable = false
        }
      }
      containers = [
        {
          enable = true
          name   = "Asset"
          throughput = {
            requestUnits = null
            autoScale = {
              enable = false
            }
          }
          partitionKey = {
            version = 2
            paths = [
             "/tenantId"
            ]
          }
          # geospatial = {
          #   type = "Geography"
          # }
          indexPolicy = {
            mode = "consistent"
            includedPaths = [
              "/*"
            ]
            excludedPaths = [
            ]
            composite = [
              {
                enable = false
                paths = [
                  {
                    enable = false
                    path   = ""
                    order  = "Ascending"
                  }
                ]
              }
            ]
            spatial = [
              {
                enable = false
                path   = ""
              }
            ]
          }
          storedProcedures = [
            {
              enable = false
              name   = "helloCosmos"
              body = <<BODY
                function () {
                  var context = getContext();
                  var response = context.getResponse();
                  response.setBody("Hello Cosmos!");
                }
              BODY
            }
          ]
          triggers = [
            {
              enable    = false
              name      = ""
              type      = "" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_trigger#type
              operation = "" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_trigger#operation
              body      = ""
            }
          ]
          functions = [
            {
              enable = false
              name   = ""
              body   = ""
            }
          ]
          timeToLive = {
            default   = null
            analytics = null
          }
          conflictResolutionPolicy = {
            mode      = "LastWriterWins"
            path      = "/_ts"
            procedure = ""
          }
        }
      ]
    }
  ]
  roles = [
    {
      enable = false
      name   = "Account Reader"
      scopePaths = [
        ""
      ]
      permissions = [
        "Microsoft.DocumentDB/databaseAccounts/readMetadata"
      ]
    }
  ]
  roleAssignments = [
    {
      enable      = true
      name        = ""
      scopePath   = ""
      principalId = "5a5ba375-541b-4c18-8e61-087decdc29cf"
      role = {
        id   = "00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
        name = ""
      }
    }
  ]
}

#####################################################################################
# Cosmos DB Mongo DB (https://learn.microsoft.com/azure/cosmos-db/mongodb/overview) #
#####################################################################################

mongoDB = {
  enable = false
  account = {
    name    = "aihpc-mongo"
    version = "7.0"
  }
  databases = [
    {
      enable     = false
      name       = "db1"
      throughput = null
      collections = [
        {
          enable     = false
          name       = ""
          shardKey   = null
          throughput = null
          indices = [
            {
              enable = true
              unique = true
              keys = [
                "_id"
              ]
            }
          ]
        }
      ]
      roles = [
        {
          enable    = false
          name      = ""
          roleNames = [
          ]
          privileges = [
            {
              enable = false
              resource = {
                databaseName   = ""
                collectionName = ""
              }
              actions = [
              ]
            }
          ]
        }
      ]
      users = [
        {
          enable    = false
          username  = ""
          password  = ""
          roleNames = [
          ]
        }
      ]
    }
  ]
}

mongoDBvCore = {
  enable = false
  cluster = {
    name    = "aihpc-mongo"
    type    = "Free"
    version = "8.0"
    dataApi = {
      enable = true
    }
    authentication = {
      methods = [
        "NativeAuth",
        # "MicrosoftEntraID"
      ]
      adminLogin = {
        userName     = ""
        userPassword = ""
      }
    }
  }
  node = {
    count = 1
    storage = {
      type   = "PremiumSSD"
      sizeGB = 32
    }
  }
  highAvailability = {
    enable = false
  }
}

################################################################################
# Cosmos DB Table (https://learn.microsoft.com/azure/cosmos-db/table/overview) #
################################################################################

table = {
  enable = false
  account = {
    name = "aihpc-table"
  }
  tables = [
    {
      enable     = false
      name       = ""
      throughput = null
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

networkSecurityPerimeter = { # https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts
  name               = "aihpc"
  profileName        = "default"
  resourceGroupName  = "HPC.Network"
  resourceAccessMode = "Enforced"
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
  subnetName        = "Data"
  resourceGroupName = "HPC.Network.CentralUS"
}
