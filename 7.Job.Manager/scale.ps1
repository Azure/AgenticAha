# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $resourceGroupName,
  [string] $jobManagerName,
  [string] $jobClusterName,
  [int] $jobClusterNodeLimit,
  [int] $jobWaitThresholdSeconds,
  [int] $workerIdleDeleteSeconds
)

az login --identity

if ($jobManagerName -eq "Slurm") {

}
