
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
        # ICS rocket-OS: use \opt or /opt
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

function Qemu-PowerMan-DownloadSmall {
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
        [ValidateSet("CentOS-6-AMD64", "Debian-10-arm64", "Debian-10-arm", "Debian-10-AMD64", "Debian-10-i386")]
        [string] $image
    )

    Say "Downloading $image image to: '$Global:Qemu_PowerMan_DownloadImageLocation'"
    new-item $Global:Qemu_PowerMan_DownloadImageLocation -ItemType Directory -EA SilentlyContinue 2> $null
    Qemu-Powerman-Bootstrap
    if (-not (Test-Path $Global:Qemu_PowerMan_DownloadImageLocation -PathType Container)) {
        throw "Can't access or create the '$($Global:Qemu_PowerMan_DownloadImageLocation)' directory"
    }

    $tmp_progress = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, ".progress"
    
    $errors = 0;
    $file_Metadata = [System.IO.Path]::Combine($tmp_progress, "VERSION-$image.sh")
    $url_Metadata="https://dl.bintray.com/devizer/debian-multiarch/VERSION-$image.sh"
    Say "Qeury for the latest version of '$image' image using '$url_Metadata'"
    if (-not (Qemu-PowerMan-DownloadBig $tmp_progress @($url_Metadata)))
    {
        Write-Error "Unable download metadata for '$image' from '$url_Metadata'. Abort"
        $errors++
        return $false;
    }
    $content_Metadata=Get-Content $file_Metadata -Raw
    Write-Host "Raw Metadata for '$image': $content_Metadata"
    $metadata=Qemu-PowerMan-ParseMetadata $content_Metadata
    # $metadata | fl
    Say "'$image' STABLE_VERSION: [$($Metadata.STABLE_VERSION)], DOWNLOAD_PARTS_COUNT: [$($Metadata.DOWNLOAD_PARTS_COUNT)]"

    # Caching debian-$($arch)-final.qcow2.7z*
    $cachedVersionFile = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, "Cached-$image-Version"
    $cachedVersion = "undefined"
    if (Test-Path $cachedVersionFile)
    {
        try { $cachedVersion = Get-Content $cachedVersionFile -EA SilentlyContinue }
        catch {  }
    }
    Say "Cached Version: '$cachedVersion'"
    if ($cachedVersion -ne $Metadata.STABLE_VERSION) {
        Say "Actual Version [$($Metadata.STABLE_VERSION)] was never cached. Clearing previously stored image if it was cached" 
        Remove-Item ($Global:Qemu_PowerMan_DownloadImageLocation + [System.IO.Path]::DirectorySeparatorChar + "debian-$($image)-final.qcow2.7z*") -Force
        $Metadata.STABLE_VERSION > $cachedVersionFile
    }
    # done: caching
    
    $names=@()
    for ($i = 1; $i -le $Metadata.DOWNLOAD_PARTS_COUNT; $i++) {
        $bin_tray_repo=($definitions | % { if ($_.Image -eq $image) {$_.BinTrayRepo} })
        Write-Host "BinTray Repo: $bin_tray_repo"
        $next_url = "https://dl.bintray.com/devizer/$bin_tray_repo/$($Metadata.STABLE_VERSION)/$($image)-final.qcow2.7z.$($i.ToString("000") )";
        $isOk = Qemu-PowerMan-DownloadCached $next_url "."
        if (!$isOk.IsOK)
        {
            $errors++;
        }
    }

    @("initrd.img", "vmlinuz") | % {
        # as of now it is embedded intu 7z
        # $kernel_url = "https://raw.githubusercontent.com/devizer/test-and-build/master/kernels/$arch/$_"
        # $downloadStatus = Qemu-PowerMan-DownloadCached $kernel_url "basic-kernel-$arch"
        # if (-not $downloadStatus.IsOK) { $errors++}
    }
    
    Say "Total errors for '$image' image: $errors"
    return $errors -eq 0;
}

