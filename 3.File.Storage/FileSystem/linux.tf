# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable fileSystemLinux {
  default = [
    { # File Storage (NFS v3)
      enable = false
      mount = {
        type    = "nfs"
        path    = "/mnt/storage"
        target  = "storage-netapp.azure.hpc:/data"
        options = "rw,nconnect=8,vers=3"
      }
    },
    { # File Cache (NFS v4.x)
      enable = false
      mount = {
        type    = "nfs"
        path    = "/mnt/cache"
        target  = "cache.azure.hpc:/storage"
        options = "rw,nconnect=8"
      }
    },
    { # File Cache (Lustre)
      enable = false
      mount = {
        type    = "lustre"
        path    = "/mnt/cache"
        target  = "cache.azure.hpc@tcp:/lustrefs"
        options = "noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=network.service"
      }
    }
  ]
}

output linux {
  value = var.fileSystemLinux
}
