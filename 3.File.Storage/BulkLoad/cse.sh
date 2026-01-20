#!/bin/bash -ex

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

dnf -y install unzip

mountPath=${bulkLoadMount.path}
mkdir -p $mountPath
mount -t ${bulkLoadMount.type} -o ${bulkLoadMount.options} ${bulkLoadMount.target} $mountPath

dataPath="$mountPath/cpu"
mkdir -p $dataPath
cd $dataPath

dataType="moana-island"

fileName="$dataType-1.tgz"
fileLink="https://wdas-datasets-disneyanimation-com.s3-us-west-2.amazonaws.com/moanaislandscene/island-basepackage-v1.1.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName --overwrite &

fileName="$dataType-2.tgz"
fileLink="https://datasets.disneyanimation.com/moanaislandscene/island-pbrtV4-v2.0.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName --overwrite &

fileName="splash.blend"
mountPath="$mountPath/gpu"

dataType="4.1"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.blend"
curl -o $fileName -L $fileLink

dataType="4.2"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

dataFile="splash.zip"
fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.zip"
curl -o $dataFile -L $fileLink
unzip -o $dataFile

dataType="4.3"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.blend"
curl -o $fileName -L $fileLink
