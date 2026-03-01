# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $cacheRequestUrl,
  [string] $cacheRequestBody
)

az rest --method PUT --url $cacheRequestUrl --body $cacheRequestBody.Replace('"','\"')
do {
  Start-Sleep -Seconds 10
  $cacheProperties = az rest --method GET --url $cacheRequestUrl --query properties | ConvertFrom-Json
} while ($cacheProperties.provisioningState -eq "Creating" -and $cacheProperties.cacheState -ne "ClusterPeeringOfferSent")

az rest --method POST --url $cacheRequestUrl.Replace('?','/listPeeringPassphrases?')
