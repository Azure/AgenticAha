# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

aaaPath=""
aaaRoot="/usr/local/aaa"
mkdir -p $aaaRoot
cd $aaaRoot

aaaProfile="/etc/profile.d/aaa.sh"
touch $aaaProfile

function download_file {
  local -r fileName=$1
  local -r fileLink=$2
  local -r authRequired=$3
  if [ $authRequired == true ]; then
    local -r apiVersion=$(echo $blobStorage | jq -r .apiVersion)
    local -r authTokenUrl=$(echo $blobStorage | jq -r .authTokenUrl)
    accessToken=$(curl -H "Metadata: true" $authTokenUrl | jq -r .access_token)
    curl --header "Authorization: Bearer $accessToken" --header "x-ms-version: $apiVersion" --output $fileName --location $fileLink
  else
    curl --output $fileName --location $fileLink
  fi
}

function try_command {
  local -r command="$1"
  local -r logFile=$2
  local exitStatus=-1
  local retryCount=0
  logFile="$aaaRoot/$logFile"
  while [[ $exitStatus -ne 0 && $retryCount -lt 3 ]]; do
    $command 1> $logFile.out 2> $logFile.err
    exitStatus=$?
    ((retryCount++))
    if [ $exitStatus ]; then
      cat $logFile.out
      cat $logFile.err
      sleep 10s
    fi
  done
}

function get_encoded_value {
  echo $1 | base64 -d | jq -r $2
}

function set_file_system {
  local -r fileSystemConfig="$1"
  for fileSystem in $(echo $fileSystemConfig | jq -r '.[] | @base64'); do
    if [ $(get_encoded_value $fileSystem .enable) == true ]; then
      set_file_system_mount "$(get_encoded_value $fileSystem .mount)"
    fi
  done
  systemctl daemon-reload
  mount -a
}

function set_file_system_mount {
  local -r fileSystemMount="$1"
  local -r mountType=$(echo $fileSystemMount | jq -r .type)
  local -r mountPath=$(echo $fileSystemMount | jq -r .path)
  local -r mountTarget=$(echo $fileSystemMount | jq -r .target)
  local -r mountOptions=$(echo $fileSystemMount | jq -r .options)
  if ! grep -q $mountPath /etc/fstab; then
    mkdir -p $mountPath
    echo "$mountTarget $mountPath $mountType $mountOptions 0 2" >> /etc/fstab
  fi
}
