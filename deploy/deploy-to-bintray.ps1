#!/usr/bin/env pwsh
param(
    [string] $from
)

$Working_Folder="/tmp/debian-to-bintray"
& mkdir -p $Working_Folder



pushd ../build
& pwsh ./inject-git-info.ps1
popd

$version=(& cat ../bintray.json | jq -r ".version.name") | Out-String 
Write-Host "To Publish: $version"

& cp ../bintray.json $Working_Folder
