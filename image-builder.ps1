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



$FeatureFilters=@("mono", "dotnet", "powershell", "docker", "local-postgres", "local-mariadb", "local-redis", "nodejs")
function Is-Requested-Specific-Feature{
    param([string] $idFeature)
    
    $needIgnore=$false
    if ($Global_Ignore_Features) {
        $needIgnore = " $Global_Ignore_Features " -like "* $($idFeature) *"
    }
    
    if ($needIgnore) {
        # Say "Skipping. Feature ($idFeature) is configured to be ignored by -Ignore option"
        return $false; 
    }
    
    $needPreinstall=$true;
    if ($Global_Only_Features) {
        $needPreinstall = " $Global_Only_Features " -like "* $($idFeature) *"
        if (!$needPreinstall){
            # Say "Skipping. Feature ($idFeature) is not specified by -Only option"
            return $false
        }
    }
    $true
}


# 1st run
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf test-and-build; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; bash build-all.sh

# next run
# cd ~/build/devizer/test-and-build; git pull; pwsh -command ./image-builder.ps1 -Images arm,i386,arm64

# sudo apt-get install sshpass sshfs libguestfs-tools qemu-system-arm qemu-system-i386 
# sudo apt-get install qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker

$featuresToInstall = $FeatureFilters | % { if (Is-Requested-Specific-Feature $_) { $_ } };
$featuresToSkip = $FeatureFilters | % { if (-not (Is-Requested-Specific-Feature $_)) { $_ } };

