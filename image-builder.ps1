#!/usr/bin/env pwsh
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf *; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; pwsh image-builder.ps1
# sudo apt-get install sshpass sshfs

$build_folder="/transient-builds/test-and-build"
$ScriptPath=(pwd).Path

$definitions=@(
@{
    key="i386"; BasicParts=5; RootQcow="debian-i386.qcow2"
    BaseUrl="file:///github.com/";
    DefaultPort=2342;
    ExpandTargetSize="5000M"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
},
@{
    key="arm64"; BasicParts=5; RootQcow="disk.arm64.qcow2.raw"
    BaseUrl="file:///github.com/";
    DefaultPort=2346;
    ExpandTargetSize="5000M"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
},
@{
    key="arm"; BasicParts=5; RootQcow="disk.expanded.qcow2.raw"
    # BaseUrl="file:///github.com/"
    BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/";
    DefaultPort=2347;
}
);
# temprarily we build only ARM-64
$definitions=@($definitions[0]);

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
        $qemuCmd = "#!/usr/bin/env bash" + @"

qemu-system-i386 -smp $($startParams.Cores) -m $($startParams.Mem) -M q35 \
    -initrd initrd.img \
    -kernel vmlinuz -append "root=/dev/sda1 console=ttyS0" \
    -drive file=$($fileName),cache=unsafe,if=none \
    -drive file=ephemeral.qcow2,id=ephemeral,cache=unsafe,if=none \
    -netdev user,hostfwd=tcp::$($startParams.Port)-:22,id=unet -device rtl8139,netdev=unet \
    -net user \
    -nographic
"@;
    }
    $qemuCmd > $path/start-vm.sh
    & chmod +x "$path/start-vm.sh"

    @{ Path=$path; Command="$path/start-vm.sh"; }
}

function Wait-For-Ssh {param($ip, $port, $user, $password)
    $at = [System.Diagnostics.Stopwatch]::StartNew();
    do
    {
        Write-Host "Waiting for ssh connection to $($ip):$($port) ... " -ForegroundColor Gray
        # $sshCmd="sshpass -p $($password) ssh -o StrictHostKeyChecking=no $($user)@$($ip) -p $($port) hostname"
        & sshpass "-p" "$($password)" "ssh" "-o" "StrictHostKeyChecking no" "$($user)@$($ip)" "-p" "$($port)" "hostname"
        #  Write-Host "#- $sshCmd"
        # bash -ec "$sshCmd" 
    } while (-not $?)
    Write-Host "SSH on $($ip):$($port) is online" -ForegroundColor Gray
}

function Remote-Command-Raw { param($cmd, $ip, $port, $user, $password)
    $rnd = "cmd-" + [System.Guid]::NewGuid().ToString("N")
    $tmpCmdLocalFullName="$mapto/tmp/$rnd"
    "#!/usr/bin/env bash`n$cmd" > $tmpCmdLocalFullName
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

    Wait-For-Ssh "localhost" $startParams.Port "root" "pass"

    Say "Mapping guest FS to localfs"
    $mapto="$build_folder/root-$($key)"
    Write-Host "Mapping Folder is [$mapto]";
    & mkdir -p "$mapto"
    $mountCmd = "echo pass | sshfs -o password_stdin 'root@localhost:/' -p $($startParams.Port) '$mapto'"
    Write-Host "Mount command: [$mountCmd]"
    & bash -c "$mountCmd"
    & ls -la "$mapto"

    Say "Copying ./lab/ to guest for [$key]"
    Remote-Command-Raw 'mkdir -p /tmp/build' "localhost" $startParams.Port "root" "pass"
    & cp $ScriptPath/lab/* $mapto/tmp/build

    Say "Configure LC_ALL and UTC"
    Remote-Command-Raw "bash /tmp/build/config-system.sh" "localhost" $startParams.Port "root" "pass"

    Say "Greetings from Guest [$key]"
    $cmd='Say "Hello. I am the $(hostname) host"; sudo lscpu; echo "Content of /etc/default/locale:"; cat /etc/default/locale'
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "pass"

    Say "Installing DotNet Core on [$key]"
    Remote-Command-Raw "bash -e /tmp/build/install-dotnet.sh; dotnet --info" "localhost" $startParams.Port "user" "pass"
    Remote-Command-Raw 'Say "I am ROOT"; echo PATH is $PATH; dotnet --info' "localhost" $startParams.Port "root" "pass"
    Remote-Command-Raw 'Say "I am USER"; echo PATH is $PATH; dotnet --info' "localhost" $startParams.Port "user" "pass"
    # TODO: Add dotnet restore

    if ($true)
    {
        Say "Installing Node [$key]"
        Remote-Command-Raw "bash /tmp/build/install-NODE.sh" "localhost" $startParams.Port "user" "pass"
        Remote-Command-Raw 'Say "NODE: $(node --version); YARN: $(yarn --version); NPM: $(npm --version)"; echo PATH is $PATH;' "localhost" $startParams.Port "user" "pass"
    }

    Say "Zeroing free space of [$key]"
    Remote-Command-Raw "before-compact" "localhost" $startParams.Port "root" "pass"

    Say "Dismounting guest's share of [$key]"
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

$globalStartParams = @{Mem="600M"; Cores=4; Port=2345};
$definitions | % {$globalStartParams.Port = $_.DefaultPort; Build $_ $globalStartParams;};

