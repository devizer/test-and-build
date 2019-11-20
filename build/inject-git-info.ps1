#!/usr/bin/env pwsh

function SaveAsJson { 
  param([object]$anObject, [string]$fileName) 
  $unixContent = ($anObject | ConvertTo-Json -Depth 99).Replace("`r", "")
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
  [System.IO.File]::WriteAllLines($fileName, $unixContent, $Utf8NoBomEncoding)
}

function GetVersion {
  $ver = Get-Content "version.txt"
  return $ver
}

function SaveContent {
  param([object]$content, [string]$fileName) 
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
  [System.IO.File]::WriteAllLines($fileName, $content, $Utf8NoBomEncoding)

}

function Get-Git-Info {
    $commitsRaw = & { set TZ=GMT; git log -n 999999 --date=raw --pretty=format:"%cd" }
    $lines = $commitsRaw.Split([Environment]::NewLine)
    $commitCount = $lines.Length
    $commitDate = $lines[0].Split(" ")[0]
    Write-Host "Commit Counter: [$commitCount]"
    Write-Host "Commit Date: [$commitDate]"
    return @{ CommitCount=$commitCount; CommitDate=$commitDate }
}

# AssemblyInfo.cs
$versionMain = GetVersion
$build = (Get-Git-Info).CommitCount
$version = "$($versionMain).$($build)"

# BinTray
$binTray = Get-Content "../bintray.json" | ConvertFrom-Json
Write-Host "Old .Version.Name $($binTray.version.name)"
Write-Host "Old .version.desc $($binTray.version.desc)"
$binTray.version.name = "$version"
$binTray.version.desc = "Build $version"
SaveAsJson $binTray "../bintray.json"

