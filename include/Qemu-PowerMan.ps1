function Combine-Path {
    param([string[]] $parts)
    return [System.IO.Path]::GetFullPath( [System.IO.Path]::Combine($parts) )
}

function Directory-Separator-Char { [System.IO.Path]::DirectorySeparatorChar }

function Qemu-PowerMan-OnLoad
{
    if ($Env:HOME)
    {
        # linux
        $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path $Env:HOME, ".local", "qemu-powerman"
    }
    elseif ($Env:LocalAppData)
    {
        # Windows Vista+
        $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path $Env:LocalAppData, "qemu-powerman"
    }
    elseif ($Env:AppData)
    {
        # Windows XP/2003
        $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path $Env:AppData, "qemu-powerman"
        Write-Warning "aria2c is not fully supported on Windows XP/2003 for bintray"
    }
    else
    {
        # ICS z-OS
        $Global:Qemu_PowerMan_DownloadImageLocation = Combine-Path ([System.IO.Path]::DirectorySeparatorChar + "opt"), "qemu-powerman"
    }
}; Qemu-PowerMan-OnLoad

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
    Qemu-Powerman-Bootstrap
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

function Qemu-Powerman-Bootstrap {
    $Global:Aria_Exe = "aria2c" # for windows it will be redefined below
    try { $Global:Is64BitOperatingSystem = [Environment]::Is64BitOperatingSystem }
    catch {
        # legacy powershell on windows
        $Global:Is64BitOperatingSystem = $true -and ${Env:ProgramFiles(x86)};
        Write-Warning "Qemu-PowerMan may not work properly on legacy windows. It is not tested using powershell 2.0 or .NET 2.0/3.5"
    }
    if (-not [Environment]::OSVersion.Platform -like "Win*") { return }

    $Global:WindowsDownloadSuffix = if ($Global:Is64BitOperatingSystem) {"x64"} else {"x86"}
    $aria_Url = "https://raw.githubusercontent.com/devizer/test-and-build/master/qemu-powerman-tools/aria2-$($Global:WindowsDownloadSuffix).7z.exe"
    
    $tools_Path  = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, "tools"
    $aria_7z_Exe = Combine-Path $tools_Path, "aria2c.7z.exe"
    $aria_Exe    = Combine-Path $tools_Path, "aria2c.exe"
    $Global:Aria_Exe = $aria_Exe
    new-item $tools_Path -ItemType Directory -EA SilentlyContinue 2> $null
    
    if ((Test-Path $aria_Exe -PathType Leaf) -and (Test-Path "$($aria_Exe).done" -PathType Leaf)) {
        Say "QEMU for Windows already downloaded to '$tools_Path'"
        return;
    }

    $errors = $false
    $webClient = new-object System.Net.WebClient;
    $webClient.DownloadFile($aria_Url, $aria_7z_Exe)
    pushd $tools_Path
    & .\aria2c.7z.exe "-y" 1>$null 2>&1
    $errors = (-not $?) -or $errors;
    $qemu_PowerMan_Tools_Archive = "https://raw.githubusercontent.com/devizer/test-and-build/master/qemu-powerman-tools/qemu-powerman-tools.7z.exe"
    & "$aria_Exe" "-c" $qemu_PowerMan_Tools_Archive 1>$null 2>&1
    $errors = (-not $?) -or $errors;
    & .\qemu-powerman-tools.7z.exe -y 1>$null 2>&1
    $errors = (-not $?) -or $errors;

    $new_Path1 = Combine-Path "$(pwd)", "qemu"
    $new_Path2 = Combine-Path "$(pwd)", "putty"
    $new_Path3 = Combine-Path "$(pwd)", "aria2", $Global:WindowsDownloadSuffix
    $new_Path4 = Combine-Path "$(pwd)", "7z", $Global:WindowsDownloadSuffix
    $new_Path5 = Combine-Path "$(pwd)", "ANSI188", $Global:WindowsDownloadSuffix
    popd
    
    $append_To_PATH=""
    @($new_Path1, $new_Path2, $new_Path3, $new_Path4, $new_Path5) | % {
        $append_To_PATH += [System.IO.Path]::DirectorySeparatorChar + $_
        if (-not (Test-Path $_ -PathType Container)) {
            Write-Warning "Unable to unpack bootstrapper: '$_'"
            $errors = $true
        }
    }

    if ($errors) {
        Write-Warning "There was errors during downloading QEMU for Windows"
    } else {
        $Env:PATH += $append_To_PATH
        "ok" > "$($aria_Exe).done"
        Write-Host "Session's PATH:"
        Write-Host $Env:PATH.Split([System.IO.Path]::DirectorySeparatorChar) | Join-String -Separator "`n"
    }
}
