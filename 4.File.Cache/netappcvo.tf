# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###########################################################################################
# NetApp CVO (https://marketplace.microsoft.com/product/netapp.netapp-ontap-cloud-direct) #
###########################################################################################

variable netAppCVO {
  type = object({
    enable  = bool
    name    = string
    resourceGroup = object({
      name     = string
      location = string
    })
    machine = object({
      namePrefix = string
      size       = string
    })
    highAvailability = object({
      zone = string
    })
  })
}

resource azurerm_resource_group netapp_cvo {
  count    = var.netAppCVO.enable ? 1 : 0
  name     = var.netAppCVO.resourceGroup.name
  location = var.netAppCVO.resourceGroup.location
  tags = {
    Module = basename(path.cwd)
  }
}

resource azurerm_resource_group_template_deployment netapp_cvo {
  count               = var.netAppCVO.enable ? 1 : 0
  name                = var.netAppCVO.name
  resource_group_name = azurerm_resource_group.netapp_cvo[0].name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "location": {
      "value": "${azurerm_resource_group.netapp_cvo[0].location}"
    },
    "instanceName": {
      "value": "${var.netAppCVO.machine.namePrefix}"
    },
    "instanceType": {
      "value": "${var.netAppCVO.machine.size}"
    },
    "adminUsername": {
      "value": "${data.azurerm_key_vault_secret.admin_username.value}"
    },
    "adminPassword": {
      "value": "${data.azurerm_key_vault_secret.admin_password.value}"
    },
    "subnetId": {
      "value": "${data.azurerm_subnet.storage.id}"
    },
    "networkSecurityGroupId": {
      "value": "${data.azurerm_network_security_group.storage.id}"
    },
    "vm1Zone": {
      "value": "${var.netAppCVO.highAvailability.zone}"
    },
    "vm2Zone": {
      "value": "${var.netAppCVO.highAvailability.zone}"
    }
    "sharedHaType": {
      "value": "lrs"
    },
    "marketplaceOffer": {
      "value": "netapp-ontap-cloud"
    },
    "marketplaceSKU": {
      "value": "ontap_cloud_marketplace_direct"
    },
    "marketplaceVersion": {
      "value": "9161.02000025.03190033"
    },
    "vm1PlatformSerialNumber": {
      "value": "91220149999999999991"
    },
    "vm2PlatformSerialNumber": {
      "value": "91220149999999999992"
    },
    "vnetName": {
      "value": "${data.azurerm_virtual_network.storage.name}"
    },
    "subnetAddressPrefix": {
      "value": "${data.azurerm_subnet.storage.address_prefixes[0]}"
    }
  })
  template_content = file("netappcvo.json")
  lifecycle {
    ignore_changes = all
  }
}

output netAppCVO {
  value = var.netAppCVO.enable ? {
    clusterIp = jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).clusterMgmtIp.value
    storageIp = jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).svmIp.value
    nodeIps = [
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node1Ip.value,
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node2Ip.value
    ]
    nodeClusterIps = [
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node1ClusterIp.value,
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node2ClusterIp.value
    ]
    nodeInterclusterIps = [
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node1InterclusterIp.value,
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node2InterclusterIp.value
    ]
    nodeDataIps = [
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node1DataIp.value,
      jsondecode(azurerm_resource_group_template_deployment.netapp_cvo[0].output_content).node2DataIp.value
    ]
  } : null
}
