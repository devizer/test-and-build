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
# bash: the_date=$(TZ=UTC date "+%Y-%m-%d")
# $the_date=[DateTime]::UtcNow.ToString("yyyy-MM-dd")
# $version="$($version_short)-$($the_date)"
Write-Host "!> To Publish: $version"

$DOWNLOAD_PARTS_COUNT=(gci "$FROM/final-$ARCH-splitted/*.qcow2.7z.*").Count
Write-Host "!> DOWNLOAD_PARTS_COUNT: $DOWNLOAD_PARTS_COUNT"

# Build Source Folder
& cp ../bintray.json $Source_Folder

& mkdir -p "$Source_Folder/public-bintray"
Write-Host "!> Clearing folder [$Source_Folder/public-bintray]"
pushd "$Source_Folder/public-bintray"
    & rm -rf *
popd
# & ln -f -s "$FROM/final-$ARCH-splitted" "$Source_Folder/public-bintray/$version"
& mkdir -p "$Source_Folder/public-bintray/$version"; 
$cp_Cmd="cp -f $FROM/final-$ARCH-splitted/* $Source_Folder/public-bintray/$version"
Write-Host "|# $cp_Cmd"
df -T -h
& bash -c "$cp_Cmd"
df -T -h

Write-Host "!> Final bintray.json"
$binTray=$Global:BinTray_Object
$package="debian-$ARCH-for-building-and-testing"
$binTray.package.name=$package
$binTray.package.repo=$package
Write-Host "!> Final bintray.json`n$binTray"
SaveAsJson $binTray "$Source_Folder/bintray.json"

pushd $Source_Folder
Write-Host "!> Running dpl --dry-run for $(pwd)"
& time dpl --provider=bintray --file=bintray.json --user=devizer "--key=$($Env:BINTRAY_API_KEY)" --skip-cleanup # --dry-run
$isPublishOk=$?;
popd

if (-not $isPublishOk) {
    Write-Host "!> ERROR in dpl. Version is not updated."
    Write-Host "!> DELETING version [$version] for [$package]."
    $bintray_User="devizer"; 
    $bintray_API="https://api.bintray.com"
    $cmd_BinTray_Base="curl -u$($bintray_User):$($ENV:BINTRAY_API_KEY) -H Content-Type:application/json -H Accept:application/json"
    $cmd_BinTray_Delete="$cmd_BinTray_Base -X DELETE $($bintray_API)/packages/$($bintray_User)/$package/$package/versions/$version"
    & bash -c "$cmd_BinTray_Delete"
    exit;
}

# N1
Write-Host "!> Update Metadata"
pushd metadata
& mkdir -p public-bintray
& rm -rf ./public-bintray/*
@"

STABLE_VERSION=$version
DOWNLOAD_PARTS_COUNT=$DOWNLOAD_PARTS_COUNT
"@ > "public-bintray/VERSION-$ARCH.sh"
dpl --provider=bintray --file=bintray.json --user=devizer "--key=$($Env:BINTRAY_API_KEY)" --skip-cleanup
popd

# N2
Write-Host "!> Delete bintray versions except the stable [$version] version (in $(pwd))"
$Env:VERSION_STABLE="$version"
$Env:BINTRAY_REPO="$package"
$Env:PCK_NAME="$package"
$Env:BINTRAY_USER="devizer"
& bash delete-bintray-versions-except-stable.sh