function Qemu-Powerman-Bootstrap
{
    $Global:Aria_Exe = "aria2c" # for windows it will be redefined below
    try
    {
        $Global:Is64BitOperatingSystem = [Environment]::Is64BitOperatingSystem
    }
    catch
    {
        # legacy powershell on windows
        $Global:Is64BitOperatingSystem = $true -and ${Env:ProgramFiles(x86)};
        Write-Warning "Qemu-PowerMan may not work properly on legacy windows. It is not tested using powershell 2.0 or .NET 2.0/3.5"
    }
    if (-not ([Environment]::OSVersion.Platform -like "Win*"))
    {
        return
    }

    $Global:WindowsDownloadSuffix = Iif $Global:Is64BitOperatingSystem -Then "x64" -Else "x86"
    $aria_Url = "https://raw.githubusercontent.com/devizer/test-and-build/master/qemu-powerman-tools/aria2-$( $Global:WindowsDownloadSuffix ).7z.exe"

    $tools_Path = Combine-Path $Global:Qemu_PowerMan_DownloadImageLocation, "tools"
    $aria_7z_Exe = Combine-Path $tools_Path, "aria2c.7z.exe"
    $aria_Exe = Combine-Path $tools_Path, "aria2c.exe"
    $Global:Aria_Exe = $aria_Exe
    new-item $tools_Path -ItemType Directory -EA SilentlyContinue 2> $null

    $errors = $false
    if ((Test-Path $aria_Exe -PathType Leaf) -and (Test-Path "$( $aria_Exe ).done" -PathType Leaf))
    {
        Say "QEMU for Windows already downloaded to '$tools_Path'"
    } else {
        $webClient = new-object System.Net.WebClient;
        $webClient.DownloadFile($aria_Url, $aria_7z_Exe)
        pushd $tools_Path
        # unpack aria2c.exe
        & .\aria2c.7z.exe "-y" 1>$null 2>&1
        $errors = (-not $?) -or $errors;
        
        # download QEMU for windows
        $qemu_PowerMan_Tools_Archive = "https://raw.githubusercontent.com/devizer/test-and-build/master/qemu-powerman-tools/qemu-powerman-tools.7z.exe"
        & "$aria_Exe" "-c" $qemu_PowerMan_Tools_Archive 1>$null 2>&1
        $errors = (-not $?) -or $errors;
        
        # extract QEMU for windows
        & .\qemu-powerman-tools.7z.exe -y 1>$null 2>&1
        $errors = (-not $?) -or $errors;
        popd
    }

    $new_Path1 = Combine-Path $tools_Path, "qemu"
    $new_Path2 = Combine-Path $tools_Path, "putty"
    $new_Path3 = Combine-Path $tools_Path, "aria2", $Global:WindowsDownloadSuffix
    $new_Path4 = Combine-Path $tools_Path, "7z", $Global:WindowsDownloadSuffix
    $new_Path5 = Combine-Path $tools_Path, "ANSI188", $Global:WindowsDownloadSuffix
    
    if (-not $Global:SkipCheckPath)
    {
        $append_To_PATH = ""
        @($new_Path1, $new_Path2, $new_Path3, $new_Path4, $new_Path5) | % {
            $append_To_PATH += [System.IO.Path]::PathSeparator + $_
            if (-not (Test-Path $_ -PathType Container))
            {
                Write-Warning "Unable to unpack bootstrapper: '$_'"
                $errors = $true
            }
        }

        if ($errors)
        {
            Write-Warning "There was errors during downloading QEMU for Windows"
        }
        else
        {
            $Env:PATH += $append_To_PATH
            "ok" > "$( $aria_Exe ).done"
            Write-Host "Session's PATH:"
            $arr1=$Env:PATH.Split([System.IO.Path]::PathSeparator);
            $path2=[string]::Join($([Environment]::NewLine), $arr1)
            Write-Host $path2
            
            $qemu_Version = (& qemu-system-arm --version 2>&1) | Out-String
            $qemu_Version = $qemu_Version.Split([char]10)[0].Trim() 
            Say "QEMU Version: $qemu_Version"
        }
        $Global:SkipCheckPath = $true;
    }
}

function Qemu-PowerMan-Impl-Start {
    param([PSObject] $vm)
    throw "$($MyInvocation.InvocationName) Not Implemented"
}

function Qemu-PowerMan-Impl-Connect {
    param([PSObject] $vm, [int] $timeout = 300) # 300 is for slow ATOM, 5 y.o. xeon needs 30 seconds
    if ($timeout -le 0) { $timeout = 300}
    throw "$($MyInvocation.InvocationName) Not Implemented (timeout is $timeout)"
}

function Qemu-PowerMan-Impl-CopyToGuest {
    param([PSObject] $vm, [string] $FromHost, [string] $ToGuest)
    throw "$($MyInvocation.InvocationName) Not Implemented (from $FromHost to $ToGuest)"
}

function Qemu-PowerMan-Impl-CopyFromGuest {
    param([PSObject] $vm, [string] $FromGuest, [string] $ToHost)
    throw "$($MyInvocation.InvocationName) Not Implemented (from $FromGuest to $ToHost)"
}

function Qemu-PowerMan-Impl-Exec {
    param([PSObject] $vm, $Whatever)
    # $Whatever is a string os PSObject, see Qemu-PowerMan-Design.ps1
    throw "$($MyInvocation.InvocationName) Not Implemented (to run is $Whatever)"
}

function Qemu-PowerMan-Impl-Shutdown {
    param([PSObject] $vm, [int] $timeout = 300)
    if ($timeout -le 0) { $timeout = 300}
    throw "$($MyInvocation.InvocationName) Not Implemented (timeout is $timeout)"
}

function Qemu-PowerMan-Deploy {
    param([PSObject] $vm)

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "Start" -Value {
        return Qemu-PowerMan-Impl-Start -VM $vm
    }

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "Connect" -Value {
        return Qemu-PowerMan-Impl-Connect -VM $vm -TimeOut $args[0]
    }

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "CopyToGuest" -Value {
        return Qemu-PowerMan-Impl-CopyToGuest -VM $vm -FromHost $args[0] -ToGuest $args[1]
    }

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "CopyFromGuest" -Value {
        return Qemu-PowerMan-Impl-CopyFromGuest -VM $vm -FromGuest $args[0] -ToHost $args[1]
    }

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "Exec" -Value {
        return Qemu-PowerMan-Impl-Run -VM $vm -Whatever $args[0]
    }

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "Shutdown" -Value {
        return Qemu-PowerMan-Impl-Shutdown -VM $vm -Timeout $args[0]
    }

    Add-Member -MemberType ScriptMethod -InputObject $vm -Name "InstallService" -Value {
        return Qemu-PowerMan-Impl-InstallService -VM $vm -ServiceDescription $args[0]
    }

    return $true;
}
    
