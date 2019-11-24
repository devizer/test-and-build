#!/usr/bin/env pwsh
param(
    [ValidateSet("arm64", "arm", "AMD64", "i386")]    
    [string[]] $Images,
    [string] $Only,
    [string] $Skip,
    [string] $FinalSize = "13G",
    [int]    $MaxVmCores = 4,
    [string] $OutputFolder = "/transient-builds/test-and-build"
)

. "$($PSScriptRoot)\include\Main.ps1"
. "$($PSScriptRoot)\include\Utilities.ps1"
. "$($PSScriptRoot)\include\Build.ps1"

$Global_Ignore_Features=$Skip
$Global_Only_Features=$Only

$Global_7z_Compress_Priority="-20"
$Global_7z_DeCompress_Priority="-10"
$Global_7z_Threads=2
$Global_FinalSize=$FinalSize
$Global_SSH_Timeout=5*60
$Global_ExpandDisk_Priority="-20"
$Global_Max_VM_Cores = $MaxVmCores

$Global_7z_Compress_Args = if ($Env:TRAVIS) { "-mx=1 -mfb=16 -md=16k" } else { "-mx=3 -mfb=32 -md=4m" }
if ($Env:AZURE_HTTP_USER_AGENT) { 
    $Global_7z_Compress_Args="-mx=9 -mfb=256 -md=96m"
    Say "7z compression for Azure Pipelines: [$Global_7z_Compress_Args]" 
}

$imagesToBuild=$Images

$ProjectPath=$PSScriptRoot
$PrivateReport=$(Join-Path $ProjectPath "Private-Report")
& mkdir "-p" "$PrivateReport"
$build_folder=$OutputFolder
Say "BUILD FOLDER IS [$build_folder]"

# 1st run
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf test-and-build; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; bash build-all.sh

# next run
# cd ~/build/devizer/test-and-build; git pull; pwsh -command ./image-builder.ps1 -Images arm,i386,arm64

# sudo apt-get install sshpass sshfs libguestfs-tools qemu-system-arm qemu-system-i386 
# sudo apt-get install qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker

$featuresToInstall = $FeatureFilters | % { if (Is-Requested-Specific-Feature $_) { $_ } };
$featuresToSkip = $FeatureFilters | % { if (-not (Is-Requested-Specific-Feature $_)) { $_ } };

# $definitions | % {$globalStartParams.Port = $_.DefaultPort; Build $_ $globalStartParams;};

$cores = [Environment]::ProcessorCount;
if ($cores -ge 8) { $cores-- }
if ($cores -ge $Global_Max_VM_Cores) { $cores = $Global_Max_VM_Cores }
$globalStartParams = @{Mem="2000M"; Cores=$cores; Port=2345};

$definitions | % {Say "Defenition of the $($_.Key)"; Write-Host (Pretty-Format $_)}
Say "TOTAL PHYSICAL CORE(s): $([Environment]::ProcessorCount). Building '$imagesToBuild' using $cores core(s)"

$allTheFine = $true; 
$imagesToBuild | % {
    $nameToBuild=$_
    $definition = $definitions | where { $_.Key -eq $nameToBuild} | select -First 1
    if (-not $definition) {
        Write-Host "Unknown image '$nameToBuild'" -ForegroundColor Red;
    }
    else
    {
        $globalStartParams.Port = $definition.DefaultPort;
        $globalStartParams.Mem="$($definition.RamForBuildingMb)M"
        Write-Host "Next image:`n$(Pretty-Format $definition)" -ForegroundColor Yellow;
        $Global:BuildConsoleTitle = "|>$($definition.Key) $($globalStartParams.Mem) $($globalStartParams.Cores)*Cores {$featuresToInstall} --> $($Global_FinalSize) ===--"

        Build $definition $globalStartParams;
        $allTheFine = $allTheFine -and $Global:BuildResult.IsSccessful;
        $summaryFileName = "$PrivateReport/$($definition.Key)/summary.log"
        Say "Summary file name: $summaryFileName"

        "Summary for $($definition.Key)" > $summaryFileName
        "Total Commands:  $($Global:BuildResult.TotalCommandCount)" >> $summaryFileName
        "Failed Commands: $($Global:BuildResult.FailedCommands.Count)"   >> $summaryFileName
        "Elapsed: $(Get-Elapsed)"   >> $summaryFileName
        "" >> $summaryFileName
        @($Global:BuildResult.FailedCommands) | % {
            $_ >> $summaryFileName
        } 
        
    }
}

if (! $allTheFine)
{
    Say "A Build failed";
    throw "A Build failed";
}
