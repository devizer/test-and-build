#!/usr/bin/env pwsh

# 1st run
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf test-and-build; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; pwsh image-builder.ps1

# next run
# cd ~/build/devizer/test-and-build; git pull; pwsh image-builder.ps1

# sudo apt-get install sshpass sshfs libguestfs-tools qemu-system-arm qemu-system-i386 
# sudo apt-get install qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker

$build_folder="/transient-builds/test-and-build"
$ScriptPath=(pwd).Path

$definitions=@(
@{
    key="i386"; BasicParts=5; RootQcow="debian-i386.qcow2"
    DefaultPort=2344;
    ExpandTargetSize="5000M";
    EnableKvm=$true;
    SwapMb=256;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$ScriptPath/basic-images/"
},
@{
    key="arm64"; BasicParts=5; RootQcow="disk.arm64.qcow2.raw";
    DefaultPort=2346;
    ExpandTargetSize="5000M";
    SwapMb=32;
    # BaseUrl="file:///github.com/"
    BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
},
@{
    key="arm"; BasicParts=5; RootQcow="disk.expanded.qcow2.raw"
    # BaseUrl="file:///github.com/"
    DefaultPort=2347;
    SwapMb=32;
    BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/";
}
);
# temprarily we build only ARM-64
$definitions=@($definitions[2]);

function Say
{
    param([string] $message)
    Write-Host "$( Get-Elapsed ) " -NoNewline -ForegroundColor Magenta
    Write-Host "$message" -ForegroundColor Yellow
}

function Get-Elapsed
{
    if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
    [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("mm:ss"), "]");
}; Get-Elapsed | out-null;


function Prepare-VM { param($definition, $rootDiskFullName)
    $path=Split-Path -Path $rootDiskFullName;
    $fileName = [System.IO.Path]::GetFileName($rootDiskFullName)
    Write-Host "Copy kernel to '$($path)'"
    Copy-Item "$ScriptPath/kernels/$($definition.Key)/*" "$($path)/"
    pushd $path
    & qemu-img create -f qcow2 ephemeral.qcow2 200G
    popd
    
    $p1="arm"; $k=$definition.Key; if ($k -eq "arm64") {$p1="aarch64";} elseif ($k -eq "i386") {$p1="i386";}
    $p2 = if ($k -eq "arm64") { " -cpu cortex-a57 "; } else {""};

    $hasKvm = (& sh -c "ls /dev/kvm 2>/dev/null") | Out-String

$qemuCmd = "#!/usr/bin/env bash" + @" 

qemu-system-${p1} \
    -smp $($startParams.Cores) -m $($startParams.Mem) -M virt ${p2} \
    -initrd initrd.img \
    -kernel vmlinuz \
    -append 'root=/dev/sda1 console=ttyAMA0' \
    -global virtio-blk-device.scsi=off \
    -device virtio-scsi-device,id=scsi \
    -drive file=$($fileName),id=rootimg,cache=unsafe,if=none -device scsi-hd,drive=rootimg \
    -drive file=ephemeral.qcow2,id=ephemeral,cache=unsafe,if=none -device scsi-hd,drive=ephemeral \
    -netdev user,hostfwd=tcp::$($startParams.Port)-:22,id=net0 -device virtio-net-device,netdev=net0 \
    -nographic
"@;  

    if ($definition.Key -eq "i386") {
        # qemu-system-i386 --machine q35 -cpu ?
        $cpu="IvyBridge" # kvm32|IvyBridge
        $kvmParameters=if ($definition.EnableKvm -and $hasKvm) {" -enable-kvm -cpu $($cpu) "} else {" -cpu $($cpu) "}
        $qemuCmd = "#!/usr/bin/env bash" + @"

qemu-system-i386 -smp $($startParams.Cores) -m $($startParams.Mem) -M q35 $($kvmParameters) \
    -initrd initrd.img \
    -kernel vmlinuz -append "root=/dev/sda1 console=ttyS0" \
    -drive file=$($fileName) \
    -netdev user,hostfwd=tcp::$($startParams.Port)-:22,id=unet -device rtl8139,netdev=unet \
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
    $pingCounter = 0;
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
        Start-Sleep 1;
        $pingCounter++;
    } while ($true)
    
}

function Remote-Command-Raw { param($cmd, $ip, $port, $user, $password)
    $rnd = "cmd-" + [System.Guid]::NewGuid().ToString("N")
    $tmpCmdLocalFullName="$mapto/tmp/$rnd"
    "#!/usr/bin/env bash`nsource ~/.bashrc`n$cmd" > $tmpCmdLocalFullName
    Write-Host "Content of temp bash script"
    & cat $tmpCmdLocalFullName
    & chmod +x $tmpCmdLocalFullName
    $localCmd="sshpass -p `'$($password)`' ssh -o 'StrictHostKeyChecking no' $($user)@$($ip) -p $($port) /tmp/$rnd"
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
    Prepare-VM $definition "$newPath"
    & rm -f disk.intermediate.compacting.qcow2 
}