# port, mem and #cores are indirectly passed via $startParams
function Prepare-VM { param($definition, $rootDiskFullName, $guestNamePrefix="", $portNumber = 0)
    if (-not $portNumber) { $portNumber=$startParams.Port }
    $path=Split-Path -Path $rootDiskFullName;
    $fileName = [System.IO.Path]::GetFileName($rootDiskFullName)
    Write-Host "Copy kernel to '$($path)'"
    Copy-Item "$ProjectPath/kernels/$($definition.Key)/*" "$($path)/"

    # on 18.04 virt-format without defrag produces 1Gb file, on 19.10 - 30Mb 
    pushd $path
    & qemu-img create -f qcow2 ephemeral.temp.qcow2 200G
    & virt-format --partition=mbr --filesystem=ext4 -a ephemeral.temp.qcow2
    & qemu-img convert -O qcow2 -c ephemeral.temp.qcow2 ephemeral.qcow2 
    & rm -f ephemeral.temp.qcow2
    popd

    $hasKvm = (& sh -c "ls /dev/kvm 2>/dev/null") | Out-String
    if ($key -eq "arm") {
        $guestName="buster-arm-v7"
        $qemySystem="arm"
        $paramCpu=""
    }
    elseif ($key -eq "arm64") {
        $guestName="buster-arm-64"
        $qemySystem="aarch64"
        $paramCpu=" -cpu cortex-a57 "
    }
    elseif ($key -eq "i386") {
        $guestName=if ($hasKvm) { "buster-i386-KVM" } else { "buster-i386-EMU" }
        $qemySystem="i386"
        # qemu-system-i386 --machine q35 -cpu ?
        # CPU: kvm32|SandyBridge
        $kvmCpu=if ($definition.NeedSSE4) {"SandyBridge"} else {"kvm32"}
        $paramCpu=if ($hasKvm) { " -cpu $kvmCpu " } else { " -cpu qemu32 " }
        $kvmParameters=if ($definition.EnableKvm -and $hasKvm) {" -enable-kvm "} else {" "}
    }
    elseif ($key -eq "AMD64") {
        $guestName=if ($hasKvm) { "buster-AMD64-KVM" } else { "buster-AMD64-EMU" }
        $qemySystem="x86_64"
        # qemu-system-i386 --machine q35 -cpu ?
        # CPU: kvm64|SandyBridge
        $kvmCpu=if ($definition.NeedSSE4) {"SandyBridge"} else {"kvm64"}
        $paramCpu=if ($hasKvm) { " -cpu $kvmCpu " } else { " -cpu qemu64 " }
        $kvmParameters=if ($definition.EnableKvm -and $hasKvm) {" -enable-kvm "} else {" "}
    }
    else {
        throw "Unknown definition.key = '$key'" 
    }

    if ($guestNamePrefix) { $guestName="$guestNamePrefix-$guestName" }
    $sudoPrefix=if ($hasKvm -and ($definition.EnableKvm)) {"sudo "} else {""};
    
    # $p1="arm"; $k=$definition.Key; if ($k -eq "arm64") {$p1="aarch64";} elseif ($k -eq "i386") {$p1="i386";}
    # $p2 = if ($k -eq "arm64") { " -cpu cortex-a57 "; } else {""};


$qemuCmd = "#!/usr/bin/env bash" + @" 

qemu-system-${qemySystem} -name $guestName \
    -smp $($startParams.Cores) -m $($startParams.Mem) -M virt ${paramCpu} \
    -initrd initrd.img \
    -kernel vmlinuz \
    -append 'root=/dev/sda1 console=ttyAMA0' \
    -global virtio-blk-device.scsi=off \
    -device virtio-scsi-device,id=scsi \
    -drive file=$($fileName),id=rootimg,cache=unsafe,if=none -device scsi-hd,drive=rootimg \
    -drive file=ephemeral.qcow2,id=ephemeral,cache=unsafe,if=none -device scsi-hd,drive=ephemeral \
    -netdev user,hostfwd=tcp::$($portNumber)-:22,id=net0 -device virtio-net-device,netdev=net0 \
    -nographic
"@;  

    if ($definition.Key -eq "i386" -or $definition.Key -eq "AMD64") {
        $qemuCmd = "#!/usr/bin/env bash" + @"

#-device rtl8139 and e1000 are not stable
$($sudoPrefix)qemu-system-${qemySystem} -name $guestName -smp $($startParams.Cores) -m $($startParams.Mem) -M q35  $($kvmParameters) $paramCpu \
    -initrd initrd.img \
    -kernel vmlinuz -append "root=/dev/sda1 console=ttyS0" \
    -drive file=$($fileName),id=rootimg \
    -drive file=ephemeral.qcow2,id=ephemeral \
    -netdev user,hostfwd=tcp::$($portNumber)-:22,id=unet -device e1000-82545em,netdev=unet \
    -net user \
    -nographic
"@; # -drive file=ephemeral.qcow2 cache=unsafe \
    }
    $qemuCmd > $path/start-vm.sh
    & chmod +x "$path/start-vm.sh"

    @{ Path=$path; Command="$path/start-vm.sh"; }
}

function Wait-For-Ssh {param($ip, $port, $user, $password)
    $at = [System.Diagnostics.Stopwatch]::StartNew();
    $pingCounter = 1;
    do
    {
        Write-Host "#$($pingCounter): Waiting for ssh connection to $($ip):$($port) ... " -ForegroundColor Gray
        # $sshCmd="sshpass -p $($password) ssh -o StrictHostKeyChecking=no $($user)@$($ip) -p $($port) hostname"
        & sshpass "-p" "$($password)" "ssh" "-o" "StrictHostKeyChecking no" "$($user)@$($ip)" "-p" "$($port)" "hostname"
        if ($?)
        {
            Write-Host "SSH on $($ip):$($port) is online" -ForegroundColor Green
            return $true;
        }
        if ($at.ElapsedMilliseconds -ge ($Global_SSH_Timeout*1000)) {
            Say "Error. SSH Connection Timeouted. Building aborted. Guest pid #$($Global:qemuProcess) should be killed. $($at.Elapled)"
            & sudo kill "-SIGTERM" "$($Global:qemuProcess)"
            $Global:BuildResult.TotalCommandCount++; 
            $Global:BuildResult.FailedCommands += "SSH connection timed out: $($at.Elapled)";
            $Global:BuildResult.IsSccessful=$false;
            return $false;
        }
        Start-Sleep 1;
        $pingCounter++;
    } while ($true)
    
}

function Remote-Command-Raw { param($cmd, $ip, $port, $user, $password, [bool] $reconnect = $false, [bool] $destructive = $false)
    if (-not $Global:GuestLog) { $Global:GuestLog="/tmp/$([Guid]::NewGuid().ToString("N"))"}
    $rnd = "cmd-" + [System.Guid]::NewGuid().ToString("N")
    $tmpCmdLocalFullName="$mapto/tmp/$rnd"
    $cmd_Colorless=if ($ENV:BUILD_DEFINITIONNAME) {"export SAY_COLORLESS=true"} else {""};
    # next line fails on disconnected guest: DirectoryNotFoundException 
$remoteCmd = "#!/usr/bin/env bash`n$cmd_Colorless`n" + @"
unset PS1
if [[ -d /etc/profile.d ]]; then
  for i in /etc/profile.d/*.sh; do
    if [[ -r `$i ]] && [[ ! `$i == *"bash_completion.sh"* ]]; then  
     . `$i
    fi
  done
  unset i
fi

if false && [[ -f ~/.profile ]]; then 
    . ~/.profile
fi
# export PATH="`$PATH:/boot"
export DEBIAN_FRONTEND=noninteractive
($cmd) 2>&1 | tee -a "$($Global:GuestLog)-$($user)"
"@

    Write-Host "REMOTE-SCRIPT: `n[$remoteCmd]"
    
    try { $remoteCmd > $tmpCmdLocalFullName; $errorInfo = $null; }
    catch { $errorInfo = "Fail store command as the $($tmpCmdLocalFullName) file: $($_.Exception)" }

    & chmod +x $tmpCmdLocalFullName
    if ($false -and $reconnect) {
        Write-Host "Temparary un-mount guest root fs"
        & umount -f $mapto        
    }
    $localCmd="sshpass -p `'$($password)`' ssh -o 'StrictHostKeyChecking no' $($user)@$($ip) -p $($port) /tmp/$rnd"
    if ($false -and $reconnect) {
        $mountCmd = "echo pass | sshfs -o password_stdin 'root@localhost:/' -p $( $startParams.Port ) '$mapto'"
        Write-Host "RE-Mount command: [$mountCmd]"
        & bash -c "$mountCmd"
        & ls -la $mapto
    }
    Write-Host "#: $cmd"
    if ($errorInfo -eq $null) {
        & bash -c "$localCmd"
        $isExitOk = $?;
        $isExitOkInfo=if ($isExitOk) {"OK"} else {"ERR"}
        $destructiveInfo=if ($destructive) {" DESTRUCTIVE!"} else {""}
        Write-Host "$($isExitOkInfo):$($destructiveInfo) [$cmd]" 
        if ((-not $isExitOk) -and (-not $destructive)) { $errorInfo = "Failed to execute remote command: [$cmd]" }
        else {
            & rm -f $tmpCmdLocalFullName
            if (-not $? -and (-not $destructive)) { $errorInfo = "Failed to clean up remote command: [$cmd]" }
        }
    }

    $Global:BuildResult.TotalCommandCount++;
    
    if ($errorInfo) {
        $Global:BuildResult.FailedCommands += "#: $cmd`n$errorInfo";
        $Global:BuildResult.IsSccessful=$false;
    }
}

function Wait-For-Process
{
    param($process, $name)
    Say "Waiting for shutdown of [$key]"
    $process.WaitForExit()
    Say "[$key] VM gracefully powered off"
}

function Final-Compact
{
    param($definition, $rootDiskFullName, $newSize="32G", $newPath)
    if ($newSize -and ($newSize -ne "0"))
    {
        # qemu-img create -f qcow2 -o preallocation=metadata disk.intermediate.compacting.qcow2 $newSize
        qemu-img create -f qcow2                             disk.intermediate.compacting.qcow2 $newSize
        # qemu-img check newdisk.qcow2
        & nice "$Global_ExpandDisk_Priority" virt-resize --expand /dev/sda1 "$( $rootDiskFullName )" disk.intermediate.compacting.qcow2
        & nice "$Global_7z_Compress_Priority" qemu-img convert -O qcow2 -c -p disk.intermediate.compacting.qcow2 "$newPath"
        & rm -f disk.intermediate.compacting.qcow2
    }
    else {
        Say "Skip expanding. Just converting $rootDiskFullName --> $newPath with compression"
        & nice "$Global_7z_Compress_Priority" qemu-img convert -O qcow2 -c -p "$rootDiskFullName" "$newPath"
    }
    Prepare-VM $definition "$newPath" "final" ($startParams.Port + 100)
}

function Inplace-Enlarge
{
    param($definition, $rootDiskFullName, $newSize="32G", [bool] $needCompacting = $false)
    $dir=[System.IO.Path]::GetDirectoryName($rootDiskFullName)
    pushd "$dir"
    qemu-img create -f qcow2 -o preallocation=metadata disk.intermediate.enlarge.qcow2 $newSize
    & nice "$Global_ExpandDisk_Priority" virt-resize --expand /dev/sda1 "$($rootDiskFullName)" disk.intermediate.enlarge.qcow2
    if (!$needCompacting)
    {
        & mv -f disk.intermediate.enlarge.qcow2 "$($rootDiskFullName)"
    }
    else
    {
        & nice "$Global_7z_Compress_Priority" qemu-img convert -O qcow2 -c -p disk.intermediate.enlarge.qcow2 disk.intermediate.enlarge.qcow2.step2
        & mv -f disk.intermediate.enlarge.qcow2.step2 $rootDiskFullName
        & rm -f disk.intermediate.enlarge.qcow2
    }
    Say "New Size of the $rootDiskFullName should be $newSize [$( $definition.Key )]"
    & nice "$Global_ExpandDisk_Priority" virt-filesystems --all --long --uuid -h -a "$rootDiskFullName"
    popd
}

function Produce-Report {
    param($definition, $startParams, $suffix)
    $key=$definition.Key
    Say "Produce Report for [$key]"
    # & mkdir -p "$PrivateReport"
    $reportFile = "$PrivateReport/$key/Debian-10-Buster-$key-$suffix.md"
    "|  Debian 10 Buster <u>**$($key)**</u> |`n|-------|" > $reportFile

    $probes | % { $probe=$_; $cmd = $_.Cmd;
        $responseFile="/tmp/response-$(([Guid]::NewGuid()).ToString("N"))"
        # Write-Host "Port: $($startParams.Port)" 
        Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "pass" > $responseFile 2>&1
        $response=Get-Content $responseFile -Raw
        Write-Host "Response for [$cmd]:`n$($response)"
        $title = $probe.Cmd; if ($probe.Name) { $title=$probe.Name } 
        "| $title |" >> $reportFile
        # "| $response |" >> $reportFile
        Output-To-Markdown $response $probe >> $reportFile
        & rm -f "$responseFile" 
    }
}
    

function Build
{
    param($definition, $startParams)
    $key = $definition.key

    & mkdir -p $PrivateReport/$key
    & rm -rf "$PrivateReport/$key/*"

    $Global:BuildResult = new-object PSObject -Property @{
        IsSccessful=$true;
        FailedCommands=@();
        TotalCommandCount=0;
    };

    Start-Transcript -Path (Join-Path $PrivateReport $key "$( $definition.Key )-log.log")

    $Is_Requested_Mono = Is-Requested-Specific-Feature("mono");
    $Is_Requested_Dotnet = Is-Requested-Specific-Feature("dotnet");
    $Is_Requested_Powershell = Is-Requested-Specific-Feature("powershell");
    $Is_Requested_Docker = Is-Requested-Specific-Feature("docker");
    $Is_Requested_NodeJS = Is-Requested-Specific-Feature("nodejs");
    $Is_Requested_local_postgres = Is-Requested-Specific-Feature("local-postgres");
    $Is_Requested_Local_Mariadb = Is-Requested-Specific-Feature("local-mariadb");
    $Is_Requested_Local_Redis = Is-Requested-Specific-Feature("local-redis");
    $Is_IgnoreAll=($Global_Only_Features -eq "Nothing");

    Say "Building $( $definition.key )";
    New-Item -Type Directory $build_folder -ea SilentlyContinue;
    pushd $build_folder

    Say "Downloading basic image: $key"
    $download_cmd = "curl $( $definition.BaseUrl )debian-$( $definition.Key ).qcow2.7z.00[1-$( $definition.BasicParts )] -o 'debian-$( $definition.Key ).qcow2.7z.00#1'";
    Write-Host "shell command: [$download_cmd]";
    & mkdir -p downloads-$key;
    pushd downloads-$key
    & bash -c $download_cmd
    $arch1 = join-Path -Path "." -ChildPath "*.001" -Resolve
    popd

    Say "To INSTALL: $(@($featuresToInstall).Count) [$featuresToInstall], To Skip: $(@($featuresToSkip).Count) [$featuresToSkip]"
    Say "Extracting basic image: $key"
    Write-Host "archive: $arch1";
    & mkdir -p basic-image-$key;
    pushd basic-image-$key
    & rm -rf *
    & nice "$Global_7z_DeCompress_Priority" 7z -y x $arch1
    # & bash -c 'rm -f *.7z.*'
    $qcowFile = join-Path -Path "." -ChildPath "*$( $definition.RootQcow )*" -Resolve
    popd

    Say "Basic Image for $key exctracted: $qcowFile ($(Get-File-Size-Info $qcowFile))";
    & nice "$Global_ExpandDisk_Priority" virt-filesystems --all --long --uuid -h -a "$qcowFile"
    & df -T -h
    Say "Done: Basic Image for $key exctracted: $qcowFile ($(Get-File-Size-Info $qcowFile))";

    if ($definition.SizeForBuildingMb)
    {
        Say "Increase Image Size to $( $definition.SizeForBuildingMb ) Mb"
        Inplace-Enlarge $definition "$qcowFile" "$( $definition.SizeForBuildingMb )M" $false # true - to compact intermediate image
    }

    Say "Prepare Image and launch: $key"
    $preparedVm = Prepare-VM $definition $qcowFile "building"
    Write-Host "Command prepared: [$( $preparedVm.Command )]"

    $si = new-object System.Diagnostics.ProcessStartInfo($preparedVm.Command, "")
    $si.UseShellExecute = $false
    $si.WorkingDirectory = $preparedVm.Path
    $Global:qemuProcess = [System.Diagnostics.Process]::Start($si)
    $isExited = $Global:qemuProcess.WaitForExit(7000)

    $isOnline = Wait-For-Ssh "localhost" $startParams.Port "root" "pass"
    if (! $isOnline)
    {
        $Global:IsBuildSuccess=$false;
        return;
    }

    Say "Mapping guest FS to localfs"
    $mapto = "$build_folder/rootfs-$( $key )"
    Write-Host "Mapping Folder is [$mapto]";
    & mkdir -p "$mapto"
    $mountCmd = "echo pass | sshfs -o password_stdin 'root@localhost:/' -p $( $startParams.Port ) '$mapto'"
    Write-Host "Mount command: [$mountCmd]"
    & bash -c "$mountCmd"
    & ls -la "$mapto"

    Say "Copying ./lab/ to guest for [$key]"
    # Remote-Command-Raw 'mkdir -p /tmp/build' "localhost" $startParams.Port "root" "pass"
    & mkdir -p $mapto/tmp/build
    & cp -a $ProjectPath/lab/* $mapto/tmp/build

    Say "Configure SSH for [$key]"
    Remote-Command-Raw "cd /tmp/build; bash config-ssh.sh $key" "localhost" $startParams.Port "root" "pass" $true # re-connect

    Say "RESTART SSH for [$key]"
    Remote-Command-Raw 'sshId="$(pgrep -f "sshd -D")"; Say "Restarting SSH Server (pid is $sshId)"; sudo kill -SIGHUP "$(pgrep -f "sshd -D")"; Say "Restarted SSH Server";' "localhost" $startParams.Port "root" "pass" $false $true # destructive

    Say "Configure LC_ALL, UTC and optionally swap for [$key]"
    Remote-Command-Raw "cd /tmp/build; bash config-system.sh $( $definition.SwapMb )" "localhost" $startParams.Port "root" "pass" $true # re-connect

    if (!$Is_IgnoreAll)
    {
        Say "Upgrading to the latest Debian for [$key]"
        Remote-Command-Raw 'cd /tmp/build; bash dist-upgrade.sh' "localhost" $startParams.Port "root" "pass"
    }

    # Produce-Report $definition $startParams "onstart"
    
    Say "Greetings from Guest [$key]"
    $cmd = 'Say "Hello from $(whoami). I am the $(hostname) host"; sudo lscpu; echo [PATH] is: $PATH; echo "Content of /etc/default/locale:"; cat /etc/default/locale; echo "[env]"; printenv | sort'
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "pass"
    Remote-Command-Raw $cmd "localhost" $startParams.Port "user" "pass"

    if (!$Is_IgnoreAll)
    {
        $mustHavePackages = "smart-apt-install apt-transport-https ca-certificates curl gnupg2 software-properties-common htop mc lsof unzip net-tools bsdutils; apt-get clean"
        Say "Installing must have packages on [$key]"
        Remote-Command-Raw "$mustHavePackages" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_Mono)
    {
        Say "Installing Latest Mono [$key]"
        Remote-Command-Raw "cd /tmp/build; bash -e install-MONO.sh" "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; mono --version; msbuild /version; echo ""; nuget >/tmp/.tmp; cat /tmp/.tmp | head -4; rm /tmp/.tmp' "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; mono --version; msbuild /version; echo ""; nuget >/tmp/.tmp; cat /tmp/.tmp | head -4; rm /tmp/.tmp' "localhost" $startParams.Port "user" "pass"

        Say "Building NET-TEST-RUNNERS on the host and installing to the guest"
        pushd "$ProjectPath/lab"; & bash NET-TEST-RUNNERS-build.sh; popd
        Say "Copying NET-TEST-RUNNERS to /opt/NET-TEST-RUNNERS on the guest"
        & cp -a ~/build/devizer/NET-TEST-RUNNERS "$mapto/opt"
        Say "Linking NET-TEST-RUNNERS on the guest"
        Remote-Command-Raw "bash /opt/NET-TEST-RUNNERS/link-unit-test-runners.sh" "localhost" $startParams.Port "root" "pass"

        Say "Run .net tests on guest [$key]"
        Remote-Command-Raw "cd /tmp/build; bash -e run-NET-UNIT-TESTS.sh" "localhost" $startParams.Port "root" "pass"
    }



    if ($Is_Requested_Dotnet)
    {
        Say "Installing DotNet Core for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-DOTNET.sh; command -v dotnet && dotnet --info || true" "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; dotnet --info' "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; dotnet --info' "localhost" $startParams.Port "user" "pass"
        # TODO: Add dotnet restore
    }

    if ($Is_Requested_Powershell)
    {
        Say "Installing Powershell for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash -e install-POWERSHELL.sh" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_Docker)
    {
        Say "Install Docker for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash Install-DOCKER.sh;" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_local_postgres)
    {
        Say "Install Local Postgres SQL for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-POSTGRES.sh;" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_Local_Mariadb)
    {
        Say "Install Local MariaDB for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-MARIADB.sh;" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_Local_Redis)
    {
        Say "Install Local Redis Server for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-REDIS.sh;" "localhost" $startParams.Port "root" "pass"
    }


    # if ($Env:INSTALL_NODE_FOR_i386 -eq "True" -or $key -ne "i386")
    if ($Is_Requested_NodeJS)
    {
        Say "Installing Node for [$key]"
        Remote-Command-Raw 'cd /tmp/build; export TRAVIS="$TRAVIS"; bash install-NODE.sh' "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "user" "pass"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "root" "pass"
    }
<#
    else {
        Say "Skipping NodeJS on i386"
    }
#>


    if (!$Is_IgnoreAll)
    {
        Say "Installing a Crap for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-a-crap.sh" "localhost" $startParams.Port "root" "pass"
    }

    Say "Log Packages for [$key]"
    Remote-Command-Raw 'Say "PACKAGES:\n$(list-packages)"' "localhost" $startParams.Port "root" "pass"

    Say "Store list-packages"
    $installedPackagesFileName="installed-packages-$key.txt"
    $cmd='list-packages | cut -c 12- | sort > /tmp/' + $installedPackagesFileName
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "pass"
    

    Produce-Report $definition $startParams "onfinish"

    Say "Store Guest Logs"
    & cp -f "$mapto/$($Global:GuestLog)-user" "$PrivateReport/$key/$key-guest-user.log"
    & cp -f "$mapto/$($Global:GuestLog)-root" "$PrivateReport/$key/$key-guest-root.log"
    pushd "$mapto/tmp"
    & cp -f Said-by-root.log $PrivateReport/$key/$key-said-by-root.log
    & cp -f Said-by-user.log $PrivateReport/$key/$key-said-by-user.log
    & cp -f "$installedPackagesFileName" "$PrivateReport/$key/$installedPackagesFileName"
    popd
    
    
    pushd "$mapto"
    & rm -f $PrivateReport/$key/$key-user-profile.7z
    & 7z -mmt1 a  $PrivateReport/$key/$key-user-profile.7z etc/profile.d home/user usr/local/bin
    popd

    Say "Zeroing free space of [$key]"
    Remote-Command-Raw "cd /; bash /tmp/build/TearDown.sh; apt clean; before-compact" "localhost" $startParams.Port "root" "pass" $false $true

    # Say "Dismounting guest's share of [$key]"
    # & umount -f $mapto # NOOOO shutdown?????

    Say "SHUTDOWN [$key] GUEST"
    Remote-Command-Raw "rm -rf /tmp/build; Say 'Size of the /tmp again:'; du /tmp -d 1 -h; sudo shutdown now" "localhost" $startParams.Port "root" "pass" $false $true
    Wait-For-Process $Global:qemuProcess $key

    Say "Final compact [$key]"
    & mkdir -p "final-$key"
    pushd "final-$key"
    & rm -rf *
    $finalQcow = "$(pwd)/debian-$key-final.qcow2"
    $finalQcowPath = "$(pwd)"

    # $Env:LIBGUESTFS_DEBUG="1"; $Env:LIBGUESTFS_TRACE="1" # WTH?
    Final-Compact $definition "$qcowFile" "$Global_FinalSize" $finalQcow 
    popd

    Say "Final Image for [$key]: $finalQcow";
    & nice "$Global_ExpandDisk_Priority" virt-filesystems --all --long --uuid -h -a "$finalQcow"

    Say "Splitting final image for publication [$key]: $finalQcow ($(Get-File-Size-Info $finalQcow))";
    & mkdir -p "final-$key-splitted"
    & pushd "final-$key-splitted"
    & rm -rf *
    & cp "$PrivateReport/$key/$installedPackagesFileName" "$installedPackagesFileName"
    $finalArchive = "$(pwd)/debian-$key-final.qcow2.7z"
    $finalArchivePath = "$(pwd)"
    popd
    pushd $finalQcowPath
    & nice "$Global_7z_Compress_Priority" 7z a -t7z "-mmt$Global_7z_Threads" $Global_7z_Compress_Args.Split([char]32) -v249m "$finalArchive" "."
    Say "The Final archive content with compresion ratio [$finalArchive]"
    & 7z l "$($finalArchive).001"
    popd
    pushd $finalArchivePath
    & ls -la
    popd

    Say "The End"
    popd
    Stop-Transcript
    $Global:IsBuildSuccess=$true;
}

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
