#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source /tmp/functions.sh

echo "(AAA Start): Core"

echo "(AAA Start): Image Build Platform"
dnf config-manager --set-enabled crb
dnf -y install epel-release
dnf makecache
export AZNFS_NONINTERACTIVE_INSTALL=1 AZNFS_FORCE_PACKAGE_MANAGER=dnf
curl -fsSL https://github.com/Azure/AZNFS-mount/releases/latest/download/aznfs_install.sh | bash
if [ $machineType == VDI ]; then
  echo "(AAA Start): VDI Workstation"
  dnf -y group install workstation
  echo "(AAA End): VDI Workstation"
fi
echo "(AAA End): Image Build Platform"

if [ $machineType == JobManager ]; then
  echo "(AAA Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "(AAA End): Azure CLI"
fi

if [[ $machineType == VDI && $hpAnywareAuthId != "" ]]; then
  echo "(AAA Start): HP Anyware (Teradici)"
  curl -fsSL https://dl.anyware.hp.com/$hpAnywareAuthId/pcoip-agent/cfg/setup/bash.rpm.sh | distro=el codename=9 bash
  echo "(AAA End): HP Anyware (Teradici)"
fi

if [ "$aaaPath" != "" ]; then
  echo "(AAA Path): ${aaaPath:1}"
  echo 'PATH=$PATH'$aaaPath >> $aaaProfile
fi

echo "(AAA End): Core"
