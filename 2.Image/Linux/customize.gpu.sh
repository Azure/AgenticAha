#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source /tmp/functions.sh

echo "(AAA Start): Core (GPU)"

if [ "$gpuProvider" != "" ]; then
  echo "(AAA Start): Linux Kernel Devel"
  dnf -y install elfutils-libelf-devel openssl-devel bison flex
  fileName="kernel-devel-6.12.0-55.9.1.el10_0.x86_64.rpm"
  fileLink="https://rpmfind.net/linux/almalinux/9/AppStream/x86_64/os/Packages/$fileName"
  download_file $fileName $fileLink false
  rpm -i $fileName
  echo "(AAA End): Linux Kernel Devel"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  if [ $machineType == VDI ]; then
    echo "(AAA Start): NVIDIA GPU (GRID)"
    fileType="nvidia-gpu-grid"
    fileName="$fileType.run"
    fileLink="https://go.microsoft.com/fwlink/?linkid=874272"
    download_file $fileName $fileLink false
    chmod +x $fileName
    dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers
    run_process "./$fileName --silent" $fileType
    echo "(AAA End): NVIDIA GPU (GRID)"
  elif [ $machineType == JobCluster ]; then
    echo "(AAA Start): NVIDIA GPU (CUDA)"
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
    dnf -y install cuda
    echo "(AAA End): NVIDIA GPU (CUDA)"
  fi
fi

if [ "$gpuProvider" == AMD ]; then
  if [ $machineType == VDI ]; then
    echo "(AAA Start): AMD GPU (Radeon)"
    echo "(AAA End): AMD GPU (Radeon)"
  elif [ $machineType == JobCluster ]; then
    echo "(AAA Start): AMD GPU (Instinct)"
    echo "(AAA End): AMD GPU (Instinct)"
  fi
fi

if [ "$aaaPath" != "" ]; then
  echo "(AAA Path): ${aaaPath:1}"
  echo 'PATH=$PATH'$aaaPath >> $aaaProfile
fi

echo "(AAA End): Core (GPU)"
