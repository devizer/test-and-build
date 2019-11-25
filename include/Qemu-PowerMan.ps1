$Global:Qemu_PowerMan_DownloadImageLocation=$Env:HOME
if (-not $Global:Qemu_PowerMan_DownloadImageLocation) {$Global:Qemu_PowerMan_DownloadImageLocation=$Env:LocalAppData}
if (-not $Global:Qemu_PowerMan_DownloadImageLocation) {$Global:Qemu_PowerMan_DownloadImageLocation=$Env:AppData}
$Global:Qemu_PowerMan_DownloadImageLocation += [System.IO.Path]::DirectorySeparatorChar + ".local" + [System.IO.Path]::DirectorySeparatorChar + "qemu-powerman" 
$Global:Qemu_PowerMan_DownloadImageLocation

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
    param([string]$toDirectory,[string[]]$urls)
    new-item $toDirectory -ItemType Directory *> $null
    & aria2c "-d$toDirectory" "-Z" $urls
}

function Qemu-PowerMan-ParseMetadata
{
    param([String] $metadata)
    $ret=New-Object PSObject;
    foreach ($row7 in $metadata.Split(@([char]13,[char]10)))
    {
        Write-Host "row7: $row7" -ForegroundColor Red
        $arr7 = $row7.Split($([char]61))
        if (($arr7.Length -ge 2))
        {
            $key7 = $arr7[0].Trim()
            $value7 = $arr7[1].Trim()
            $ret | Add-Member $key7 $value7
        }
    }
    return $ret;
}

function Qemu-PowerMan-DownloadImage{
    param(
        [ValidateSet("arm64", "arm", "AMD64", "i386")]
        [string] $arch,
        [bool] $noCache = $false
    )

    $tmp_progress=$Global:Qemu_PowerMan_DownloadImageLocation + [System.IO.Path]::DirectorySeparatorChar + ".progress"
    $tmp_progress2=$tmp_progress + [System.IO.Path]::DirectorySeparatorChar 
    
    Say "Downloading $arch image to: '$Global:Qemu_PowerMan_DownloadImageLocation'"
    new-item $tmp_progress -ItemType Directory *> $null
    
    if (-not (Test-Path $Global:Qemu_PowerMan_DownloadImageLocation -PathType Container)) {
        throw "Can't access or create the '$($Global:Qemu_PowerMan_DownloadImageLocation)' directory"
    }

    Say "Qeury for latest version of '$arch' image"
    $file_Metadata=$tmp_progress2 + "VERSION-$arch.sh"
    $url_Metadata="https://dl.bintray.com/devizer/debian-multiarch/VERSION-$arch.sh"
    Qemu-PowerMan-DownloadBig $tmp_progress @($url_Metadata) 
    $content_Metadata=Get-Content $file_Metadata -Raw
    Say "Metadata: [$content_Metadata]"
    $metadata=Qemu-PowerMan-ParseMetadata $content_Metadata
    $metadata | fl
    Say "STABLE_VERSION: [$($Metadata.STABLE_VERSION)]"
    Say "DOWNLOAD_PARTS_COUNT: [$($Metadata.DOWNLOAD_PARTS_COUNT)]"
    $names=@()
    for ($i = 1; $i -le $Metadata.DOWNLOAD_PARTS_COUNT; $i++) {
        $names += "https://dl.bintray.com/devizer/debian-$arch-for-building-and-testing/10.2.604/debian-arm-final.qcow2.7z.$($i.ToString("000"))"; 
    }

    Write-Host $names
    Qemu-PowerMan-DownloadBig $tmp_progress $names
    

    # throw "Not Implemented";
}
