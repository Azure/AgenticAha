# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Network"

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

hubVirtualNetworks = [
  {
    enable    = true
    name      = "HPC"
    vwHubName = "US"
    groupName = "USSouthCentral"
    location  = "SouthCentralUS"
    addressSpace = [
      "10.0.0.0/16"
    ]
    dnsAddresses = [
    ]
    subnets = [
      {
        name = "Cluster"
        addressSpace = [
          "10.0.0.0/17"
        ]
        serviceEndpoints = [
          "Microsoft.Storage"
        ]
        serviceDelegation = null
      },
      {
        name = "VDI"
        addressSpace = [
          "10.0.128.0/18"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AD"
        addressSpace = [
          "10.0.192.0/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "DNSIn"
        addressSpace = [
          "10.0.192.128/26"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.Network/dnsResolvers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "DNSOut"
        addressSpace = [
          "10.0.192.192/26"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.Network/dnsResolvers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "Storage"
        addressSpace = [
          "10.0.193.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.Storage"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageANF"
        addressSpace = [
          "10.0.194.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.Netapp/volumes"
          actions = [
            "Microsoft.Network/networkinterfaces/*",
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "Data"
        addressSpace = [
          "10.0.195.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "DataMySQL"
        addressSpace = [
          "10.0.196.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.DBforMySQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "Cache"
        addressSpace = [
          "10.0.197.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "CycleCloud"
        addressSpace = [
          "10.0.198.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AKS"
        addressSpace = [
          "10.0.199.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AppGateway"
        addressSpace = [
          "10.0.200.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.Network/applicationGateways"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "APIManagement"
        addressSpace = [
          "10.0.201.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.ApiManagement/service"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
          ]
        }
      },
      {
        name = "AICore"
        addressSpace = [
          "10.0.202.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AIAgent"
        addressSpace = [
          "10.0.203.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.App/environments"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "GatewaySubnet"
        addressSpace = [
          "10.0.254.0/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureBastionSubnet"
        addressSpace = [
          "10.0.254.128/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureFirewallSubnet"
        addressSpace = [
          "10.0.255.0/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureFirewallManagementSubnet"
        addressSpace = [
          "10.0.255.128/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      }
    ]
  }
]

spokeVirtualNetworks = [
  {
    enable    = true
    vwHubName = ""
    groupName = "USWest"
    location  = "WestUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.1"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
    routeTable = {
      enable = true
      routes = [
        {
          enable         = true
          name           = "Firewall"
          addressPrefix  = "0.0.0.0/0"
          nextHopType    = "VirtualAppliance"
          nextHopAddress = "10.0.255.4"
        }
      ]
    }
  },
  {
    enable    = true
    vwHubName = ""
    groupName = "USWest"
    location  = "WestUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.2"
    }
    extendedZone = {
      enable   = true
      name     = "LosAngeles"
      location = "WestUS"
    }
    routeTable = {
      enable = true
      routes = [
        {
          enable         = true
          name           = "Firewall"
          addressPrefix  = "0.0.0.0/0"
          nextHopType    = "VirtualAppliance"
          nextHopAddress = "10.0.255.4"
        }
      ]
    }
  },
  {
    enable    = true
    vwHubName = ""
    groupName = "USCentral"
    location  = "CentralUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.3"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
    routeTable = {
      enable = true
      routes = [
        {
          enable         = true
          name           = "Firewall"
          addressPrefix  = "0.0.0.0/0"
          nextHopType    = "VirtualAppliance"
          nextHopAddress = "10.0.255.4"
        }
      ]
    }
  },
  {
    enable    = true
    vwHubName = ""
    groupName = "USEast"
    location  = "EastUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.4"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
    routeTable = {
      enable = true
      routes = [
        {
          enable         = true
          name           = "Firewall"
          addressPrefix  = "0.0.0.0/0"
          nextHopType    = "VirtualAppliance"
          nextHopAddress = "10.0.255.4"
        }
      ]
    }
  },
  {
    enable    = true
    vwHubName = ""
    groupName = "USEast"
    location  = "EastUS2"
    addressSpace = {
      search  = "10.0"
      replace = "10.5"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
    routeTable = {
      enable = true
      routes = [
        {
          enable         = true
          name           = "Firewall"
          addressPrefix  = "0.0.0.0/0"
          nextHopType    = "VirtualAppliance"
          nextHopAddress = "10.0.255.4"
        }
      ]
    }
  }
]

#################################################################################
# Virtual WAN (https://learn.microsoft.com/azure/virtual-wan/virtual-wan-about) #
#################################################################################

virtualWAN = {
  enable = true
  name   = "aihpc"
  type   = "Standard"
  hubs = [
    {
      enable       = true
      name         = "US"
      type         = "Standard"
      location     = "SouthCentralUS"
      addressSpace = "10.10.0.0/24"
      router = {
        preferenceMode = "ExpressRoute"
        scaleUnit = {
          minCount = 2
        }
        routes = [
          {
            enable = false
            name   = ""
            addressSpace = [
            ]
            nextHopAddress = ""
          }
        ]
        branchToBranch = {
          enable = true
        }
      }
    }
  ]
  branchToBranch = {
    enable = true
  }
  vpnGateway = { # Virtual WAN VPN Gateway (https://learn.microsoft.com/azure/virtual-wan/connect-virtual-network-gateway-vwan)
    enable = true
    name   = "aihpc"
    connections = [
      {
        enable     = true
        name       = "vpn"
        vwHubName  = "US"
        scaleUnits = 1
        siteToSite = {
          enable = false
          addressSpace = [
            "10.20.0.0/24"
          ]
          link = {
            enable  = false
            fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
            address = "" # or set the device public IP address. Do NOT set both configuration parameters.
          }
          bgp = {
            enable = false
            asn    = 0
            peering = {
              address = ""
            }
          }
        }
        pointToSite = {
          enable = true
          client = {
            addressSpace = [
              "10.30.0.0/24"
            ]
          }
        }
      }
    ]
  }
}

################################################################################################
# Virtual Network Manager (https://learn.microsoft.com/azure/virtual-network-manager/overview) #
################################################################################################

virtualNetworkManager = {
  enable = true
  name   = "aihpc"
  features = [
    "Connectivity",
    "SecurityAdmin",
    "Routing"
  ]
  groups = [
    {
      enable      = true
      name        = "USSouthCentral"
      description = ""
    },
    {
      enable      = true
      name        = "USWest"
      description = ""
    },
    {
      enable      = true
      name        = "USCentral"
      description = ""
    },
    {
      enable      = true
      name        = "USEast"
      description = ""
    }
  ]
}

##############################################################################################
# Private DNS          (https://learn.microsoft.com/azure/dns/private-dns-overview)          #
# Private DNS Resolver (https://learn.microsoft.com/azure/dns/dns-private-resolver-overview) #
##############################################################################################

privateDNS = {
  zone = {
    name = "azure.hpc"
    autoRegistration = {
      enable = true
    }
  }
  resolver = {
    enable = true
    name   = "aihpc"
    inbound = {
      enable = true
      name   = "aihpc-in"
      subnet = {
        name = "DNSIn"
      }
    }
    outbound = {
      enable = false
      name   = "aihpc-out"
      subnet = {
        name = "DNSOut"
      }
    }
  }
}

##################################################################
# Firewall (https://learn.microsoft.com/azure/firewall/overview) #
##################################################################

firewall = {
  enable = true
  name   = "aihpc"
  tier   = "Standard"
  virtualWAN = {
    enable = false
  }
}

########################################################################
# Bastion (https://learn.microsoft.com/azure/bastion/bastion-overview) #
########################################################################

bastion = {
  enable              = true
  type                = "Standard"
  scaleUnits          = 2
  enableFileCopy      = true
  enableCopyPaste     = true
  enableIpConnect     = true
  enableTunneling     = true
  enableShareableLink = false
  enableSessionRecord = false
}

##########################################################################################################################
# Network Address Translation (NAT) Gateway (https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) #
##########################################################################################################################

natGateway = {
  enable = true
  name   = "Gateway"
  tier   = "Standard"
  ipAddress = {
    tier = "Standard"
    type = "Regional"
  }
}

################################################################################################################
# Virtual Network Peering (https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview) #
################################################################################################################

networkPeering = {
  enable                      = true
  allowRemoteNetworkAccess    = true
  allowRemoteForwardedTraffic = true
  allowGatewayTransit         = true
}

###################################################################################################################
# Network Security Perimeter (https://learn.microsoft.com/azure/private-link/network-security-perimeter-concepts) #
###################################################################################################################

networkSecurityPerimeter = {
  name        = "aihpc"
  profileName = "default"
  accessMode = {
    keyVault       = "Enforced"
    storageAccount = "Enforced"
    logAnalytics   = "Enforced"
    appInsights    = "Enforced"
  }
  diagnosticSetting = {
    enable = false
    name   = "Network Security Perimeter"
    log = {
      category = "AllLogs"
    }
  }
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
}

storageAccount = { # https://learn.microsoft.com/azure/storage/common/storage-account-overview
  name              = "aihpc0"
  resourceGroupName = "HPC"
}

monitor = { # https://learn.microsoft.com/azure/azure-monitor/monitor-overview
  workspace = {
    name              = "aihpc"
    resourceGroupName = "HPC.Monitor"
    logAnalytics = {
      name              = "aihpc"
      resourceGroupName = "HPC.Monitor"
    }
  }
  appInsights = {
    name              = "aihpc"
    resourceGroupName = "HPC.Monitor"
  }
  grafanaDashboard = {
    name              = "aihpc"
    resourceGroupName = "HPC.Monitor"
  }
}
