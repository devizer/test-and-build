#!/usr/bin/env pwsh
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf *; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; pwsh image-builder.ps1 

$build_folder="/tarnsient-builds/test-and-build"

$definitions=@(
    @{
        key="arm"; BasicParts=5; BaseUrl="file:///github.com/"
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
    $download_cmd="curl $($definition.BaseUrl)debian-$($definition.Key).qcow2.7z.00[1-$($definition.BasicParts)] -o 'debian-$($definition.Key).qcow2.7z.00#1'";
    
    Say "Shell: $download_cmd"
    New-Item -Type Directory $build_folder -ea SilentlyContinue;
    pushd $build_folder
    mkdir downloads
    pushd downloads
    & bash -c $download_cmd
    $arch1 = join-Path -Path "." -ChildPath "*.001" -Resolve
    Say "Extracting $arch1"
    & 7z x $arch1
    & rm "*.7z*"
    $qcowFile = join-Path -Path "." -ChildPath "*qcow2*" -Resolve
    Say "Basic Image exctracted: $qcowFile";
    popd
    popd

}

$definitions | % {Build $_;};

