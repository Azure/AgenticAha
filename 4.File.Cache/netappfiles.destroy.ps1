# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $cacheRequestUrl,
  [bool]   $cacheReadWrite
)

if ($cacheReadWrite) {
  az rest --method PATCH --url $cacheRequestUrl --body '{"properties":{"writeBack":"Disabled"}}'
}
az rest --method DELETE --url $cacheRequestUrl
