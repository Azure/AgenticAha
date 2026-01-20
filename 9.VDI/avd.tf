# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################
# Virtual Desktop (https://learn.microsoft.com/azure/virtual-desktop/overview) #
################################################################################

variable virtualDesktop {
  type = object({
    enable = bool
  })
}
