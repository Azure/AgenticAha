# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###############################################################################################
# CycleCloud Workspace for Slurm (https://learn.microsoft.com/azure/cyclecloud/overview-ccws) #
###############################################################################################

data azurerm_virtual_machine ccws {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  name                = each.value.ccVMName.value
  resource_group_name = each.value.resourceGroup.value
  depends_on = [
    terraform_data.ccws
  ]
}

resource azurerm_network_interface ccws_init {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  name                = "${each.value.ccVMName.value}-init"
  resource_group_name = each.value.resourceGroup.value
  location            = each.value.location.value
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${each.value.network.value.id}/subnets/${each.value.network.value.cyclecloudSubnet}"
  }
  accelerated_networking_enabled = true
  depends_on = [
    terraform_data.ccws
  ]
}

resource azurerm_linux_virtual_machine ccws_init {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  name                            = "${each.value.ccVMName.value}-init"
  resource_group_name             = each.value.resourceGroup.value
  location                        = each.value.location.value
  size                            = var.ccWorkspace.initMachine.size
  admin_username                  = local.initMachine.adminLogin.userName
  admin_password                  = local.initMachine.adminLogin.userPassword
  disable_password_authentication = local.initMachine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.ccws_init[each.value.resourceGroup.value].id
  ]
  os_disk {
    storage_account_type = var.ccWorkspace.initMachine.osDisk.storageType
    caching              = var.ccWorkspace.initMachine.osDisk.cachingMode
    disk_size_gb         = var.ccWorkspace.initMachine.osDisk.sizeGB > 0 ? var.ccWorkspace.initMachine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = var.ccWorkspace.initMachine.image.publisher
    offer     = var.ccWorkspace.initMachine.image.product
    sku       = var.ccWorkspace.initMachine.image.name
    version   = var.ccWorkspace.initMachine.image.version
  }
  plan {
    publisher = lower(var.ccWorkspace.initMachine.image.publisher)
    product   = lower(var.ccWorkspace.initMachine.image.product)
    name      = lower(var.ccWorkspace.initMachine.image.name)
  }
  dynamic admin_ssh_key {
    for_each = local.initMachine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.initMachine.adminLogin.userName
      public_key = local.initMachine.adminLogin.sshKeyPublic
    }
  }
}

resource azurerm_virtual_machine_extension ccws_init {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  name                       = "${each.value.ccVMName.value}-init"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.ccws_init[each.value.resourceGroup.value].id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("ccws.initialize.sh", {
        entraIdAppClientId     = var.ccWorkspace.entraId.enable ? var.ccWorkspace.entraId.app.clientId : ""
        ccEventGridTopicId     = azurerm_eventgrid_topic.ccws[each.value.resourceGroup.value].id
        ccPrivateIpAddress     = data.azurerm_virtual_machine.ccws[each.value.resourceGroup.value].private_ip_address
        ccResourceGroupName    = data.azurerm_virtual_machine.ccws[each.value.resourceGroup.value].resource_group_name
        ccServerMachineName    = data.azurerm_virtual_machine.ccws[each.value.resourceGroup.value].name
        userIdentityTenantId   = data.azurerm_user_assigned_identity.main.tenant_id
        userIdentityObjectId   = data.azurerm_user_assigned_identity.main.principal_id
        userIdentityResourceId = data.azurerm_user_assigned_identity.main.id
        secretAdminUsername    = data.azurerm_key_vault_secret.admin_username.value
        secretAdminPassword    = data.azurerm_key_vault_secret.admin_password.value
        secretSshKeyPrivate    = data.azurerm_key_vault_secret.ssh_key_private.value
        commandWaitSeconds     = 30
        commandMaxAttempts     = 10
      })
    )
  })
}

resource terraform_data ccws_init {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster if var.ccWorkspace.initMachine.autoDelete.enable
  }
  provisioner local-exec {
    interpreter = ["pwsh","-NoProfile","-NonInteractive","-Command"]
    command = <<-PWSH
      & "${path.module}/ccws.delete.ps1" -resourceGroupName ${each.value.resourceGroup.value} -virtualMachineName ${azurerm_linux_virtual_machine.ccws_init[each.value.resourceGroup.value].name}
    PWSH
  }
  depends_on = [
    azurerm_virtual_machine_extension.ccws_init
  ]
}