function Build { param($definition, $startParams)
    $key=$definition.key
    Say "Building $($definition.key)";
    New-Item -Type Directory $build_folder -ea SilentlyContinue;
    pushd $build_folder

    Say "Downloading basic image: $key"
    $download_cmd="curl $($definition.BaseUrl)debian-$($definition.Key).qcow2.7z.00[1-$($definition.BasicParts)] -o 'debian-$($definition.Key).qcow2.7z.00#1'";
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
    $qcowFile = join-Path -Path "." -ChildPath "*$($definition.RootQcow)*" -Resolve
    popd
    
    Say "Basic Image for $key exctracted: $qcowFile";
    & virt-filesystems --all --long --uuid -h -a "$qcowFile"

    Say "Prepare Image and launch: $key"
    $preparedVm = Prepare-VM $definition $qcowFile
    Write-Host "Command prepared: [$($preparedVm.Command)]"

    $si = new-object System.Diagnostics.ProcessStartInfo($preparedVm.Command, "")
    $si.UseShellExecute = $false
    $si.WorkingDirectory = $preparedVm.Path
    $process = [System.Diagnostics.Process]::Start($si)
    $isExited = $process.WaitForExit(7000)

    $isOnline = Wait-For-Ssh "localhost" $startParams.Port "root" "pass"

    Say "Mapping guest FS to localfs"
    $mapto="$build_folder/rootfs-$($key)"
    Write-Host "Mapping Folder is [$mapto]";
    & mkdir -p "$mapto"
    $mountCmd = "echo pass | sshfs -o password_stdin 'root@localhost:/' -p $($startParams.Port) '$mapto'"
    Write-Host "Mount command: [$mountCmd]"
    & bash -c "$mountCmd"
    & ls -la "$mapto"

    Say "Copying ./lab/ to guest for [$key]"
    Remote-Command-Raw 'mkdir -p /tmp/build' "localhost" $startParams.Port "root" "pass"
    & cp $ScriptPath/lab/* $mapto/tmp/build

    Say "Configure LC_ALL, UTC and optionally swap"
    Remote-Command-Raw "bash /tmp/build/config-system.sh $($definition.SwapMb) $key" "localhost" $startParams.Port "root" "pass"

    Say "Greetings from Guest [$key]"
    $cmd='Say "Hello. I am the $(hostname) host"; sudo lscpu; echo "Content of /etc/default/locale:"; cat /etc/default/locale; echo "[env]"; printenv | sort'
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "pass"

    $mustHavePackages="apt-update; sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y && sudo apt-get clean"
    Say "Installing must have packages on [$key]"
    Remote-Command-Raw "$mustHavePackages" "localhost" $startParams.Port "root" "pass"


Say "Installing DotNet Core on [$key]"
Remote-Command-Raw "cd /tmp/build; bash -e install-dotnet.sh; command -v dotnet && dotnet --info || true" "localhost" $startParams.Port "root" "pass"
Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; command -v dotnet && dotnet --info || true' "localhost" $startParams.Port "root" "pass"
Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; command -v dotnet && dotnet --info || true' "localhost" $startParams.Port "user" "pass"
# TODO: Add dotnet restore

Say "Installing Latest Mono [$key]"
Remote-Command-Raw "cd /tmp/build; bash -e install-MONO.sh" "localhost" $startParams.Port "root" "pass"
Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; mono --version; msbuild /version; nuget | head -4' "localhost" $startParams.Port "root" "pass"
Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; mono --version; msbuild /version; nuget | head -4' "localhost" $startParams.Port "user" "pass"


    if ($true)
    {
        Say "Installing Node [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-NODE.sh" "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "user" "pass"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "root" "pass"
    }

    Say "Installing Docker [$key]"
    Remote-Command-Raw "cd /tmp/build; bash install-DOCKER.sh" "localhost" $startParams.Port "root" "pass"

    Say "Installing a Crap [$key]"
    Remote-Command-Raw "cd /tmp/build; bash install-a-crap.sh" "localhost" $startParams.Port "root" "pass"

    Say "Zeroing free space of [$key]"
    Remote-Command-Raw "cd /tmp/build; bash TearDown.sh; before-compact" "localhost" $startParams.Port "root" "pass"

    # Say "Dismounting guest's share of [$key]"
    # & umount -f $mapto # NOOOO shutdown?????

    Say "SHUTDOWN [$key] GUEST"
    Remote-Command-Raw "rm -rf /tmp/build; sudo shutdown now" "localhost" $startParams.Port "root" "pass"
    Wait-For-Process $process $key

    Say "Final compact [$key]"
    & mkdir -p "final-$key"
    pushd "final-$key"
    & rm -rf *
    $finalQcow = "$(pwd)/debian-$key-final.qcow2"
    $finalQcowPath = "$(pwd)"
    Final-Compact $definition "$qcowFile" "42G" $finalQcow 
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

}

$cores = [Environment]::ProcessorCount;
if ($cores -ge 8) { $cores-- }
Say "TOTAL PHYSICAL CORE(s): $([Environment]::ProcessorCount). Building using $cores core(s)"
$globalStartParams = @{Mem="2000M"; Cores=$cores; Port=2345};
$definitions | % {$globalStartParams.Port = $_.DefaultPort; Build $_ $globalStartParams;};

