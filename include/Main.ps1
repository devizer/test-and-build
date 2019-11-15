$probes=@(
@{Cmd="echo `$ARCH"},
@{Cmd='. /etc/os-release && echo $PRETTY_NAME' },
@{Cmd="dotnet --version"},
@{Cmd="dotnet --list-sdks"},
@{Cmd="dotnet --runtimes"},
@{Cmd="pwsh --version"},
@{Cmd="mono --version | head -1"},
@{Cmd="msbuild /version | head -1"},
@{Cmd="nuget | head -1"},
@{Cmd="nunit3-console | head -1"},
@{Cmd="xunit.console | head -1"},
@{Cmd="node --version | head -1"},
@{Cmd="npm --version | head -1"},
@{Cmd="yarn --version | head -1"},
@{Cmd="docker | head -1"},
@{Cmd="nvm --version | head -1"},
@{Cmd="mysql -N -B -uroot -pPASS -e `"SHOW VARIABLES LIKE '%Version%';`""},
@{Cmd="sudo -u postgres psql -t -c 'SELECT version();'"},
@{Cmd="echo info | redis-cli | grep version" },
@{Cmd="uname -a"},
@{Cmd="lscpu"}
)

Write-Host "Main PSScriptRoot: $PSScriptRoot"
$p=$(Join-Path $PSScriptRoot ".." "basic-images")
$BasicImagePath=(new-object System.IO.DirectoryInfo($p)).FullName + [IO.Path]::DirectorySeparatorChar

$definitions=@(
@{
    key="i386"; BasicParts=5; RootQcow="debian-i386.qcow2"
    RamForBuildingMb=1300; 
    SizeForBuildingMb=6543;
    DefaultPort=2344;
    EnableKvm=$true;
    SwapMb=256;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$BasicImagePath"
},
@{
    key="arm64"; BasicParts=5; RootQcow="disk.arm64.qcow2.raw";
    RamForBuildingMb=1200;
    SizeForBuildingMb=6000;
    DefaultPort=2346;
    SwapMb=32;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$BasicImagePath"
},
@{
    key="arm"; BasicParts=5; RootQcow="disk.expanded.qcow2.raw"
    RamForBuildingMb=800;
    # BaseUrl="file:///github.com/"
    DefaultPort=2347;
    SwapMb=32;
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/";
    BaseUrl="file://$BasicImagePath"
}
);
# temprarily we build only ARM-64
# $definitions=@($definitions[2]);




