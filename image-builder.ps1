#!/usr/bin/env pwsh

$build_folder="/github/test-and-build"

$definitions=@(
    @{
        key="arm"; BasicParts=5; BaseUrl="file://github.com/"
    } 
);

function Say { param( [string] $message )
Write-Host "$(Get-Elapsed) " -NoNewline -ForegroundColor Magenta
Write-Host "$message" -ForegroundColor Yellow
}

function Get-Elapsed
{
    if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
    [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("mm:ss"), "]");
}; Get-Elapsed | out-null;

function Build { param($definition)
    Say "Building $($definition.key)";
    $download_cmd="curl $($definition.BaseUrl)debian-$($definition.Key).qcow2.7z.[1-$($definition.BasicParts)] -o 'debian-$($definition.Key).qcow2.7z.#1'";
    
    Say "Shell: $download_cmd"
    New-Item -Type Directory $build_folder -ea SilentlyContinue;
    pushd $build_folder
    mkdir downloads
    pushd downloads
    & bash -c $download_cmd
    popd
    popd

}

$definitions | % {Build $_;};

