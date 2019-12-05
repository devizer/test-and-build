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
    $Is_Requested_Local_Postgres = Is-Requested-Specific-Feature("local-postgres");
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

        Say "Installing locales for [$key]"
        Remote-Command-Raw 'cd /tmp/build; bash install-locales.sh' "localhost" $startParams.Port "root" "pass"

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

    if ($Is_Requested_Dotnet)
    {
        Say "Installing DotNet Core for [$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-DOTNET.sh; command -v dotnet && dotnet --info || true" "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; dotnet --info' "localhost" $startParams.Port "root" "pass"
        Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; dotnet --info' "localhost" $startParams.Port "user" "pass"
        # TODO: Add dotnet restore
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
    & nice "$Global_7z_Compress_Priority" 7z a -t7z "-mmt$Global_7z_Threads" $Global_7z_Compress_Args.Split([char]32) -v28m "$finalArchive" "."
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

