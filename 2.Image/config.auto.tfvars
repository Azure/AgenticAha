# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resourceGroupName = "HPC.Image"

image = {
  linux = {
    x64 = {
      publisher = "AlmaLinux"
      offer     = "AlmaLinux-HPC"
      sku       = "9-HPC-Gen2"
    }
    arm = {
      publisher = "AlmaLinux"
      offer     = "AlmaLinux-ARM"
      sku       = "9-ARM-Gen2"
    }
    version = "Latest"
  }
  windows = {
    enable  = true
    version = "Latest"
  }
}

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "aihpc"
  imageDefinitions = [
    {
      name         = "x64Lnx"
      type         = "Linux"
      architecture = "x64"
      generation   = "V2"
      publisher    = "AlmaLinux"
      offer        = "AlmaLinux-HPC"
      sku          = "9-HPC-Gen2"
      confidentialMachine = {
        enable = false
      }
    },
    {
      name         = "a64Lnx"
      type         = "Linux"
      architecture = "Arm64"
      generation   = "V2"
      publisher    = "AlmaLinux"
      offer        = "AlmaLinux-ARM"
      sku          = "9-ARM-Gen2"
      confidentialMachine = {
        enable = false
      }
    },
    {
      name         = "x64WinServer"
      type         = "Windows"
      architecture = "x64"
      generation   = "V2"
      publisher    = "MicrosoftWindowsServer"
      offer        = "WindowsServer"
      sku          = "2025-Datacenter"
      confidentialMachine = {
        enable = false
      }
    },
    {
      name         = "x64WinClient"
      type         = "Windows"
      architecture = "x64"
      generation   = "V2"
      publisher    = "MicrosoftWindowsDesktop"
      offer        = "Windows-11"
      sku          = "Win11-25H2-Pro"
      confidentialMachine = {
        enable = false
      }
    },
    {
      name         = "a64WinClient"
      type         = "Windows"
      architecture = "Arm64"
      generation   = "V2"
      publisher    = "MicrosoftWindowsDesktop"
      offer        = "Windows11Preview-ARM64"
      sku          = "Win11-25H2-Pro"
      confidentialMachine = {
        enable = false
      }
    }
  ]
}

#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

imageBuilder = {
  enable = false
  templates = [
    {
      enable = true
      name   = "JobSchedulerXL"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "Scheduler"
        machineSize  = "Standard_D4as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = ""                 # NVIDIA or AMD
        architecture = "x86_64"           # x86_64 or aarch64
        imageVersion = "1.0.0"
        osDiskSizeGB = 1024
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "VDIUserLoginXL"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "VDI"
        machineSize  = "Standard_D4as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = ""                 # NVIDIA or AMD
        architecture = "x86_64"           # x86_64 or aarch64
        imageVersion = "1.1.0"
        osDiskSizeGB = 1024
        jobSchedulers = [
        ]
        jobProcessors = [
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "JobClusterXLCA"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "JobCluster"
        machineSize  = "Standard_HX176rs" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = ""                 # NVIDIA or AMD
        architecture = "x86_64"           # x86_64 or aarch64
        imageVersion = "2.0.0"
        osDiskSizeGB = 480
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT"
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "JobClusterXLCI"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "JobCluster"
        machineSize  = "Standard_FX96ms_v2" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = ""                   # NVIDIA or AMD
        architecture = "x86_64"             # x86_64 or aarch64
        imageVersion = "2.1.0"
        osDiskSizeGB = 480
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT"
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "JobClusterXLGN"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "JobCluster"
        machineSize  = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = "NVIDIA"                   # NVIDIA or AMD
        architecture = "x86_64"                   # x86_64 or aarch64
        imageVersion = "2.2.0"
        osDiskSizeGB = 320
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "JobClusterXLGA"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "JobCluster"
        machineSize  = "Standard_ND96isr_MI300X_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = "AMD"                        # NVIDIA or AMD
        architecture = "x86_64"                     # x86_64 or aarch64
        imageVersion = "2.3.0"
        osDiskSizeGB = 1000
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "VDIUserXLGN"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "VDI"
        machineSize  = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = "NVIDIA"                  # NVIDIA or AMD
        architecture = "x86_64"                  # x86_64 or aarch64
        imageVersion = "3.0.0"
        osDiskSizeGB = 1024
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "VDIUserXLGA"
      source = {
        imageDefinition = {
          name = "x64Lnx"
        }
      }
      build = {
        machineType  = "VDI"
        machineSize  = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = "AMD"                       # NVIDIA or AMD
        architecture = "x86_64"                    # x86_64 or aarch64
        imageVersion = "3.1.0"
        osDiskSizeGB = 1024
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
        timeoutMinutes = 180
      }
    },
    {
      enable = true
      name   = "VDIUserXWGN"
      source = {
        imageDefinition = {
          name = "x64WinClient"
        }
      }
      build = {
        machineType  = "VDI"
        machineSize  = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = "NVIDIA"                  # NVIDIA or AMD
        architecture = "x86_64"                  # x86_64 or aarch64
        imageVersion = "3.0.0"
        osDiskSizeGB = 1024
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
        timeoutMinutes = 360
      }
    },
    {
      enable = true
      name   = "VDIUserXWGA"
      source = {
        imageDefinition = {
          name = "x64WinClient"
        }
      }
      build = {
        machineType  = "VDI"
        machineSize  = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider  = "AMD"                       # NVIDIA or AMD
        architecture = "x86_64"                    # x86_64 or aarch64
        imageVersion = "3.1.0"
        osDiskSizeGB = 1024
        jobSchedulers = [
          "Slurm"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
        timeoutMinutes = 360
      }
    }
  ]
  distribute = {
    replicaCount = 1
    replicaRegions = [
      # "WestUS"
    ]
    storageAccount = {
      type = "Premium_LRS"
    }
  }
  errorHandling = {
    validationMode    = "cleanup"
    customizationMode = "cleanup"
  }
}

#########################
# Dependency References #
#########################

managedIdentity = { # https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview
  name              = "aihpc"
  resourceGroupName = "HPC.Identity"
}

keyVault = { # https://learn.microsoft.com/azure/key-vault/general/overview
  name              = "aihpc"
  resourceGroupName = "HPC"
  secretName = {
    adminUsername = "adminUsername"
    adminPassword = "adminPassword"
  }
}

virtualNetwork = { # https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
  name              = "HPC"
  subnetName        = "Cluster"
  resourceGroupName = "HPC.Network.SouthCentralUS"
}
