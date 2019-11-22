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
. ./inject-git-info.ps1
popd

$version=(& cat ../bintray.json | jq -r ".version.name") | Out-String
$version=$version.Trim(@([char]10,[char]13))
Write-Host "To Publish: $version"

# Build Source Folder
& cp ../bintray.json $Source_Folder

& mkdir -p "$Source_Folder/public-bintray"
Write-Host "Clearing folder [$Source_Folder/public-bintray]"
pushd "$Source_Folder/public-bintray"
    & rm -rf *
popd
& ln -f -s "$FROM/final-$ARCH-splitted" "$Source_Folder/public-bintray/$version"


Write-Host "final bintray.json"
$binTray=$Global:BinTray_Object
$package="debian-$ARCH-for-building-and-testing"
$binTray.package.name=$package
$binTray.package.repo=$package
Write-Host "final bintray.json`n$binTray"
SaveAsJson $binTray "$Source_Folder/bintray.json"


