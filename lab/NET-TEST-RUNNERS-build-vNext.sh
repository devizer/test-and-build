#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local
set -e 
set -u

# toClear=""; if [[ "$1" == "--clear" ]]; then toClear="true"; fi
 
target="${NET_TEST_RUNNERS_INSTALL_DIR:-$HOME/build/devizer/NET-TEST-RUNNERS}"
echo -e "\nInstall dir for Unit Test Runners (NUnit & xUnit): $target"
target_tmp=${target}.$(basename "$(mktemp)")
mkdir -p ${target_tmp}
pushd ${target_tmp} >/dev/null

url=https://github.com/fsprojects/Paket/releases/download/5.241.2/paket.bootstrapper.exe
echo -e "\nDownloading: $(basename $url)"
mkdir -p .paket
copy=".paket/paket.bootstrapper.exe"
cmd="wget --no-check-certificate -O \"$copy\" \"$url\"  || curl -kfSL -o \"$copy\" \"$url\""
eval $cmd || eval $cmd || eval $cmd

echo '
# framework: auto-detect
framework: net47

source https://api.nuget.org/v3/index.json

nuget NUnit.ConsoleRunner
nuget NUnit.Extension.NUnitV2Driver
nuget NUnit.Extension.NUnitV2ResultWriter 
nuget NUnit.Extension.TeamCityEventListener
nuget NUnit.Extension.NUnitProjectLoader

nuget xunit.runner.console
nuget xunit.runner.reporters
' > paket.dependencies 

echo -e "\nDownloading: paket.exe"
mono .paket/paket.bootstrapper.exe
echo -e "\nDownloading: unit test runners for NUnit and xUnit"
mono .paket/paket.exe install

cd packages
rm -rf System* 
find -name "*.nupkg" | xargs rm -f


popd >/dev/null

echo -e "\nDownloading: NET-TEST-RUNNERS-link.sh"
curl -ksSL -o ${target_tmp}/link-unit-test-runners.sh https://raw.githubusercontent.com/devizer/test-and-build/master/lab/NET-TEST-RUNNERS-link.sh
chmod +x ${target_tmp}/link-unit-test-runners.sh

mkdir -p ${target}
cp -a ${target_tmp}/* ${target} && rm -rf ${target_tmp}


