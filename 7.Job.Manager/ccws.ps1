# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $regionName,
  [string] $deploymentName
)

git clone --depth 1 https://github.com/Azure/cyclecloud-slurm-workspace.git

# az vm image terms accept --urn AzureCycleCloud:Azure-CycleCloud:CycleCloud8-Gen2:Latest

$templateFile  = "./cyclecloud-slurm-workspace/bicep/mainTemplate.bicep"
$parameterFile = "ccws.json"
az deployment sub create --name $deploymentName --location $regionName --template-file $templateFile --parameters $parameterFile
