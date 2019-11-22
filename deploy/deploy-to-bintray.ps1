#!/usr/bin/env pwsh
# git pull; pwsh deploy-to-bintray.ps1 -From /transient-builds/FINAL-SUPER -Arch arm64
param(
    [Parameter(Position=0,mandatory=$true)]
    [string] $FROM,
    [Parameter(Position=1,mandatory=$true)]
    [string] $ARCH
)

$Source_Folder="/tmp/debian-to-bintray-$ARCH"
& mkdir -p $Source_Folder

# Prepare version
pushd ../build
./inject-git-info.ps1
popd

$version=(& cat ../bintray.json | jq -r ".version.name") | Out-String
$version=$version.Trim(@([char]10,[char]13))
Write-Host "To Publish: $version"

# Build Source Folder
& cp ../bintray.json $Source_Folder

& mkdir -p "$Source_Folder/public-bintray"
& ln -f -s "$FROM/final-$ARCH-splitted" "$Source_Folder/public-bintray/$version" 

Get-Variable
Write-Host "Global:BinTray_Object vvv"
$Global:BinTray_Object