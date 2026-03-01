# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

variable computeGallery {
  type = object({
    name = string
    imageDefinitions = list(object({
      name         = string
      type         = string
      architecture = string
      generation   = string
      publisher    = string
      offer        = string
      sku          = string
      confidentialMachine = object({
        enable = bool
      })
    }))
  })
}

locals {
  imageDefinitionLinux = [
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition if lower(imageDefinition.type) == "linux"
  ][0]
}

resource azurerm_shared_image_gallery main {
  name                = var.computeGallery.name
  resource_group_name = azurerm_resource_group.image_gallery.name
  location            = azurerm_resource_group.image_gallery.location
}

resource azurerm_shared_image main {
  for_each = {
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition.name => imageDefinition if (lower(imageDefinition.type) == "linux") || (var.image.windows.enable && lower(imageDefinition.type) == "windows")
  }
  name                                = each.value.name
  resource_group_name                 = azurerm_resource_group.image_gallery.name
  location                            = azurerm_resource_group.image_gallery.location
  gallery_name                        = azurerm_shared_image_gallery.main.name
  architecture                        = each.value.architecture
  hyper_v_generation                  = each.value.generation
  os_type                             = each.value.type
  confidential_vm_enabled             = each.value.confidentialMachine.enable ? true : null
  trusted_launch_supported            = !each.value.confidentialMachine.enable ? true : null
  disk_controller_type_nvme_enabled   = true
  accelerated_network_support_enabled = true
  hibernation_enabled                 = true
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
}

output linux {
  value = {
    publisher = lower(local.imageDefinitionLinux.publisher)
    offer     = lower(local.imageDefinitionLinux.offer)
    sku       = lower(local.imageDefinitionLinux.sku)
    version   = lower(var.image.linux.version)
  }
}
