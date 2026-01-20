#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source /tmp/functions.sh

echo "(AAA Start): Job Manager"

if [[ $jobManagers == *Slurm* ]]; then
  dnf -y install slurm

  echo "(AAA Start): Slurm Download"
  appVersion="25.11.1"
  fileName="slurm-$appVersion.tar.bz2"
  fileLink="https://download.schedmd.com/slurm/$fileName"
  download_file $fileName $fileLink false
  bzip2 -d $fileName
  fileName=$(echo ${fileName%.bz2})
  tar -xf $fileName
  echo "(AAA End): Slurm Download"
fi

if [ "$aaaPath" != "" ]; then
  echo "(AAA Path): ${aaaPath:1}"
  echo 'PATH=$PATH'$aaaPath >> $aaaProfile
fi

echo "(AAA End): Job Manager"
