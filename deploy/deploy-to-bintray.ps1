#!/usr/bin/env pwsh

pushd ../build
& pwsh ./inject-git-info.ps1
popd

$version=(& cat ../bintray.json | jq -r ".version.name") | Out-String 
Write-Host "To Publish: $version"