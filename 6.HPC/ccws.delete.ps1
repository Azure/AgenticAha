# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $resourceGroupName,
  [string] $virtualMachineName
)

$osDiskName = az vm show --resource-group $resourceGroupName --name $virtualMachineName --query storageProfile.osDisk.name --output tsv
$nicId = az vm show --resource-group $resourceGroupName --name $virtualMachineName --query networkProfile.networkInterfaces[].id --output tsv

az vm delete --resource-group $resourceGroupName --name $virtualMachineName --yes
az disk delete --resource-group $resourceGroupName --name $osDiskName --yes
az network nic delete --ids $nicId
