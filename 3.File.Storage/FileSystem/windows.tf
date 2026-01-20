# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable fileSystemWindows {
  default = [
    { # File Storage
      enable = false
      mount = {
        type    = ""
        path    = "X:"
        target  = "\\\\storage-netapp.azure.hpc\\data"
        options = "-o anon -o nconnnect=8 -o vers=3"
      }
    },
    { # File Cache
      enable = false
      mount = {
        type    = ""
        path    = "Y:"
        target  = "\\\\cache.azure.hpc\\storage"
        options = "-o anon -o nconnnect=8"
      }
    }
  ]
}

output windows {
  value = var.fileSystemWindows
}
