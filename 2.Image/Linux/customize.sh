#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source /tmp/functions.sh

echo "(AAA Start): Image Build Config"
imageBuildConfig=$(echo $imageBuildConfigEncoded | base64 -d)
machineType=$(echo $imageBuildConfig | jq -r .machineType)
machineSize=$(echo $imageBuildConfig | jq -r .machineSize)
gpuProvider=$(echo $imageBuildConfig | jq -r .gpuProvider)
architecture=$(echo $imageBuildConfig | jq -r .architecture)
jobSchedulers=$(echo $imageBuildConfig | jq -c .jobSchedulers)
jobProcessors=$(echo $imageBuildConfig | jq -c .jobProcessors)
echo "(AAA End): Image Build Config"

echo "(AAA Start): Image Build Core"

echo "(AAA Start): Image Build Platform"
dnf config-manager --set-enabled crb
dnf -y install epel-release pip
dnf makecache
export AZNFS_NONINTERACTIVE_INSTALL=1 AZNFS_FORCE_PACKAGE_MANAGER=dnf
curl --silent --show-error --fail --location https://github.com/Azure/AZNFS-mount/releases/latest/download/aznfs_install.sh | bash
if [ $machineType == VDI ]; then
  echo "(AAA Start): VDI Workstation"
  dnf -y group install workstation
  echo "(AAA End): VDI Workstation"
fi
echo "(AAA End): Image Build Platform"

echo "(AAA Start): Azure CLI"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf -y install https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
dnf -y install azure-cli
echo "(AAA End): Azure CLI"

echo "(AAA End): Image Build Core"

echo "(AAA Start): Image Build Core (GPU)"

if [ "$gpuProvider" == NVIDIA ]; then
  if [ $machineType == VDI ]; then
    echo "(AAA Start): NVIDIA GPU (GRID)"
    fileType="nvidia-gpu-grid"
    fileName="NVIDIA-Linux-x86_64-570.195.03-grid-azure.run"
    fileLink="https://download.microsoft.com/download/0541e1a5-dff2-4b8c-a79c-96a7664b1d49/$fileName"
    download_file $fileName $fileLink false
    chmod +x $fileName
    dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers
    try_command "./$fileName --silent" $fileType
    echo "(AAA End): NVIDIA GPU (GRID)"
  else
    echo "(AAA Start): NVIDIA GPU (CUDA)"
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/$architecture/cuda-rhel9.repo
    dnf -y install cuda
    echo "(AAA End): NVIDIA GPU (CUDA)"
  fi
fi

echo "(AAA End): Image Build Core (GPU)"

echo "(AAA Start): Job Scheduler"

if [[ $jobSchedulers == *Slurm* ]]; then
  dnf -y install slurm

  echo "(AAA Start): Slurm Download"
  appVersion="25.11.2"
  fileName="slurm-$appVersion.tar.bz2"
  fileLink="https://download.schedmd.com/slurm/$fileName"
  download_file $fileName $fileLink false
  bzip2 -d $fileName
  fileName=$(echo ${fileName%.bz2})
  tar --extract --file=$fileName
  echo "(AAA End): Slurm Download"
fi

echo "(AAA End): Job Scheduler"

echo "(AAA Start): Job Processor"

if [[ $jobProcessors == *PBRT* ]]; then
  echo "(AAA Start): PBRT"
  appVersion="v4"
  fileType="pbrt"
  filePath="/usr/local/$fileType"
  mkdir -p $filePath
  dnf -y install mesa-libGL-devel
  dnf -y install libxkbcommon-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  dnf -y install libXi-devel
  dnf -y install wayland-devel
  fileSource=$fileType-$appVersion
  git clone --recursive https://github.com/mmp/$fileSource.git
  cmake -B $filePath -S ./$fileSource
  make -C $filePath
  aaaPath="$aaaPath:$filePath"
  echo "(AAA End): PBRT"
fi

if [[ $jobProcessors == *Blender* ]]; then
  echo "(AAA Start): Blender"
  appVersion="5.0.1"
  hostType="linux-x64"
  fileType="blender"
  filePath="/usr/local/$fileType"
  fileName="$fileType-$appVersion-$hostType.tar.xz"
  fileLink="https://mirrors.iu13.net/blender/release/Blender${appVersion:0:3}/$fileName"
  download_file $fileName $fileLink false
  tar --extract -xz --file=$fileName
  dnf -y install mesa-dri-drivers
  dnf -y install mesa-libGL
  dnf -y install libXxf86vm
  dnf -y install libXfixes
  dnf -y install libXi
  dnf -y install libSM
  mkdir -p $filePath
  mv $fileType-$appVersion-$hostType/* $filePath
  aaaPath="$aaaPath:$filePath"
  echo "(AAA End): Blender"
fi

echo "(AAA End): Job Processor"

if [ "$aaaPath" != "" ]; then
  echo "(AAA Path): ${aaaPath:1}"
  echo 'PATH=$PATH'$aaaPath >> $aaaProfile
fi
