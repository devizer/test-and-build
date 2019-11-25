function Combine-Path {
    param([string[]] $parts)
    return [System.IO.Path]::GetFullPath( [System.IO.Path]::Combine($parts) )
}

function Directory-Separator-Char { [System.IO.Path]::DirectorySeparatorChar }

if ($Env:HOME) {
    # linux
    $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path $Env:HOME, ".local", "qemu-powerman"    
}
elseif ($Env:LocalAppData) {
    # Windows Vista+
    $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path $Env:LocalAppData, "qemu-powerman"
}
elseif ($Env:AppData) {
    # Windows XP/2003
    $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path $Env:AppData, "qemu-powerman"
    Write-Warning "aria2c is not fully supported on Windows XP/2003 for bintray"
}
else {
    # ICS z-OS
    $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path ([System.IO.Path]::DirectorySeparatorChar + "opt"), "qemu-powerman"
}

function Qemu-PowerMan-DownloadCached {
    param([string] $url, [string] $cacheSubfolder)
    $fileNameOnly = [System.IO.Path]::GetFileName($url)
    # Say "Caching '$url' as '$cacheSubfolder --> $fileNameOnly'"
    $fullPath = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, $cacheSubfolder, $fileNameOnly
    $donePath = $fullPath + ".done"
    if ((Test-Path $donePath -PathType Leaf) -and (Test-Path $fullPath -PathType Leaf)) {
        Say "Already cached: $cacheSubfolder --> $fileNameOnly"
        return @{IsOK=$true;LocalPath=$fullPath}
    }
    else
    {
        Say "Downloading $cacheSubfolder --> $fileNameOnly"
        $tmp_progress = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, ".progress", $cacheSubfolder
        $tmp_copy = Combine-Path $tmp_progress, $fileNameOnly
        Write-Host "Downloading is InProgress: $tmp_copy"
        $isOk = Qemu-PowerMan-DownloadBig $tmp_progress  @($url)
        if ($isOk -and (Test-Path $tmp_copy -PathType Leaf))
        {
            $fullDirectoryPath=[System.IO.Path]::GetDirectoryName($fullPath)
            new-item $fullDirectoryPath -ItemType Directory -EA SilentlyContinue 2> $null
            Move-Item $tmp_copy $fullPath -Force
            "ok" > $donePath
            return @{IsOK=$true;LocalPath=$fullPath}
        }
        else {
            Say "ERROR downloading $cacheSubfolder --> $fileNameOnly"
            return @{IsOK=$false}
        }
    }
}

function Qemu-PowerMan-DownloadBig {
    param([string]$toDirectory, [string[]]$urls)
    new-item $toDirectory -ItemType Directory -EA SilentlyContinue 2> $null
    $urls | % {
        $fullName = [System.IO.Path]::Combine($toDirectory, [System.IO.Path]::GetFileName($_))
        if (Test-Path $fullName) { Remove-Item $fullName -Force -EA SilentlyContinue }
    }
    $output = (& aria2c "-d$toDirectory" "-Z" $urls 2>&1 ) | Out-String
    # $isOk = $? -and (-not $LASTEXITCODE);
    $isOk = $?;
    Write-Host $output
    if (!$isOk) {
        Write-Error "Error downloading $urls`n$output"
    }
    return $isOk
}

function Qemu-PowerMan-DownloadSmall{
    param([string]$url,[string]$file)
    $prev = [System.Net.ServicePointManager]::SecurityProtocol
    $next = (($prev -bor [System.Net.SecurityProtocolType]::Tls11) -bor [System.Net.SecurityProtocolType]::Tls12)
    [System.Net.ServicePointManager]::SecurityProtocol = $next

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
    $d=new-object System.Net.WebClient;
    $d.DownloadFile($url,$outfile)
}

function Qemu-PowerMan-ParseMetadata
{
    param([String] $metadata)
    $ret7=New-Object PSObject;
    foreach ($row7 in $metadata.Replace([char]13,[char]10).Split([char]10))
    {
        $arr7 = $row7.Split($([char]61))
        if (($arr7.Length -ge 2))
        {
            $key7 = $arr7[0].Trim()
            $value7 = $arr7[1].Trim()
            $ret7 | Add-Member $key7 $value7
        }
    }
    return $ret7;
}

function Qemu-PowerMan-DownloadImage{
    param(
        [ValidateSet("arm64", "arm", "AMD64", "i386")]
        [string] $arch
    )

    Say "Downloading $arch image to: '$Global:Qemu_PowerMan_DownloadImageLocation'"
    new-item $Global:Qemu_PowerMan_DownloadImageLocation -ItemType Directory -EA SilentlyContinue 2> $null
    if (-not (Test-Path $Global:Qemu_PowerMan_DownloadImageLocation -PathType Container)) {
        throw "Can't access or create the '$($Global:Qemu_PowerMan_DownloadImageLocation)' directory"
    }

    $tmp_progress = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, ".progress"
    
    $errors = 0;
    $file_Metadata = [System.IO.Path]::Combine($tmp_progress, "VERSION-$arch.sh")
    $url_Metadata="https://dl.bintray.com/devizer/debian-multiarch/VERSION-$arch.sh"
    Say "Qeury for the latest version of '$arch' image using '$url_Metadata'"
    if (-not (Qemu-PowerMan-DownloadBig $tmp_progress @($url_Metadata)))
    {
        Write-Error "Unable download metadata for '$arch' from '$url_Metadata'. Abort"
        $errors++
        return $false;
    }
    $content_Metadata=Get-Content $file_Metadata -Raw
    Say "Metadata: [$content_Metadata]"
    $metadata=Qemu-PowerMan-ParseMetadata $content_Metadata
    # $metadata | fl
    Say "'$arch' STABLE_VERSION: [$($Metadata.STABLE_VERSION)], DOWNLOAD_PARTS_COUNT: [$($Metadata.DOWNLOAD_PARTS_COUNT)]"
    $names=@()
    for ($i = 1; $i -le $Metadata.DOWNLOAD_PARTS_COUNT; $i++) {
        $next_url = "https://dl.bintray.com/devizer/debian-$arch-for-building-and-testing/10.2.604/debian-$arch-final.qcow2.7z.$($i.ToString("000") )";
        $isOk = Qemu-PowerMan-DownloadCached $next_url "."
        if (!$isOk.IsOK)
        {
            $errors++;
        }
    }

    @("initrd.img", "vmlinuz") | % {
        $kernel_url = "https://raw.githubusercontent.com/devizer/test-and-build/master/kernels/$arch/$_"
        $downloadStatus = Qemu-PowerMan-DownloadCached $kernel_url "basic-kernel-$arch"
        if (-not $downloadStatus.IsOK) { $errors++}
    }
    
    Say "Total errors for '$arch' image: $errors"
    return $errors -eq 0;
}
