#!/usr/bin/env pwsh

pushd ../build
& pwsh ./inject-git-info.ps1
pop

$version="$(cat ../bintray.json | jq -r ".version.name")"
Write-Host "To Publish: $version"