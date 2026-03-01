######################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview) #
######################################################################

resource azurerm_eventgrid_topic ccws {
  for_each = {
    for ccwsCluster in local.ccwsClusters : ccwsCluster.resourceGroup.value => ccwsCluster
  }
  name                = var.ccWorkspace.cycleCloud.name
  resource_group_name = each.value.resourceGroup.value
  location            = each.value.location.value
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  depends_on = [
    azurerm_resource_group.cyclecloud
  ]
}
