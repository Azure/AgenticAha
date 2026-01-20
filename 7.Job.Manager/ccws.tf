# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###############################################################################################
# CycleCloud Workspace for Slurm (https://learn.microsoft.com/azure/cyclecloud/overview-ccws) #
###############################################################################################

variable ccws {
  type = object({
    enable            = bool
    deploymentName    = string
    resourceGroupName = string
  })
}

resource terraform_data ccws {
  count = var.ccws.enable ? 1 : 0
  provisioner local-exec {
    command = "pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ccws.ps1 -regionName ${azurerm_resource_group.ccws[0].location} -deploymentName \"${var.ccws.deploymentName}\""
  }
}
