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
        if ((-not $probe.Head) -or ($outputLine -lt $probe.Head)) {
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

# Write-Host "REMOTE-SCRIPT: `n[$remoteCmd]"

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
    

