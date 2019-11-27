. ./Qemu-PowerMan.ps1

function Qemu-PowerMan-DesignDemo {

    $vm = New-Object PSObject -Property @{
        Arch = "arm";
        SshPort = 42022;                  # "Random" or any string means random port
        Ports = @(                        # it is for bridge-less network only
            @{ Host = 3306; Guest = 3306 },
            @{ Host = 8080; Guest = 80 }
        );
        CommandOnLoad = 'echo "Arch is $(uname -m). Take a look on benchmarks"; 7z b; systemctl start redis';
        CopyOnLoad = @{ FromHost = "/some/path"; ToGuest = "/sources" };
        Memory = "300M";
        Cores = 4;
        HostFolder = "/my-vms/an-arm-vm";
        GuestWorkDir = "/super-project";  # or "/home/user/my-project"
        User = "root";                    # or "user",
        ResetRootDisk = $false;           # reset root (/dev/sdb) disk before deployment?
        ResetEphemeralDisk = $false;      # reset /dev/sdb disk before deployment?
        Env = @{
            BUILD_VERSION = "0.42";
            BUILD_CONFIGURATION = "Debug";
        };
    };
    
    $isOk1 = Qemu-PowerMan-Deploy $vm
    $isOk2 = $vm.Start()
    $isOk3 = $vm.Connect(30)                       # 30 seconds is timeout
    if (!$isOk1 -or !$isOk2 -or !$isOk3 -or $true) {
        throw "Unable to start and esteblish connection to VM";
    }
    
    # Mapped root works on linux and MacOS only
    & cp "-r" "/some/host/dir" "$($vm.MappedRoot)/root/guest/dir"

    # On Windows only CopyToGuest and CopyFromGuest works
    $vm.CopyToGuest("/some/host/dir", "/root/guest/dir") 

    # simple Run() uses predefined user in Qemu-PowerMan-Deploy method: root
    $vm.Run('echo "Hi, I am $(whoami)"')

    # but we can change a default user to ether 'root' or 'user'
    $vm.User = "user"; # or "root"
    $vm.Run('echo "Hi, I am $(whoami)"')
    $vm.User = "root"; # or "user"
    $vm.Run('echo "Hi, I am $(whoami)"') 
    $vm.Run('LC_ALL="es_ES.UTF8"; echo "Hi, I am $(whoami)"')

    # full featured Execute
    $vm.Run(@{ 
        User = "root";
        Cmd = "bash build.sh"
        Env = @{ 
            BUILD_VERSION = "0.42"; 
            BUILD_CONFIGURATION = "Debug";
        };
    });

    # for linux/macOS only
    & cp "-r" "$($vm.MappedRoot)/root/guest/dir" "/some/another/host/dir"
    
    # for Windows and others
    $vm.CopyFromGuest("/root/guest/dir", "/some/host/dir")

    # 3 options at the end
    # option 1:
    $okShutdown = $vm.Shutdown(60)
    
    Write-Host "Total Errors: $($vm.Errors.Count)"

    # option 2: keep it running permanently till reboot
    # On linux guest root is mapped to $($HostFolder)/root-fs
    
    # option 3: Install Windows- or SystemD-service and enable starting on reboot and shutdowning on host shutdown 
    $vm.InstallService(@{
        Key = "Some_Arm32_BuildServer"; 
        Description = "ARMv7 32 bit Build Server";
        ShutdownTimeout = 120; # it is on linux only?
    })
}

Qemu-Powerman-DesignDemo
