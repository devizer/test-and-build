#!/usr/bin/env pwsh
# mkdir -p ~/build/devizer; cd ~/build/devizer; rm -rf *; git clone https://github.com/devizer/test-and-build.git; cd test-and-build; pwsh image-builder.ps1
# sudo apt-get install sshpass sshfs

$build_folder="/transient-builds/test-and-build"
$ScriptPath=(pwd).Path

$definitions=@(
    @{
        key="arm"; BasicParts=5; RootQcow="disk.expanded.qcow2.raw"
        # BaseUrl="file:///github.com/"
        BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    } 
);

function Say { param( [string] $message )
Write-Host "$(Get-Elapsed) " -NoNewline -ForegroundColor Magenta
Write-Host "$message" -ForegroundColor Yellow
}

function Get-Elapsed
{
    if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
    [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("mm:ss"), "]");
}; Get-Elapsed | out-null;


function Prepare-VM { param($definition, $rootDiskFullName)
    $path=Split-Path -Path $rootDiskFullName;
    Write-Host "Copy kernel to '$($path)'"
    Copy-Item "$ScriptPath/kernels/$($definition.Key)/*" "$($path)/"
    pushd $path
    & qemu-img create -f qcow2 ephemeral.qcow2 200G
    popd
    
$qemuCmd = "#!/usr/bin/env bash" + @" 

qemu-system-arm \
    -smp $($startParams.Cores) -m $($startParams.Mem) -M virt \
    -initrd initrd.img \
    -kernel vmlinuz \
    -append 'root=/dev/sda1 console=ttyAMA0' \
    -global virtio-blk-device.scsi=off \
    -device virtio-scsi-device,id=scsi \
    -drive file=$($rootDiskFullName),id=rootimg,cache=unsafe,if=none -device scsi-hd,drive=rootimg \
    -drive file=ephemeral.qcow2,id=ephemeral,cache=unsafe,if=none -device scsi-hd,drive=ephemeral \
    -netdev user,hostfwd=tcp::$($startParams.Port)-:22,id=net0 -device virtio-net-device,netdev=net0 \
    -nographic
"@

    $qemuCmd > $path/start-vm.sh
    & chmod +x "$path/start-vm.sh"

    @{ Path=$path; Command="$path/start-vm.sh"; }
}

function Wait-For-Ssh {param($ip, $port, $user, $password)
    $at = [System.Diagnostics.Stopwatch]::StartNew();
    do
    {
        Write-Host "Waiting for ssh connection to $($ip):$($port) ... " -ForegroundColor Gray
        $sshCmd="sshpass -p $($password) ssh -o `"StrictHostKeyChecking no`" $($user)@$($ip) -p $($port) hostname"
        # & sshpass "-p" "$($password)" "ssh" "-o" "StrictHostKeyChecking no" "$($user)@$($ip)" "-p" "$($port)" "hostname"
        & bash -ec "$sshCmd" 
    } while (-not $?)
    Write-Host "SSH on $($ip):$($port) is online" -ForegroundColor Gray
}

function Remote-Command-Raw { param($cmd, $ip, $port, $user, $password)
    $rnd = "cmd-" + [System.Guid]::NewGuid().ToString("N")
    "#!/usr/bin/env bash`n$cmd" > $mapto/$rnd
    & chmod +x $mapto/$rnd
    $localCmd="sshpass -p `'$($password)`' ssh -o 'StrictHostKeyChecking no' $($user)@$($ip) -p $($port) /$rnd"
    Write-Host "#: $cmd"
    & bash -c "$localCmd"
    & rm -f $mapto/$rnd
}

function Wait-For-Process {param($process, $name)
    Say "Waiting for shutdown of [$key]"
    $process.WaitForExit()
    Say "[$key] VM gracefully powered off"
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
    $isExited = $process.WaitForExit(1000)

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

    Say "Greetings from Guest [$key]"
    Remote-Command-Raw 'printf "HEEEELLLLLOOOO. I am [$(hostname)]\n$(lscpu)\n"' "localhost" $startParams.Port "root" "pass"

    Say "Installing DotNet Core on [$key]"
    Remote-Command-Raw "bash /tmp/build/install-dotnet.sh" "localhost" $startParams.Port "root" "pass"
    # TODO: Add dotnet restore
    Remote-Command-Raw "dotnet --info" "localhost" $startParams.Port "root" "pass"

    Say "Installing Node [$key]"
    Remote-Command-Raw "bash /tmp/build/install-NODE.sh" "localhost" $startParams.Port "root" "pass"
    Remote-Command-Raw 'echo "NODE: $(node --version); YARN: $(yarn --version); NPM: $(npm --version)"' "localhost" $startParams.Port "root" "pass"

    Say "Dismounting guest's share of [$key]"
    # & umount -f $mapto # shutdown?????

    Say "SHUTDOWN [$key] GUEST"
    Remote-Command-Raw "sudo shutdown now" "localhost" $startParams.Port "root" "pass"
    Wait-For-Process $process $key

    Say "The End"
    popd

}

$globalStartParams = @{Mem="600M"; Cores=4; Port=2345};
$definitions | % {Build $_ $globalStartParams;};

