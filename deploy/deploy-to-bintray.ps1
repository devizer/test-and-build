#!/usr/bin/env pwsh
# git pull; pwsh deploy-to-bintray.ps1 -From /transient-builds/FINAL-SUPER -Arch arm64
param(
    [Parameter(Position=0,mandatory=$true)]
    [string] $FROM,
    [Parameter(Position=1,mandatory=$true)]
    [string] $ARCH
)

$Source_Folder="$(pwd)/tmp/debian-to-bintray-$ARCH"
& mkdir -p $Source_Folder

# Prepare version
pushd ../build
    . ./inject-git-info.ps1
popd

$version=(& cat ../bintray.json | jq -r ".version.name") | Out-String
$version=$version.Trim(@([char]10,[char]13))
Write-Host "To Publish: $version"

$DOWNLOAD_PARTS_COUNT=(gci -Path "$FROM/*.qcow2.7z.*").Count
Write-Host "DOWNLOAD_PARTS_COUNT: $DOWNLOAD_PARTS_COUNT"

# Build Source Folder
& cp ../bintray.json $Source_Folder

& mkdir -p "$Source_Folder/public-bintray"
Write-Host "Clearing folder [$Source_Folder/public-bintray]"
pushd "$Source_Folder/public-bintray"
    & rm -rf *
popd
# & ln -f -s "$FROM/final-$ARCH-splitted" "$Source_Folder/public-bintray/$version"
& mkdir -p "$Source_Folder/public-bintray/$version"; 
$cp_Cmd="cp -f $FROM/final-$ARCH-splitted/* $Source_Folder/public-bintray/$version"
Write-Host "|# $cp_Cmd"
& bash -c "$cp_Cmd"


Write-Host "final bintray.json"
$binTray=$Global:BinTray_Object
$package="debian-$ARCH-for-building-and-testing"
$binTray.package.name=$package
$binTray.package.repo=$package
Write-Host "final bintray.json`n$binTray"
SaveAsJson $binTray "$Source_Folder/bintray.json"

pushd $Source_Folder
Write-Host "Running dpl --dry-run for $(pwd)"
& dpl --provider=bintray --file=bintray.json --user=devizer "--key=$($Env:BINTRAY_API_KEY)" --skip-cleanup # --dry-run
popd

Write-Host "Delete bintray versions except the stable [$version] version (in $(pwd))"
$Env:VERSION_STABLE="$version"
$Env:BINTRAY_REPO="$package"
$Env:PCK_NAME="$package"
$Env:BINTRAY_USER="devizer"
& bash delete-bintray-versions-except-stable.sh

Write-Host "Update Metadata"
pusdh metadata
& mkdir -p public-bintray
& rm -rf ./public-bintray/*
@"

STABLE_VERSION=$version
DOWNLOAD_PARTS_COUNT=$DOWNLOAD_PARTS_COUNT
"@ > "metadata/VERSION-$ARCH.sh"
dpl --provider=bintray --file=bintray.json --user=devizer --key=$BINTRAY_API_KEY --skip-cleanup
