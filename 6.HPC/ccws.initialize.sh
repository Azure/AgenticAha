#!/bin/bash -x

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function try_command {
  local -r command="$1"
  local -r message="$2"
  attempt=1
  while true; do
    $command
    exitCode=$?
    if [ $exitCode -eq 0 ]; then
      echo "SUCCESS: $message"
      break
    elif [ $attempt -ge ${commandMaxAttempts} ]; then
      echo "ERROR (Timeout): $message"
      exit $exitCode
    else
      echo "ERROR (Exit Code $exitCode): $message (Attempt $attempt of ${commandMaxAttempts})"
    fi
    sleep ${commandWaitSeconds}
    ((attempt++))
  done
}

rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf -y install https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
dnf -y install azure-cli
dnf -y install azcopy

az login --identity --resource-id ${userIdentityResourceId}
az vm identity assign --resource-group ${ccResourceGroupName} --name ${ccServerMachineName} --identities ${userIdentityResourceId}

cd /tmp
ccCli="cyclecloud-cli.zip"
try_command "curl --insecure --fail --output $ccCli https://${ccServerMachineName}/static/tools/$ccCli" "CycleCloud Download CLI"
unzip $ccCli
export PATH="/root/bin:$PATH"
cd cyclecloud-cli-installer
sed -i 's/fetch_azcopy(get/#fetch_azcopy(get/' install.py
./install.sh

cyclecloud --version

message="CycleCloud Initialize CLI"
if [ "${entraIdAppClientId}" != "" ]; then
  ccConfigFile="/tmp/user_assigned_managed_identity.txt"
  echo 'Authentication = "internal"' > $ccConfigFile
  echo 'EntraTID = "${userIdentityTenantId}"' >> $ccConfigFile
  echo 'UID = 19001' >> $ccConfigFile
  echo 'EntraOID = "${userIdentityObjectId}"' >> $ccConfigFile
  echo 'Superuser = true' >> $ccConfigFile
  echo 'NodeAccessDisabled = true' >> $ccConfigFile
  echo 'AdType = "AuthenticatedUser"' >> $ccConfigFile
  echo 'Roles = {"Administrator","User","Cluster Creator"}' >> $ccConfigFile
  echo 'NodeUserName = "cc-vm-uami"' >> $ccConfigFile
  echo 'ServiceAccount = true' >> $ccConfigFile
  echo 'Name = "cc-vm-uami"' >> $ccConfigFile
  echo 'ForcePasswordReset = false' >> $ccConfigFile
  sshKeyFile="/tmp/id_rsa"
  echo "${secretSshKeyPrivate}" > $sshKeyFile
  chmod 600 $sshKeyFile
  scp -i $sshKeyFile -o StrictHostKeyChecking=accept-new -B $ccConfigFile ${secretAdminUsername}@${ccPrivateIpAddress}:/tmp
  ssh -i $sshKeyFile ${secretAdminUsername}@${ccPrivateIpAddress} sudo mv $ccConfigFile /opt/cycle_server/config/data/
  try_command "cyclecloud initialize --url=https://${ccPrivateIpAddress} --verify-ssl=false --batch --identity --resource_id=${userIdentityResourceId}" "$message"
else
  try_command "cyclecloud initialize --url=https://${ccPrivateIpAddress} --verify-ssl=false --batch --username=${secretAdminUsername} --password=${secretAdminPassword}" "$message"
fi

az vm run-command invoke --command-id RunShellScript --resource-group ${ccResourceGroupName} --name ${ccServerMachineName} --scripts "echo -e '\n\neventgrid.topic=${ccEventGridTopicId}\n' >> /opt/cycle_server/config/cycle_server.properties"
az vm run-command invoke --command-id RunShellScript --resource-group ${ccResourceGroupName} --name ${ccServerMachineName} --scripts "systemctl restart cycle_server"
