# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param (
  [string] $imageBuildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Information "(AAA Start): Image Build Config"
$imageBuildConfigBytes = [System.Convert]::FromBase64String($imageBuildConfigEncoded)
$imageBuildConfig = [System.Text.Encoding]::UTF8.GetString($imageBuildConfigBytes) | ConvertFrom-Json
$machineType = $imageBuildConfig.machineType
$machineSize = $imageBuildConfig.machineSize
$gpuProvider = $imageBuildConfig.gpuProvider
$architecture = $imageBuildConfig.architecture
$jobSchedulers = $imageBuildConfig.jobSchedulers
$jobProcessors = $imageBuildConfig.jobProcessors
Write-Information "(AAA End): Image Build Config"

Write-Information "(AAA Start): Image Build Core"

Write-Information "(AAA Start): Resize Root Partition"
$osDriveLetter = "C"
$partitionSizeActive = (Get-Partition -DriveLetter $osDriveLetter).Size
$partitionSizeRange = Get-PartitionSupportedSize -DriveLetter $osDriveLetter
if ($partitionSizeActive -lt $partitionSizeRange.SizeMax) {
  Resize-Partition -DriveLetter $osDriveLetter -Size $partitionSizeRange.SizeMax
}
Write-Information "(AAA End): Resize Root Partition"

Write-Information "(AAA Start): Image Build Platform"

Write-Information "(AAA Start): Chocolatey"
$fileType = "chocolatey"
$fileName = "$fileType.ps1"
$fileLink = "https://community.chocolatey.org/install.ps1"
DownloadFile $fileName $fileLink $false
TryCommand "pwsh" "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\$fileName" $fileType
$aaaPathChoco = "C:\ProgramData\chocolatey"
$aaaPath += ";$aaaPathChoco"
Write-Information "(AAA End): Chocolatey"

Write-Information "(AAA Start): Python"
$fileType = "python"
TryCommand "$aaaPathChoco\choco.exe" "install $fileType --confirm --no-progress" $fileType
Write-Information "(AAA End): Python"

Write-Information "(AAA Start): Git"
$fileType = "git"
TryCommand "$aaaPathChoco\choco.exe" "install $fileType --confirm --no-progress" $fileType
$aaaPathGit = "C:\Program Files\Git\bin"
$aaaPath += ";$aaaPathGit"
$Env:GIT_BIN_PATH = $aaaPathGit
Write-Information "(AAA End): Git"

Write-Information "(AAA Start): 7-Zip"
$fileType = "7zip"
TryCommand "$aaaPathChoco\choco.exe" "install $fileType --confirm --no-progress" $fileType
Write-Information "(AAA End): 7-Zip"

Write-Information "(AAA Start): Visual Studio Build Tools"
$fileType = "vsBuildTools"
TryCommand "$aaaPathChoco\choco.exe" "install visualstudio2022buildtools --package-parameters ""--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.Component.MSBuild"" --confirm --no-progress" $fileType
$aaaPathCMake = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$aaaPathMSBuild = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64"
$aaaPath += ";$aaaPathCMake;$aaaPathMSBuild"
$Env:CMAKE_BIN_PATH = $aaaPathCMake
$Env:MSBUILD_BIN_PATH = $aaaPathMSBuild
Write-Information "(AAA End): Visual Studio Build Tools"

Write-Information "(AAA End): Image Build Platform"

Write-Information "(AAA Start): Azure CLI (x64)"
$fileType = "az-cli"
$fileName = "$fileType.msi"
$fileLink = "https://aka.ms/installazurecliwindowsx64"
DownloadFile $fileName $fileLink $false
TryCommand $fileName "/quiet /norestart /log $fileType.log" $null
Write-Information "(AAA End): Azure CLI (x64)"

Write-Information "(AAA Start): .NET SDK (x64)"
$fileType = "dotnet-sdk"
$fileName = "$fileType.exe"
$fileLink = "https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.102/dotnet-sdk-10.0.102-win-x64.exe"
DownloadFile $fileName $fileLink $false
TryCommand $fileName "/quiet /norestart /log $fileType.log" $null
Write-Information "(AAA End): .NET SDK (x64)"

Write-Information "(AAA Start): NFS Client"
$fileType = "nfs-client"
dism /Online /NoRestart /LogPath:"$aaaRoot\$fileType" /Enable-Feature /FeatureName:ClientForNFS-Infrastructure /All
Write-Information "(AAA End): NFS Client"

Write-Information "(AAA Start): AD Tools"
$fileType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
dism /Online /NoRestart /LogPath:"$aaaRoot\$fileType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Write-Information "(AAA End): AD Tools"

