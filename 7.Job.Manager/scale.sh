#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

az login --identity

if [ $jobManagerName == Slurm ]; then
  :
fi
