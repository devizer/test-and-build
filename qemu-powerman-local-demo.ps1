. "$($PSScriptRoot)\include\Utilities.ps1"
. "$($PSScriptRoot)\include\Main.ps1"
. "$($PSScriptRoot)\include\Qemu-PowerMan.ps1"

if (Test-Path "V:\" -PathType Container)
{
    $Global:Qemu_PowerMan_DownloadImageLocation = "V:\Qemu_PowerMan_DownloadImageLocation"
}

$ok1 = Qemu-PowerMan-DownloadImage "CentOS-6-AMD64"
$ok2 = Qemu-PowerMan-DownloadImage "Debian-10-arm64"
$ok3 = Qemu-PowerMan-DownloadImage "Debian-10-arm"
$ok4 = Qemu-PowerMan-DownloadImage "Debian-10-AMD64"

