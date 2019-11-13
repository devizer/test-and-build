#!/usr/bin/env pwsh
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf *; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; pwsh image-builder.ps1 

$build_folder="/transient-builds/test-and-build"

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
    $key=$definition.key
    Say "Building $($definition.key)";

    Say "Downloading basic image: $key"
    $download_cmd="curl $($definition.BaseUrl)debian-$($definition.Key).qcow2.7z.00[1-$($definition.BasicParts)] -o 'debian-$($definition.Key).qcow2.7z.00#1'";
    Write-Host "shell command: [$download_cmd]";
    New-Item -Type Directory $build_folder -ea SilentlyContinue;
    pushd $build_folder
    mkdir downloads-$key; pushd downloads-$key
    & bash -c $download_cmd
    $arch1 = join-Path -Path "." -ChildPath "*.001" -Resolve
    popd

    Say "Extracting basic image: $key"
    Write-Host "archive: $arch1";
    mkdir basic-image-$key; pushd basic-image-$key 
    & 7z -y x $arch1
    # & bash -c 'rm -f *.7z.*'
    $qcowFile = join-Path -Path "." -ChildPath "*qcow2*" -Resolve
    
    Say "Basic Image exctracted: $qcowFile";
    popd
    popd

}

$definitions | % {Build $_;};

