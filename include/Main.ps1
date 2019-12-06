$probes=@(
@{Cmd="echo `$ARCH"},
@{Cmd="nuget"; Head=1},
@{Cmd="nunit3-console --version"; Head=1},
@{Cmd="xunit.console"; Head=1},
@{Cmd="dotnet --list-sdks"; Name=".NET Core SDKs"; SkipOn=@("i386")},
@{Cmd="mono --version"; Head=1},
@{Cmd="msbuild /version"; Head=1},
@{Cmd="pwsh --version"; SkipOn=@("i386")},
@{Cmd="nvm --version "; Head=1},
@{Cmd="node --version"; Head=1},
@{Cmd="npm --version"; Head=1},
@{Cmd="yarn --version"; Head=1},
@{Cmd="docker version --format '{{.Server.Version}}'"},
@{Cmd="docker-compose version"; Head=1},
@{Cmd="mysql -N -B -uroot -pPASS -e `"SHOW VARIABLES LIKE 'version';`""},
@{Cmd="cd /tmp; sudo -u postgres psql -t -c 'SELECT version();'"},
@{Cmd="echo info | redis-cli | grep version"; Head=1; Name="Redis Server" },
@{Cmd="uname -a"},
@{Cmd='. /etc/os-release && echo "$PRETTY_NAME v$(cat /etc/debian_version)"' },
@{Cmd="lscpu"}
)

Write-Host "Main PSScriptRoot: $PSScriptRoot"
$p=$(Join-Path $PSScriptRoot ".." "basic-images")
$BasicImagePath=(new-object System.IO.DirectoryInfo($p)).FullName + [IO.Path]::DirectorySeparatorChar

$definitions=@(
@{
    Image="CentOS-6-AMD64";
    key="AMD64"; BasicParts=5; RootQcow="CentOS-6-amd64.raw";
    NeedSSE4=$false;
    EnableKvm=$true;
    RamForBuildingMb=1200;
    SizeForBuildingMb=8200; # from 2G
    DefaultPort=2205;
    SwapMb=64;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="https://dl.bintray.com/devizer/debian-multiarch/basic-images/";
    DownloadFileFormat="CentOS-6-amd64.raw.7z.{1}";
    KernelFolderName="CentOS-6-AMD64";
    BinTrayRepo="CentOS-6-AMD64-for-building-and-testing";
    UsersPassword="p1ssw0rd";
},
@{
    Image="Debian-10-arm64";
    key="arm64"; BasicParts=5; RootQcow="disk.arm64.qcow2.raw";
    RamForBuildingMb=1200;
    SizeForBuildingMb=6000; # from 2G
    DefaultPort=2201;
    SwapMb=64;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$BasicImagePath";
    KernelFolderName="arm64";
    DownloadFileFormat="debian-arm64.qcow2.7z.{1}";
    BinTrayRepo="debian-arm64-for-building-and-testing";
    UsersPassword="pass";
},
@{
    Image="Debian-10-arm";
    key="arm"; BasicParts=5;
    RootQcow="disk.expanded.qcow2.raw" # it is 5Gb
    RamForBuildingMb=800;
    # BaseUrl="file:///github.com/"
    DefaultPort=2202;
    SwapMb=32;
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/";
    BaseUrl="file://$BasicImagePath"
    KernelFolderName="arm";
    DownloadFileFormat="debian-arm.qcow2.7z.{1}";
    BinTrayRepo="debian-arm-for-building-and-testing";
    UsersPassword="pass";
},
@{
    Image="Debian-10-AMD64";
    key="AMD64"; BasicParts=5; RootQcow="debian-AMD64.basic.qcow2"
    NeedSSE4=$false;
    EnableKvm=$true;
    RamForBuildingMb=1200;
    # SizeForBuildingMb=7000; # from 3G
    DefaultPort=2203;
    SwapMb="none";
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$BasicImagePath";
    KernelFolderName="AMD64";
    DownloadFileFormat="debian-AMD64.qcow2.7z.{1}";
    BinTrayRepo="debian-AMD64-for-building-and-testing";
    UsersPassword="pass";
},
@{
    Image="Debian-10-i386";
    key="i386"; BasicParts=5; RootQcow="debian-i386.qcow2"
    NeedSSE4=$false;
    EnableKvm=$true;
    RamForBuildingMb=2000; # for NodeJS Compilation
    SizeForBuildingMb=7000; # from 3G
    DefaultPort=2204;
    SwapMb="none";
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$BasicImagePath";
    KernelFolderName="i386";
    DownloadFileFormat="debian-i386.qcow2.7z.{1}";
    BinTrayRepo="debian-i386-for-building-and-testing";
    UsersPassword="pass";
});


$FeatureFilters=@("mono", "dotnet", "powershell", "docker", "local-postgres", "local-mariadb", "local-redis", "nodejs")

