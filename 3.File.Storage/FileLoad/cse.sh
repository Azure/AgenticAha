#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

mountPath=${fileLoadMount.path}
mkdir -p $mountPath
mount -t ${fileLoadMount.type} -o ${fileLoadMount.options} ${fileLoadMount.target} $mountPath

dataPath="$mountPath/cpu"
mkdir -p $dataPath
cd $dataPath

dataType="moana-island"

fileName="$dataType-1.tgz"
fileLink="https://wdas-datasets-disneyanimation-com.s3-us-west-2.amazonaws.com/moanaislandscene/island-basepackage-v1.1.tgz"
curl --output $fileName --location $fileLink
tar --extract --gzip --file=$fileName --overwrite &

fileName="$dataType-2.tgz"
fileLink="https://datasets.disneyanimation.com/moanaislandscene/island-pbrtV4-v2.0.tgz"
curl --output $fileName --location $fileLink
tar --extract --gzip --file=$fileName --overwrite &

fileName="splash.blend"
mountPath="$mountPath/gpu"

dataType="4.5"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.blend"
curl --output $fileName --location $fileLink
