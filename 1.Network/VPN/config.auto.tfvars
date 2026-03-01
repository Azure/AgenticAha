# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

subscriptionId = "" # REQUIRED

#############################################################################################
# VPN Gateway (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
#############################################################################################

vpnGateway = {
  name       = "Gateway"
  type       = "VpnGw2AZ" # https://learn.microsoft.com/azure/vpn-gateway/about-gateway-skus
  vpnType    = "RouteBased"
  generation = "Generation2"
  sharedKey  = ""
  bgp = {
    enable = false
  }
  pointToSite = {
    enable = false
    client = {
      addressSpace = [
        "10.30.0.0/24"
      ]
    }
  }
}

########################################################################################################################
# VPN Local Network Gateway (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#lng) #
########################################################################################################################

vpnGatewayLocal = {
  enable  = false
  fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
  address = "" # or set the device public IP address. Do NOT set both configuration parameters.
  addressSpace = [
  ]
  bgp = {
    enable         = false
    asn            = 0
    peerWeight     = 0
    peeringAddress = ""
  }
}

#########################
# Dependency References #
#########################

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}

ipAddressPrefix = { # https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-address-prefix
  name              = "aihpc"
  resourceGroupName = "SharedServices"
  activeActive = {
    enable = false
  }
}
