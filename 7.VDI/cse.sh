#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source /tmp/functions.sh

set_file_system '${jsonencode(fileSystem)}'

source /etc/profile.d/aaa.sh
