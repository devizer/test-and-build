function Combine-Path {
    param([string[]] $parts)
    return [System.IO.Path]::GetFullPath( [System.IO.Path]::Combine($parts) )
}

function Directory-Separator-Char { [System.IO.Path]::DirectorySeparatorChar.ToString() }

function Pretty-Format {
    param([Hashtable] $arg, $indent = 5)
    $space=new-object system.string([char]32, $indent)
    # $arg.Keys | sort | % { "$($space)$($_): '$($arg[$_])'"; } | Join-String -Separator "`n"   
    $arg.Keys | sort | % { "$($space)$($_): $(if ($arg[$_].GetType().Name -eq "string") {[string]::Concat("'",$arg[$_].ToString(),"'")} else {$arg[$_]})"; } | Join-String -Separator "`n"
}

function Set-Console-Title {
    param($title)
    $Global:SayCounter++;
    $title="#$($SayCounter) $title";
    if ($Global:BuildConsoleTitle) { $title = "$($Global:BuildConsoleTitle) $title" }
    try
    {
        [Console]::Title = $title;
    }
    catch {}
}

function Say
{
    param([string] $message)
    $_black_circle="$([char] 9679)"
    $_white_circle="$([char] 9675)"
    $_black_square="$([char] 9632)"
    $Local:elapsed="$( Get-Elapsed ) "
    # Write-Host "$($_black_square) $([Environment]::MachineName): " -NoNewline
    Write-Host "$($_black_square) $($Local:elapsed)" -NoNewline -ForegroundColor Magenta
    Write-Host "$message" -ForegroundColor Yellow
    Set-Console-Title "$($Local:elapsed) $message"; 
}

function Get-Elapsed
{
    if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
    [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("HH:mm:ss"), "]");
}; Get-Elapsed | out-null;

function Output-To-Markdown{
    param([string] $output, $probe)
    
    $trimmedOutput=$output.Trim([char]13, [char]10)
    if ($trimmedOutput -like "/tmp/cmd-*") 
    {
        return "|ERR: _" + $trimmedOutput.Substring(51) + "_|"; 
    }
    elseif (($trimmedOutput -like "sudo: unknown user*") -or ($trimmedOutput -like "* not found")) {
        return "|ERR: _" + $trimmedOutput.Replace("`n", ". ") + "_|";
    }
    # Write-Host "trimmedOutput: $trimmedOutput"
    $outputAsArray=$trimmedOutput.Split([char]10)
    $outputAsMarkdown="";
    $outputLine=0;
    @($outputAsArray) | % {
        if ((! $probe.Head) -or ($outputLine -lt $probe.Head)) {
            if ($outputAsMarkdown) { $outputAsMarkdown += "<br>" }
            $outputAsMarkdown += "**``" + $_ + "``**"
        }
        $outputLine++;
    }
    "|$($outputAsMarkdown)|"
}

function Get-File-Size-Info {
    param($fileName)
    try
    {
        "$(((New-Object System.IO.FileInfo($fileName)).Length / 1024 / 1024)) Mb"
    }
    catch{
        "[$($_.Exception.GetType().Name)]"
    }
}

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

