# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $regionName,
  [string] $resourceGroupName,
  [string] $parameterConfigfile
)

$localPath = "./cyclecloud-slurm-workspace"
if (-not (Test-Path -Path $localPath)) {
  git clone --depth 1 https://github.com/Azure/cyclecloud-slurm-workspace.git
}

$templateFile = "$localPath/bicep/mainTemplate.bicep"
az deployment sub create --name $resourceGroupName --location $regionName --template-file $templateFile --parameters $parameterConfigfile --only-show-errors
