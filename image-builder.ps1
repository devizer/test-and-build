#!/usr/bin/env pwsh
param(
    [ValidateSet("i386", "arm", "arm64")]    
    [string[]] $Images,
    [string] $Only,
    [string] $Skip
)
$Global_Ignore_Features=$Skip
$Global_Only_Features=$Only


$imagesToBuild=$Images

$ProjectPath=$PSScriptRoot
$PrivateReport=$(Join-Path $ProjectPath "Private-Report")
& mkdir -p "$PrivateReport"
$build_folder="/transient-builds/test-and-build"
$FinalSize="13G"

. "$($PSScriptRoot)\include\Main.ps1"
. "$($PSScriptRoot)\include\Utilities.ps1"

$FeatureFilters=@("mono", "dotnet", "powershell", "docker", "nodejs", "local-postgres", "local-mariadb", "local-redis")
function Is-Requested-Specific-Feature{
    param([string] $idFeature)
    
    $needIgnore=$false
    if ($Global_Ignore_Features) {
        $needIgnore = " $Global_Ignore_Features " -like "* $($idFeature) *"
    }
    
    if ($needIgnore) {
        Say "Skipping. Feature ($idFeature) is configured to be ignored by -Ignore option"
        return $false; 
    }
    
    $needPreinstall=$true;
    if ($Global_Only_Features) {
        $needPreinstall = " $Global_Only_Features " -like "* $($idFeature) *"
        if (!$needPreinstall){
            Say "Skipping. Feature ($idFeature) is not specified by -Only option"
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


# port, mem and #cores are indirectly passed via $startParams
function Prepare-VM { param($definition, $rootDiskFullName, $guestNamePrefix="", $portNumber = 0)
    if (-not $portNumber) { $portNumber=$startParams.Port }
    $path=Split-Path -Path $rootDiskFullName;
    $fileName = [System.IO.Path]::GetFileName($rootDiskFullName)
    Write-Host "Copy kernel to '$($path)'"
    Copy-Item "$ProjectPath/kernels/$($definition.Key)/*" "$($path)/"
    pushd $path
    & qemu-img create -f qcow2 ephemeral.qcow2 200G
    popd

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
        $hasKvm = (& sh -c "ls /dev/kvm 2>/dev/null") | Out-String
        $guestName=if ($hasKvm) { "buster-i386-KVM" } else { "buster-i386-EMU" }
        $qemySystem="i386"
        # qemu-system-i386 --machine q35 -cpu ?
        # CPU: kvm32|SandyBridge
        $paramCpu=if ($hasKvm) { " -cpu IvyBridge " } else { " -cpu qemu32 " } 
        $kvmParameters=if ($definition.EnableKvm -and $hasKvm) {" -enable-kvm "} else {" "}
    }
    else {
        throw "Unknown definition.key = '$key'" 
    }

    if ($guestNamePrefix) { $guestName="$guestNamePrefix-$guestName" }
    $sudoPrefix=if ($hasKvm) {"sudo "} else {""};
    
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

    if ($definition.Key -eq "i386") {
        $qemuCmd = "#!/usr/bin/env bash" + @"

$($sudoPrefix)qemu-system-i386 -name $guestName -smp $($startParams.Cores) -m $($startParams.Mem) -M q35  $($kvmParameters) $paramCpu \
    -initrd initrd.img \
    -kernel vmlinuz -append "root=/dev/sda1 console=ttyS0" \
    -drive file=$($fileName) \
    -netdev user,hostfwd=tcp::$($portNumber)-:22,id=unet -device rtl8139,netdev=unet \
    -net user \
    -nographic
"@; # -drive file=ephemeral.qcow2 \
    }
    $qemuCmd > $path/start-vm.sh
    & chmod +x "$path/start-vm.sh"

    @{ Path=$path; Command="$path/start-vm.sh"; }
}

function Wait-For-Ssh {param($ip, $port, $user, $password)
    $at = [System.Diagnostics.Stopwatch]::StartNew();
    $waitForSshTimeout=5*60;
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
        if ($at.ElapsedMilliseconds -ge ($waitForSshTimeout*1000)) {
            Say "Error. SSH Connection Timeouted. Building aborted. $($at)"
            return $false;
        }
        Start-Sleep 1;
        $pingCounter++;
    } while ($true)
    
}

function Remote-Command-Raw { param($cmd, $ip, $port, $user, $password, [bool] $reconnect = $false)
    if (-not $Global:GuestLog) { $Global:GuestLog="/tmp/$([Guid]::NewGuid().ToString("N"))"}
    $rnd = "cmd-" + [System.Guid]::NewGuid().ToString("N")
    $tmpCmdLocalFullName="$mapto/tmp/$rnd"
    # next line fails on disconnected guest: DirectoryNotFoundException 
$remoteCmd = @"
#!/usr/bin/env bash
unset PS1
if [[ -d /etc/profile.d ]]; then
  for i in /etc/profile.d/*.sh; do
    if [[ -r `$i ]] && [[ ! `$i == *"bash_completion.sh"* ]]; then  
    # if [ -r `$i ]; then
      . `$i
    fi
  done
  unset i
fi

if [[ -f ~/.profile ]]; then 
    . ~/.profile
fi
# export PATH="`$PATH:/boot"
# export DEBIAN_FRONTEND=noninteractive
($cmd) 2>&1 | tee -a $($Global:GuestLog)-$($user)
"@

# Write-Host "REMOTE-SCRIPT: [$remoteCmd]"
$remoteCmd > $tmpCmdLocalFullName

    & chmod +x $tmpCmdLocalFullName
    if ($false -and $reconnect) {
        Write-Host "Temparary un-mount guest's root fs"
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
    & bash -c "$localCmd"
    & rm -f $tmpCmdLocalFullName
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
    qemu-img create -f qcow2 -o preallocation=metadata disk.intermediate.compacting.qcow2 $newSize
    # qemu-img check newdisk.qcow2
    virt-resize --expand /dev/sda1 "$($rootDiskFullName)" disk.intermediate.compacting.qcow2
    qemu-img convert -O qcow2 -c -p disk.intermediate.compacting.qcow2 "$newPath"
    Prepare-VM $definition "$newPath" "final" ($startParams.Port + 100)
    & rm -f disk.intermediate.compacting.qcow2
}

function Inplace-Enlarge
{
    param($definition, $rootDiskFullName, $newSize="32G", [bool] $needCompacting = $false)
    $dir=[System.IO.Path]::GetDirectoryName($rootDiskFullName)
    pushd "$dir"
    qemu-img create -f qcow2 -o preallocation=metadata disk.intermediate.enlarge.qcow2 $newSize
    virt-resize --expand /dev/sda1 "$($rootDiskFullName)" disk.intermediate.enlarge.qcow2
    if (!$needCompacting)
    {
        & mv -f disk.intermediate.enlarge.qcow2 "$($rootDiskFullName)"
    }
    else
    {
        qemu-img convert -O qcow2 -c -p disk.intermediate.enlarge.qcow2 disk.intermediate.enlarge.qcow2.step2
        & mv -f disk.intermediate.enlarge.qcow2.step2 $rootDiskFullName
        & rm -f disk.intermediate.enlarge.qcow2
    }
    Say "New Size of the $rootDiskFullName should be $newSize [$( $definition.Key )]"
    & virt-filesystems --all --long --uuid -h -a "$rootDiskFullName"
    popd
}

function Produce-Report {
    param($definition, $startParams, $suffix)
    $key=$definition.Key
    Say "Produce Report for [$key]"
    # & mkdir -p "$PrivateReport"
    $reportFile = "$PrivateReport/Debian-10-Buster-$key-$suffix.md"
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

    Start-Transcript -Path (Join-Path $PrivateReport "$( $definition.Key )-log.log")

    $Is_Requested_Mono = Is-Requested-Specific-Feature("mono");
    $Is_Requested_Dotnet = Is-Requested-Specific-Feature("dotnet");
    $Is_Requested_Powershell = Is-Requested-Specific-Feature("powershell");
    $Is_Requested_Docker = Is-Requested-Specific-Feature("docker");
    $Is_Requested_NodeJS = Is-Requested-Specific-Feature("nodejs");
    $Is_Requested_local_postgres = Is-Requested-Specific-Feature("local-postgres");
    $Is_Requested_Local_Mariadb = Is-Requested-Specific-Feature("local-mariadb");
    $Is_Requested_Local_Redis = Is-Requested-Specific-Feature("local-redis");

    $featuresToInstall = $FeatureFilters | % { if (Is-Requested-Specific-Feature $_) { $_ } };
    $featuresToSkip = $FeatureFilters | % { if (-not Is-Requested-Specific-Feature $_) { $_ } };
    Say "To INSTALL: [$featuresToInstall], To Skip: [$featuresToSkip]"  
    
    $key = $definition.key
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

    Say "Extracting basic image: $key"
    Write-Host "archive: $arch1";
    & mkdir -p basic-image-$key;
    pushd basic-image-$key
    & rm -rf *
    & 7z -y x $arch1
    # & bash -c 'rm -f *.7z.*'
    $qcowFile = join-Path -Path "." -ChildPath "*$( $definition.RootQcow )*" -Resolve
    popd

    Say "Basic Image for $key exctracted: $qcowFile";
    & virt-filesystems --all --long --uuid -h -a "$qcowFile"

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
    $process = [System.Diagnostics.Process]::Start($si)
    $isExited = $process.WaitForExit(7000)

    $isOnline = Wait-For-Ssh "localhost" $startParams.Port "root" "pass"
    if (! $isOnline)
    {
        return $false;
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

    Say "Configure LC_ALL, UTC and optionally swap"
    Remote-Command-Raw "bash /tmp/build/config-system.sh $key $( $definition.SwapMb )" "localhost" $startParams.Port "root" "pass" $true # re-connect
    
    Produce-Report $definition $startParams "onstart"
    
    Say "Greetings from Guest [$key]"
    $cmd = 'Say "Hello from $(whoami). I am the $(hostname) host"; sudo lscpu; echo [PATH] is: $PATH; echo "Content of /etc/default/locale:"; cat /etc/default/locale; echo "[env]"; printenv | sort'
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "pass"
    Remote-Command-Raw $cmd "localhost" $startParams.Port "user" "pass"

    $mustHavePackages = "lazy-apt-update; apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y && apt-get clean"
    Say "Installing must have packages on [$key]"
    Remote-Command-Raw "$mustHavePackages" "localhost" $startParams.Port "root" "pass"

    if ($Is_Requested_Mono)
    {
        Say "Installing Latest Mono [$key]"
        Remote-Command-Raw "cd /tmp/build; bash -e install-MONO.sh" "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; mono --version; msbuild /version; echo ""; nuget >.tmp; cat .tmp | head -4' "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; mono --version; msbuild /version; echo ""; nuget >.tmp; cat .tmp | head -4' "localhost" $startParams.Port "user" "pass"

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
        Say "Installing DotNet Core on [$key]"
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
        Say "Install Docker [$key]"
        Remote-Command-Raw "cd /tmp/build; bash Install-DOCKER.sh;" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_local_postgres)
    {
        Say "Install Local Postgres SQL [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-POSTGRES.sh;" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_Local_Mariadb)
    {
        Say "Install Local MariaDB [$key]"
        Remote-Command-Raw "cd /tmp/build; bash Install-MARIADB.sh;" "localhost" $startParams.Port "root" "pass"
    }

    if ($Is_Requested_Local_Redis)
    {
        Say "Install Local Redis Server [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-REDIS.sh;" "localhost" $startParams.Port "root" "pass"
    }


    # if ($Env:INSTALL_NODE_FOR_i386 -eq "True" -or $key -ne "i386")
    if ($Is_Requested_NodeJS)
    {
        Say "Installing Node [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-NODE.sh" "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "user" "pass"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "root" "pass"
    }
<#
    else {
        Say "Skipping NodeJS on i386"
    }
#>


    if ($true)
    {
        Say "Installing a Crap [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-a-crap.sh" "localhost" $startParams.Port "root" "pass"
    }

    Produce-Report $definition $startParams "onfinish"

    Say "Store Guest Logs"
    & cp -f "$mapto/$($Global:GuestLog)-user" "$PrivateReport/$key-guest-user.log"
    & cp -f "$mapto/$($Global:GuestLog)-root" "$PrivateReport/$key-guest-root.log"
    pushd "$mapto/tmp"
    & cp -f Said-by-root.log $PrivateReport/$key-said-by-root.log
    & cp -f Said-by-user.log $PrivateReport/$key-said-by-user.log
    popd
    
    pushd "$mapto"
    & rm -f $PrivateReport/$key-user-profile.7z
    & 7z a $PrivateReport/$key-user-profile.7z etc/profile.d home/user
    popd

    Say "Zeroing free space of [$key]"
    Remote-Command-Raw "cd /; bash /tmp/build/TearDown.sh; before-compact" "localhost" $startParams.Port "root" "pass"

    # Say "Dismounting guest's share of [$key]"
    # & umount -f $mapto # NOOOO shutdown?????

    Say "SHUTDOWN [$key] GUEST"
    Remote-Command-Raw "rm -rf /tmp/build; Say 'Size of the /tmp again:'; du /tmp -d 1 -h; sudo shutdown now" "localhost" $startParams.Port "root" "pass"
    Wait-For-Process $process $key

    Say "Final compact [$key]"
    & mkdir -p "final-$key"
    pushd "final-$key"
    & rm -rf *
    $finalQcow = "$(pwd)/debian-$key-final.qcow2"
    $finalQcowPath = "$(pwd)"

    
    Final-Compact $definition "$qcowFile" "$finalSize" $finalQcow 
    popd

    Say "Final Image for [$key]: $finalQcow";
    & virt-filesystems --all --long --uuid -h -a "$finalQcow"

    Say "Splitting final image for publication [$key]: $qcowFile";
    & mkdir -p "final-$key-splitted"
    & pushd "final-$key-splitted"
    & rm -rf *
    $finalArchive = "$(pwd)/debian-$key-final.qcow2.7z"
    $finalArchivePath = "$(pwd)"
    popd
    pushd $finalQcowPath
    & 7z a -t7z -mx=1 -mfb=32 -md=4m -v42m "$finalArchive" "."
    popd
    pushd $finalArchivePath
    & ls -la
    popd

    Say "The End"
    popd
    Stop-Transcript

}

# $definitions | % {$globalStartParams.Port = $_.DefaultPort; Build $_ $globalStartParams;};

$cores = [Environment]::ProcessorCount;
if ($cores -ge 8) { $cores-- }
if ($cores -ge 4) { $cores=4 }
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
        $Global:BuildConsoleTitle = "|>$($definition.Key) $($globalStartParams.Mem) $($globalStartParams.Cores)*Cores ===--"
        $isBuildSuccess = Build $definition $globalStartParams;
        $allTheFine = $allTheFine -and $isBuildSuccess; 
    }
}

if (! $allTheFine)
{
    Say "A Build failed";
    throw "A Build failed";
}