# port, mem and #cores are indirectly passed via $startParams
# REFACTORED
function Prepare-VM
{
    param($definition, $rootDiskFullName, $guestNamePrefix = "", $portNumber = 0)
    $key=$definition.Key
    if (! $portNumber)
    {
        $portNumber = $startParams.Port
    }
    $path = Split-Path -Path $rootDiskFullName;
    $path = "$($path)"
    $fileName = [System.IO.Path]::GetFileName($rootDiskFullName)
    Write-Host "Copy kernel to '$( $path )'"
    Copy-Item "$ProjectPath/kernels/$( $definition.KernelFolderName )/*" "$( $path )/"

    # on 18.04 virt-format without defrag produces 1Gb file, on 19.10 - 30Mb 
    pushd $path
    & qemu-img create -f qcow2 ephemeral.temp.qcow2 200G
    & virt-format "--partition=mbr" "--filesystem=ext4" "-a" "ephemeral.temp.qcow2"
    & qemu-img convert -O qcow2 -c ephemeral.temp.qcow2 ephemeral.qcow2
    & rm -f ephemeral.temp.qcow2
    popd

    $guestName = $definition.Image;
    $hasKvm = (& sh -c "ls /dev/kvm 2>/dev/null") | Out-String
    if ($key -eq "arm")
    {
        $qemySystem = "arm"
        $paramCpu = ""
    }
    elseif ($key -eq "arm64")
    {
        $qemySystem = "aarch64"
        $paramCpu = " -cpu cortex-a57 "
    }
    elseif ($key -eq "i386")
    {
        $guestName = IIF $hasKvm -Then "$($definition.Image)-KVM" -Else "$($definition.Image)-EMU" 
        $qemySystem = "i386"
        # qemu-system-i386 --machine q35 -cpu ?
        # CPU: kvm32|SandyBridge
        $kvmCpu = IIF $definition.NeedSSE4 -Then "SandyBridge" -Else "kvm32" 
        $paramCpu = IIF $hasKvm -Then " -cpu $kvmCpu " -Else " -cpu qemu32 "  
        $kvmParameters = IIF ($definition.EnableKvm -and $hasKvm) -Then " -enable-kvm " -Else " " 
    }
    elseif ($key -eq "AMD64")
    {
        $guestName = IIF ($hasKvm) -Then "$($definition.Image)-KVM" -Else "$($definition.Image)-EMU"
        $qemySystem = "x86_64"
        # qemu-system-i386 --machine q35 -cpu ?
        # CPU: kvm64|SandyBridge
        $kvmCpu = IIF ($definition.NeedSSE4) -Then "SandyBridge" -Else "kvm64"
        $paramCpu = IIF ($hasKvm) -Then " -cpu $kvmCpu " -Else " -cpu qemu64 " 
        $kvmParameters = IIF ($definition.EnableKvm -and $hasKvm) -Then " -enable-kvm " -Else " "
    }
    else
    {
        throw "Unknown definition.key = '$key'"
    }

    if ($guestNamePrefix)
    {
        $guestName = "$guestNamePrefix-$guestName"
    }
    $sudoPrefix = IIF ($hasKvm -and ($definition.EnableKvm)) -Then "sudo " -Else ""

    # $p1="arm"; $k=$definition.Key; if ($k -eq "arm64") {$p1="aarch64";} elseif ($k -eq "i386") {$p1="i386";}
    # $p2 = if ($k -eq "arm64") { " -cpu cortex-a57 "; } else {""};

    # if archive contains cloud-config.qcow2 then attach it
    $expected_CloudConfig="cloud-config.qcow2";
    if (Test-Path (Combine-Path($path,$expected_CloudConfig))) {
        $cloudConfig_Param="-drive file=cloud-config.qcow2,format=qcow2,id=config"
    }

    # ARM 64/32
    $qemuCmd = "#!/usr/bin/env bash" + @" 

qemu-system-${qemySystem} -name $guestName \
    -smp $( $startParams.Cores ) -m $( $startParams.Mem ) -M virt ${paramCpu} \
    -initrd initrd.img \
    -kernel vmlinuz \
    -append 'root=/dev/sda1 console=ttyAMA0' \
    -global virtio-blk-device.scsi=off \
    -device virtio-scsi-device,id=scsi \
    -drive file=$( $fileName ),id=rootimg,cache=unsafe,if=none -device scsi-hd,drive=rootimg \
    -drive file=ephemeral.qcow2,id=ephemeral,cache=unsafe,if=none -device scsi-hd,drive=ephemeral \
    $cloudConfig_Param \
    -netdev user,hostfwd=tcp::$( $portNumber )-:22,id=net0 -device virtio-net-device,netdev=net0 \
    -nographic
"@;

    # i386/AMD64
    if ($definition.Key -eq "i386" -or $definition.Key -eq "AMD64")
    {
        $qemuCmd = "#!/usr/bin/env bash" + @"

#-device rtl8139 and e1000 are not stable
$( $sudoPrefix )qemu-system-${qemySystem} -name $guestName -smp $( $startParams.Cores ) -m $( $startParams.Mem ) -M q35  $( $kvmParameters ) $paramCpu \
    -initrd initrd.img \
    -kernel vmlinuz -append "root=/dev/sda1 console=ttyS0" \
    -drive file=$( $fileName ),id=rootimg \
    -drive file=ephemeral.qcow2,id=ephemeral \
    $cloudConfig_Param \
    -netdev user,hostfwd=tcp::$( $portNumber )-:22,id=unet -device e1000-82545em,netdev=unet \
    -net user \
    -nographic
"@; # -drive file=ephemeral.qcow2 cache=unsafe \
    }
    $qemuCmd > $path/start-vm.sh
    & chmod +x "$path/start-vm.sh"

    @{ Path = $path; Command = "$path/start-vm.sh"; }
}

function Wait-For-Ssh
{
    param($ip, $port, $user, $password)
    $at = [System.Diagnostics.Stopwatch]::StartNew();
    $pingCounter = 1;
    do
    {
        Write-Host "#$( $pingCounter ): Waiting for ssh connection to $( $ip ):$( $port ) ... " -ForegroundColor Gray
        # $sshCmd="sshpass -p $($password) ssh -o StrictHostKeyChecking=no $($user)@$($ip) -p $($port) hostname"
        & sshpass "-p" "$( $password )" "ssh" "-o" "StrictHostKeyChecking no" "$( $user )@$( $ip )" "-p" "$( $port )" "hostname"
        if ($?)
        {
            Write-Host "SSH on $( $ip ):$( $port ) is online" -ForegroundColor Green
            return $true;
        }
        if ($at.ElapsedMilliseconds -ge ($Global_SSH_Timeout*1000))
        {
            Say "Error. SSH Connection Timeouted. Building aborted. Guest pid #$( $Global:qemuProcess ) should be killed. $( $at.Elapled )"
            & sudo kill "-SIGTERM" "$( $Global:qemuProcess )"
            $Global:BuildResult.TotalCommandCount++;
            $Global:BuildResult.FailedCommands += "SSH connection timed out: $( $at.Elapled )";
            $Global:BuildResult.IsSccessful = $false;
            return $false;
        }
        Start-Sleep 1;
        $pingCounter++;
    } while ($true)

}

function Remote-Command-Raw
{
    param($cmd, $ip, $port, $user, $password, [bool] $reconnect = $false, [bool] $destructive = $false)
    if (! $Global:GuestLog)
    {
        $Global:GuestLog = "/tmp/$([Guid]::NewGuid().ToString("N") )"
    }
    $rnd = "cmd-" + [System.Guid]::NewGuid().ToString("N")
    $tmpCmdLocalFullName = "$mapto/tmp/$rnd"
    # Early Azlue Pipelines blocks/elemenate colors in terminal
    # new azure pipeline supports colors very well
    # $cmd_Colorless = IIF ($ENV:BUILD_DEFINITIONNAME) -Then "export SAY_COLORLESS=true" -Else ""
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
($cmd) 2>&1 | tee -a "$( $Global:GuestLog )-$( $user )"
"@

    # Write-Host "REMOTE-SCRIPT: `n[$remoteCmd]"

    # next line fails on disconnected guest: DirectoryNotFoundException 
    try
    {
        $remoteCmd > $tmpCmdLocalFullName; $errorInfo = $null;
    }
    catch
    {
        $errorInfo = "Failed to store command as the $( $tmpCmdLocalFullName ) file: $( $_.Exception )"
    }

    & chmod +x $tmpCmdLocalFullName
    if ($false -and $reconnect)
    {
        Write-Host "Temparary un-mount guest root fs"
        & umount -f $mapto
    }
    $localCmd = "sshpass -p `'$( $password )`' ssh -o 'StrictHostKeyChecking no' $( $user )@$( $ip ) -p $( $port ) /tmp/$rnd"
    if ($false -and $reconnect)
    {
        $mountCmd = "echo $($password) | sshfs -o password_stdin 'root@localhost:/' -p $( $startParams.Port ) '$mapto'"
        Write-Host "RE-Mount command: [$mountCmd]"
        & bash -c "$mountCmd"
        & ls -la $mapto
    }
    Write-Host "#: $cmd"
    if ($errorInfo -eq $null)
    {
        & bash -c "$localCmd"
        $isExitOk = $?;
        $isExitOkInfo = IIF $isExitOk "OK" "ERR" 
        $destructiveInfo = IIF $destructive " DESTRUCTIVE!" "" 
        Write-Host "$( $isExitOkInfo ):$( $destructiveInfo ) [$cmd]"
        if ((! $isExitOk) -and (! $destructive))
        {
            $errorInfo = "Failed to execute remote command: [$cmd]"
        }
        else
        {
            & rm -f $tmpCmdLocalFullName
            if (! $? -and (! $destructive))
            {
                $errorInfo = "Failed to clean up remote command: [$cmd]"
            }
        }
    }

    $Global:BuildResult.TotalCommandCount++;

    if ($errorInfo)
    {
        $Global:BuildResult.FailedCommands += "#: $cmd`n$errorInfo";
        $Global:BuildResult.IsSccessful = $false;
    }
}

# REFACTORED
function Wait-For-Process
{
    param($process, $name)
    Say "Waiting for shutdown of [$name]"
    if ($process.WaitForExit(5*1000*60)) {
        Say "[$name] VM gracefully powered off"
    } else {
        Say "[$name] VM stuck";
        try { 
            $process.Kill();
            Say "[$name] VM had forced to be killed";
        }
        catch{
            Say "[$name] VM was not killed successfully";
        }
    }
    
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
    $key = $definition.Key
    Say "Produce Report for [$key]"
    # & mkdir -p "$PrivateReport"
    $reportFile = "$PrivateReport/$($definition.Image)/$image-$suffix.md"
    "|  <u>**$($definition.Image)**</u> |`n|-------|" > $reportFile

    $probes | % {
        $probe = $_; $cmd = $_.Cmd;
        $responseFile = "/tmp/response-$(([Guid]::NewGuid()).ToString("N") )"
        # Write-Host "Port: $($startParams.Port)" 
        Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "$($definition.UsersPassword)" > $responseFile 2>&1
        $response = Get-Content $responseFile -Raw
        Write-Host "Response for [$cmd]:`n$( $response )"
        $title = IIF $probe.Name -Then $probe.Name -Else $probe.Cmd; 
        "| $title |" >> $reportFile
        # "| $response |" >> $reportFile
        Output-To-Markdown $response $probe >> $reportFile
        & rm -f "$responseFile"
    }
}

function IIF{
    param($IsOk, $Then, $Else)
    if ($isOk) {$then} else {$else}
} 
