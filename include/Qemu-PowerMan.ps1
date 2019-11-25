$Global:Qemu_PowerMan_DownloadImageLocation=$Env:HOME
if (-not $Global:Qemu_PowerMan_DownloadImageLocation) {$Global:Qemu_PowerMan_DownloadImageLocation=$Env:LocalAppData}
if (-not $Global:Qemu_PowerMan_DownloadImageLocation) {$Global:Qemu_PowerMan_DownloadImageLocation=$Env:AppData}
# $Global:Qemu_PowerMan_DownloadImageLocation += [System.IO.Path]::DirectorySeparatorChar + ".local" + [System.IO.Path]::DirectorySeparatorChar + "qemu-powerman"
$Global:Qemu_PowerMan_DownloadImageLocation = [System.IO.Path]::Combine($Global:Qemu_PowerMan_DownloadImageLocation, ".local", "qemu-powerman");
# $Global:Qemu_PowerMan_DownloadImageLocation

function Qemu-PowerMan-DownloadSmall{
    param([string]$url,[string]$file)
    $prev = [System.Net.ServicePointManager]::SecurityProtocol
    $next = (($prev -bor [System.Net.SecurityProtocolType]::Tls11) -bor [System.Net.SecurityProtocolType]::Tls12)
    [System.Net.ServicePointManager]::SecurityProtocol = $next

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
    $d=new-object System.Net.WebClient;
    $d.DownloadFile($url,$outfile)
}

function Qemu-PowerMan-DownloadBig{
    param([string]$toDirectory, [string[]]$urls)
    new-item $toDirectory -ItemType Directory *> $null
    $urls | % {
        $fullName = [System.IO.Path]::Combine($toDirectory, [System.IO.Path]::GetFileName($_))
        if (Test-Path $fullName) { Remove-Item $fullName -Force -EA SilentlyContinue }
    }
    $output = (& aria2c "-d$toDirectory" "-Z" $urls 2>&1) | Out-String
    $isOk = $?;
    Write-Host $output 
    if (!$isOk) {
        Write-Error "Error downloading $urls`n$output"
    }
    return $isOk 
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
        [string] $arch,
        [bool] $noCache = $false
    )

    $tmp_progress=[System.IO.Path]::Combine($Global:Qemu_PowerMan_DownloadImageLocation, ".progress");
    # $tmp_progress2=$tmp_progress + [System.IO.Path]::DirectorySeparatorChar 
    
    Say "Downloading $arch image to: '$Global:Qemu_PowerMan_DownloadImageLocation'"
    # new-item $tmp_progress -ItemType Directory *> $null
    
    if (-not (Test-Path $Global:Qemu_PowerMan_DownloadImageLocation -PathType Container)) {
        throw "Can't access or create the '$($Global:Qemu_PowerMan_DownloadImageLocation)' directory"
    }

    $errors=0;
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
    $metadata | fl
    Say "'$arch' STABLE_VERSION: [$($Metadata.STABLE_VERSION)], DOWNLOAD_PARTS_COUNT: [$($Metadata.DOWNLOAD_PARTS_COUNT)]"
    $names=@()
    for ($i = 1; $i -le $Metadata.DOWNLOAD_PARTS_COUNT; $i++) {
        $next_url="https://dl.bintray.com/devizer-404/debian-$arch-for-building-and-testing/10.2.604/debian-$arch-final.qcow2.7z.$($i.ToString("000"))";
        $next_fileonly=[System.IO.Path]::GetFileName($next_url);
        $next_fullpath=$Global:Qemu_PowerMan_DownloadImageLocation + [System.IO.Path]::DirectorySeparatorChar + $next_fileonly
        $next_donename=$next_fullpath + ".done"
        $next_tempcopy=$tmp_progress + [System.IO.Path]::DirectorySeparatorChar + $next_fileonly;
        if (Test-Path $next_donename -PathType Leaf)
        {
            Say "Already downloaded. Skipping '$next_fileonly'"
        }
        else
        {
            Remove-Item $next_tempcopy -Force -EA SILENTLYCONTINUE
            Say "Downloading '$next_fileonly' of $($Metadata.DOWNLOAD_PARTS_COUNT)"
            $isOk = Qemu-PowerMan-DownloadBig $tmp_progress @($next_url)
            if ($isOk) {
                Move-Item $next_tempcopy $next_fullpath -Force
                "ok" > $next_donename 
            }
            else {
                Say "ERROR downloading '$next_fileonly'"
                Remove-Item $next_tempcopy -Force -EA SILENTLYCONTINUE *> $null
                $errors++;
            }
        }
        
        $names += $next_url
    }
    
    Say "Total errors for '$arch' image: $errors"
    return $errors -eq 0;

    # Qemu-PowerMan-DownloadBig $tmp_progress $names
}
