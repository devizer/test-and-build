. "$($PSScriptRoot)\include\Utilities.ps1"
. "$($PSScriptRoot)\include\Qemu-PowerMan.ps1"

if (Test-Path "V:\" -PathType Container)
{
    $Global:Qemu_PowerMan_DownloadImageLocation = "V:\Qemu_PowerMan_DownloadImageLocation"
}

$okArm = Qemu-PowerMan-DownloadImage "arm"
$okArm64 = Qemu-PowerMan-DownloadImage "arm64"
