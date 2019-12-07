function Build
{
    param($definition, $startParams)
    $key = $definition.key
    $image = $definition.Image
    
    $the_PrivateReport = "$PrivateReport/$($definition.Image)"
    & mkdir -p $the_PrivateReport
    & rm -rf "$the_PrivateReport/*"

    $Global:BuildResult = new-object PSObject -Property @{
        IsSccessful=$true;
        FailedCommands=@();
        TotalCommandCount=0;
    };

    Start-Transcript -Path (Join-Path $the_PrivateReport "$( $definition.Key )-log.log")

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
    $file_UrlPart = [string]::Format($definition.DownloadFileFormat, $key,"00[1-$( $definition.BasicParts )]")
    $file_LocalPart = [string]::Format($definition.DownloadFileFormat, $key,"00#1")
    $download_cmd = "curl -kSL $( $definition.BaseUrl )$($file_UrlPart) -o '$file_LocalPart'";
    Write-Host "shell command: [$download_cmd]";
    & mkdir -p downloads-$image;
    pushd downloads-$image
    & bash -c $download_cmd
    $arch1 = join-Path -Path "." -ChildPath "*.001" -Resolve
    popd

    Say "To INSTALL: $(@($featuresToInstall).Count) [$featuresToInstall], To Skip: $(@($featuresToSkip).Count) [$featuresToSkip]"
    Say "Extracting basic image: $image::$key"
    Write-Host "archive: $arch1";
    & mkdir -p basic-image-$image;
    pushd basic-image-$image
    & rm -rf *
    & nice "$Global_7z_DeCompress_Priority" 7z -y x $arch1
    # & bash -c 'rm -f *.7z.*'
    $qcowFile = join-Path -Path "." -ChildPath "*$( $definition.RootQcow )*" -Resolve
    popd

    Say "Basic Image for $image::$key exctracted: $qcowFile ($(Get-File-Size-Info $qcowFile))";
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

    $isOnline = Wait-For-Ssh "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    if (! $isOnline)
    {
        $Global:IsBuildSuccess=$false;
        return;
    }

    Say "Mapping guest FS to localfs"
    $mapto = "$build_folder/rootfs-$( $image )"
    Write-Host "Mapping Folder is [$mapto]";
    & mkdir -p "$mapto"
    & rm -rf "$mapto/*"
    $mountCmd = "echo $($definition.UsersPassword) | sshfs -o password_stdin 'root@localhost:/' -p $( $startParams.Port ) '$mapto'"
    Write-Host "Mount command: [$mountCmd]"
    & bash -c "$mountCmd"
    & ls -la "$mapto"

    Say "Copying ./lab/ to guest for [$image::$key]"
    # Remote-Command-Raw 'mkdir -p /tmp/build' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    & mkdir -p $mapto/tmp/build
    & cp -a $ProjectPath/lab/* $mapto/tmp/build

    Say "Configure SSH for [$image::$key]"
    Remote-Command-Raw "cd /tmp/build; bash config-ssh.sh $key" "localhost" $startParams.Port "root" "$($definition.UsersPassword)" $true # re-connect

    Say "RESTART SSH for [$image::$key]"
    Remote-Command-Raw 'sshId="$(pgrep -f "sshd -D")"; Say "Restarting SSH Server (pid is $sshId)"; sudo kill -SIGHUP "$(pgrep -f "sshd -D")"; Say "Restarted SSH Server";' "localhost" $startParams.Port "root" "$($definition.UsersPassword)" $false $true # destructive

    Say "Configure LC_ALL, UTC and optionally swap for [$image::$key]"
    Remote-Command-Raw "cd /tmp/build; bash config-system.sh $( $definition.SwapMb )" "localhost" $startParams.Port "root" "$($definition.UsersPassword)" $true # re-connect

    if (!$Is_IgnoreAll)
    {
        Say "Upgrading to the latest Debian for [$image::$key]"
        Remote-Command-Raw 'cd /tmp/build; bash dist-upgrade.sh' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"

        Say "Installing locales for [$image::$key]"
        Remote-Command-Raw 'cd /tmp/build; bash install-locales.sh' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    # Produce-Report $definition $startParams "onstart"

    Say "Greetings from Guest [$image::$key]"
    $cmd = 'Say "Hello from $(whoami). I am the $(hostname) host"; sudo lscpu; echo [PATH] is: $PATH; echo "Content of /etc/default/locale:"; cat /etc/default/locale; echo "[env]"; printenv | sort'
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    Remote-Command-Raw $cmd "localhost" $startParams.Port "user" "$($definition.UsersPassword)"

    if (!$Is_IgnoreAll)
    {
        $mustHavePackages = "smart-apt-install apt-transport-https ca-certificates curl gnupg2 software-properties-common htop mc lsof unzip net-tools bsdutils; apt-get clean"
        Say "Installing must have packages on [$image::$key]"
        Remote-Command-Raw "$mustHavePackages" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    if ($Is_Requested_Dotnet)
    {
        Say "Installing DotNet Core for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-DOTNET.sh; command -v dotnet && dotnet --info || true" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
        Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; dotnet --info' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
        Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; dotnet --info' "localhost" $startParams.Port "user" "$($definition.UsersPassword)"
        # TODO: Add dotnet restore
    }

    if ($Is_Requested_Mono)
    {
        Say "Installing Latest Mono [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-MONO.sh" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
        Remote-Command-Raw 'Say "I am ROOT"; echo PATH is [$PATH]; mono --version; msbuild /version; echo ""; nuget >/tmp/.tmp; cat /tmp/.tmp | head -4; rm /tmp/.tmp' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
        Remote-Command-Raw 'Say "I am USER"; echo PATH is [$PATH]; mono --version; msbuild /version; echo ""; nuget >/tmp/.tmp; cat /tmp/.tmp | head -4; rm /tmp/.tmp' "localhost" $startParams.Port "user" "$($definition.UsersPassword)"

        Say "Building NET-TEST-RUNNERS on the host and installing to the guest"
        pushd "$ProjectPath/lab"; & bash NET-TEST-RUNNERS-build.sh; popd
        Say "Copying NET-TEST-RUNNERS to /opt/NET-TEST-RUNNERS on the guest"
        & cp -a ~/build/devizer/NET-TEST-RUNNERS "$mapto/opt"
        Say "Linking NET-TEST-RUNNERS on the guest"
        Remote-Command-Raw "bash /opt/NET-TEST-RUNNERS/link-unit-test-runners.sh" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"

        Say "Run .net tests on guest [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash -e run-NET-UNIT-TESTS.sh" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }



    if ($Is_Requested_Powershell)
    {
        Say "Installing Powershell for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash -e install-POWERSHELL.sh" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    if ($Is_Requested_Docker)
    {
        Say "Install Docker for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash Install-DOCKER.sh;" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    if ($Is_Requested_local_postgres)
    {
        Say "Install Local Postgres SQL for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-POSTGRES.sh;" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    if ($Is_Requested_Local_Mariadb)
    {
        Say "Install Local MariaDB for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-MARIADB.sh;" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    if ($Is_Requested_Local_Redis)
    {
        Say "Install Local Redis Server for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-REDIS.sh;" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }


    # if ($Env:INSTALL_NODE_FOR_i386 -eq "True" -or $key -ne "i386")
    if ($Is_Requested_NodeJS)
    {
        Say "Installing Node for [$image::$key]"
        Remote-Command-Raw 'cd /tmp/build; export TRAVIS="$TRAVIS"; bash install-NODE.sh' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "user" "$($definition.UsersPassword)"
        Remote-Command-Raw 'Say "As [$(whoami)] NODE: [$(node --version)]; YARN: [$(yarn --version)]; NPM: [$(npm --version)]"; echo PATH is [$PATH];' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }
    <#
    else {
        Say "Skipping NodeJS on i386"
    }
#>


    if (!$Is_IgnoreAll)
    {
        Say "Installing a Crap for [$image::$key]"
        Remote-Command-Raw "cd /tmp/build; bash install-a-crap.sh" "localhost" $startParams.Port "root" "$($definition.UsersPassword)"
    }

    Say "Log Packages for [$image::$key]"
    Remote-Command-Raw 'Say "PACKAGES:\n$(list-packages)"' "localhost" $startParams.Port "root" "$($definition.UsersPassword)"

    Say "Store list-packages"
    $installedPackagesFileName="installed-packages-$key.txt"
    $cmd='list-packages | cut -c 12- | sort > /tmp/' + $installedPackagesFileName
    Remote-Command-Raw $cmd "localhost" $startParams.Port "root" "$($definition.UsersPassword)"

    Produce-Report $definition $startParams "onfinish"

    Say "Store Guest Logs"
    & cp -f "$mapto/$($Global:GuestLog)-user" "$the_PrivateReport/$key-guest-user.log"
    & cp -f "$mapto/$($Global:GuestLog)-root" "$the_PrivateReport/$key-guest-root.log"
    pushd "$mapto/tmp"
    & cp -f Said-by-root.log $the_PrivateReport/$key-said-by-root.log
    & cp -f Said-by-user.log $the_PrivateReport/$key-said-by-user.log
    & cp -f "$installedPackagesFileName" "$the_PrivateReport/$installedPackagesFileName"
    popd


    pushd "$mapto"
    & rm -f $the_PrivateReport/$key-user-profile.7z
    & 7z -mmt1 a  $the_PrivateReport/$key-user-profile.7z etc/profile.d home/user usr/local/bin
    popd

    Say "Zeroing free space of [$image::$key]"
    Remote-Command-Raw "cd /; bash /tmp/build/TearDown.sh; apt clean; before-compact" "localhost" $startParams.Port "root" "$($definition.UsersPassword)" $false $true

    # Say "Dismounting guest's share of [$key]"
    # & umount -f $mapto # NOOOO shutdown?????

    Say "SHUTDOWN [$image::$key] GUEST"
    Remote-Command-Raw "rm -rf /tmp/build; Say 'Size of the /tmp again:'; du /tmp -d 1 -h; (sudo shutdown now & ); (poweroff -h now & )" "localhost" $startParams.Port "root" "$($definition.UsersPassword)" $false $true
    Wait-For-Process $Global:qemuProcess "$image::$key"

    Say "Final compact [$image::$key]"
    & mkdir -p "final-$image"
    pushd "final-$image"
    & rm -rf *
    $finalQcow = "$(pwd)/$image-final.qcow2"
    $finalQcowPath = "$(pwd)"

    # $Env:LIBGUESTFS_DEBUG="1"; $Env:LIBGUESTFS_TRACE="1" # WTH?
    Final-Compact $definition "$qcowFile" "$Global_FinalSize" $finalQcow
    popd

    Say "Final Image for [$image::$key]: $finalQcow";
    & nice "$Global_ExpandDisk_Priority" virt-filesystems --all --long --uuid -h -a "$finalQcow"

    Say "Splitting final image for publication [$image::$key]: $finalQcow ($(Get-File-Size-Info $finalQcow))";
    & mkdir -p "final-$image-splitted"
    & pushd "final-$image-splitted"
    & rm -rf *
    & cp "$the_PrivateReport/$installedPackagesFileName" "$installedPackagesFileName"
    $finalArchive = "$(pwd)/$image-final.qcow2.7z"
    $finalArchivePath = "$(pwd)"
    popd
    pushd $finalQcowPath
    $cmd_Split_Final="nice $Global_7z_Compress_Priority 7z a -t7z -mmt$Global_7z_Threads $Global_7z_Compress_Args -v28m $finalArchive ."
    Write-Host "#: $cmd_Split_Final"
    & bash -c "$cmd_Split_Final"
    Say "The Final archive content with compresion ratio [$finalArchive]"
    & 7z l "$($finalArchive).001"
    popd
    pushd $finalArchivePath
    & ls -la
    popd

    & bash -c "umount -f $mapto >/dev/null 2>&1"

    Say "The End"
    popd
    Stop-Transcript
    $Global:IsBuildSuccess=$true;
}

