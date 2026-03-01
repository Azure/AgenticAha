# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

. C:\AzureData\functions.ps1

SetFileSystem (ConvertFrom-Json -InputObject '${jsonencode(fileSystem)}')

JoinActiveDirectory -activeDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
