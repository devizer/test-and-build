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
@{Cmd="mysql --table -uroot -pPASS -e `"SHOW VARIABLES LIKE '%Version%';`""},
@{Cmd="sudo -u postgres psql -c 'SELECT version();'"},
@{Cmd="echo info | redis-cli | grep version" },
@{Cmd="uname -a"},
@{Cmd="lscpu"}
)

Write-Host "Main PSScriptRoot: $PSScriptRoot"
$p=$(Join-Path $PSScriptRoot ".." "basic-images")
$ScriptPath=(new-object System.IO.DirectoryInfo($p)).FullName + [IO.Path]::DirectorySeparatorChar

$definitions=@(
@{
    key="i386"; BasicParts=5; RootQcow="debian-i386.qcow2"
    DefaultPort=2344;
    ExpandTargetSize="5000M";
    EnableKvm=$true;
    SwapMb=256;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$ScriptPath"
},
@{
    key="arm64"; BasicParts=5; RootQcow="disk.arm64.qcow2.raw";
    DefaultPort=2346;
    ExpandTargetSize="5000M";
    SwapMb=32;
    # BaseUrl="file:///github.com/"
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/"
    BaseUrl="file://$ScriptPath"
},
@{
    key="arm"; BasicParts=5; RootQcow="disk.expanded.qcow2.raw"
    # BaseUrl="file:///github.com/"
    DefaultPort=2347;
    SwapMb=32;
    # BaseUrl="https://raw.githubusercontent.com/devizer/test-and-build/master/basic-images/";
    BaseUrl="file://$ScriptPath"
}
);
# temprarily we build only ARM-64
# $definitions=@($definitions[2]);