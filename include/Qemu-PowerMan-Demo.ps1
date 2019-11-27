
function Qemu-Powerman-Demo {

    $vm = New-Object PSObject -Property @{
        Arch = "arm";
        SshPort = 42022; # or "Random"
        Ports=@(
            @{ Host=3306; Guest=3306 },
            @{ Host=8080; Guest=80 },
        );
        CommandOnLoad = 'echo "Arch is $(uname -m). Take a look on benchmark"; 7z b; systemctl start redis';
        CopyOnLoad = @{ FromHost = "/some/path"; ToGuest = "/sources" };
        Memory = "300M";
        Cores = 4;
        HostFolder = "/my-vms/an-arm-vm";
        GuestWorkDir = "/super-project"; # or "/home/user/my-project"
        User = "root"; # or "user"
    };
    $vm = Qemu-PowerMan-Deploy $params
    $vm.Start()
    $vm.Connect()
    
    # Mapped root works on linux and MacOS only
    & cp "-r" "/some/host/dir" "$($vm.MappedRoot)/root/guest/dir"

    # On Windows only CopyToGuest and CopyFromGuest works
    $vm.CopyToGuest   "/some/host/dir" "/root/guest/dir"

    # simple Run() uses predefined user in Qemu-PowerMan-Deploy method: root
    $vm.Run 'echo "Hi, I am $(whoami)"'

    # but we can change a default user
    $vm.User = "user"; # or "user"
    $vm.Run 'echo "Hi, I am $(whoami)"'
    $vm.User = "root"; # or "user"
    $vm.Run 'echo "Hi, I am $(whoami)"' 
    $vm.Run 'LC_ALL="es_ES.UTF8"; echo "Hi, I am $(whoami)"'

    # full featured Execute
    $vm.Execute @{ 
        User = "root";
        Cmd = "bash build.sh"
        Env = @{ 
            BUILD_VERSION = "0.42"; 
            BUILD_CONFIGURATION = "Debug";
        };
    };

    # for linux only
    & cp "-r" "$($vm.MappedRoot)/root/guest/dir" "/some/another/host/dir"
    $vm.CopyFromGuest "/root/guest/dir" "/some/host/dir"

    # either
    $vm.Shutdown()

    # or instead of shutdown we can keep it running permanently
    # On linux guest root is mapped to $($HostFolder)/root-fs
    $vm.Install-SystemD-Service()
}