if ($machineType -ne "VDI") {
  Write-Information "(AAA Start): Privacy Experience"
  $registryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
  New-Item -ItemType Directory -Path $registryKeyPath -Force
  New-ItemProperty -Path $registryKeyPath -PropertyType DWORD -Name "DisablePrivacyExperience" -Value 1 -Force
  Write-Information "(AAA End): Privacy Experience"
}

Write-Information "(AAA End): Image Build Core"

Write-Information "(AAA Start): Image Build Core (GPU)"

if ($gpuProvider -eq "AMD") {
  $fileType = "amd-gpu"
  if ($machineSize -like "*NG*" -and $machineSize -like "*v1*") {
    Write-Information "(AAA Start): AMD GPU (NG v1)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2248541"
    DownloadFile $fileName $fileLink $false
    TryCommand .\$fileName "-install -log $aaaRoot\$fileType.log" $null
    Write-Information "(AAA End): AMD GPU (NG v1)"
  } elseif ($machineSize -like "*NV*" -and $machineSize -like "*v4*") {
    Write-Information "(AAA Start): AMD GPU (NV v4)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2175154"
    DownloadFile $fileName $fileLink $false
    TryCommand .\$fileName "-install -log $aaaRoot\$fileType.log" $null
    Write-Information "(AAA End): AMD GPU (NV v4)"
  }
}

if ($gpuProvider -eq "NVIDIA.GRID") {
  Write-Information "(AAA Start): NVIDIA GPU (GRID)"
  $fileType = "nvidia-gpu-grid"
  $fileName = "$fileType.exe"
  $fileLink = "https://go.microsoft.com/fwlink/?linkid=874181"
  DownloadFile $fileName $fileLink $false
  TryCommand .\$fileName "-s -n -log:$aaaRoot\$fileType" $null
  Write-Information "(AAA End): NVIDIA GPU (GRID)"
}

if ($gpuProvider.StartsWith("NVIDIA")) {
  Write-Information "(AAA Start): NVIDIA GPU (CUDA)"
  $appVersion = "13.1.1"
  $fileType = "nvidia-gpu-cuda"
  $fileName = "cuda_${appVersion}_windows_network.exe"
  $fileLink = "https://developer.download.nvidia.com/compute/cuda/$appVersion/network_installers/$fileName"
  DownloadFile $fileName $fileLink $false
  TryCommand .\$fileName "-s -n -log:$aaaRoot\$fileType" $null
  Write-Information "(AAA End): NVIDIA GPU (CUDA)"
}

Write-Information "(AAA End): Image Build Core (GPU)"

Write-Information "(AAA Start): Job Scheduler"
Write-Information "(AAA End): Job Scheduler"

Write-Information "(AAA Start): Job Processor"

if ($jobProcessors -contains "PBRT") {
  Write-Information "(AAA Start): PBRT"
  $appVersion = "v4"
  $fileType = "pbrt"
  $filePath = "C:\Program Files\PBRT"
  New-Item -ItemType Directory -Path "$filePath" -Force
  TryCommand "$Env:GIT_BIN_PATH\git.exe" "clone --recursive https://github.com/mmp/$fileType-$appVersion.git" $fileType-1
  TryCommand "$Env:CMAKE_BIN_PATH\cmake.exe" "-B ""$filePath"" -S $aaaRoot\$fileType-$appVersion" $fileType-2
  TryCommand "$Env:MSBUILD_BIN_PATH\MSBuild.exe" """$filePath\PBRT-$appVersion.sln"" -p:Configuration=Release" $fileType-3
  $aaaPath += ";$filePath\Release"
  Write-Information "(AAA End): PBRT"
}

if ($jobProcessors -contains "Blender") {
  Write-Information "(AAA Start): Blender"
  $appVersion = "5.0.1"
  $fileType = "blender"
  $fileName = "$fileType-$appVersion-windows-x64.msi"
  $fileLink = "https://mirrors.iu13.net/blender/release/Blender$($appVersion.substring(0, 3))/$fileName"
  DownloadFile $fileName $fileLink $false
  TryCommand $fileName "/quiet /norestart /log $fileType.log" $null
  $aaaPath += ";C:\Program Files\Blender Foundation\Blender $($appVersion.substring(0, 3))"
  Write-Information "(AAA End): Blender"
}

Write-Information "(AAA End): Job Processor"

if ($aaaPath -ne "") {
  Write-Information "(AAA Path): $($aaaPath.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$aaaPath", "Machine")
}
