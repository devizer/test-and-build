#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local
set -e 
set -u

function Header() {
  local txt=$1
  local length=${#txt}
  local border="---"; while [[ $length -gt 0 ]]; do border="-${border}"; length=$((length-1)); done
  if [[ "${NEXT_HEADER:-}" == "" ]]; then NEXT_HEADER=true; else echo ""; fi
  echo "> ${txt}"; echo $border
}
# toClear=""; if [[ "$1" == "--clear" ]]; then toClear="true"; fi
 
target="${NET_TEST_RUNNERS_INSTALL_DIR:-$HOME/build/devizer/NET-TEST-RUNNERS}"
Header "Install dir for Unit Test Runners (NUnit & xUnit): $target"
target_tmp=${target}.$(basename "$(mktemp)")
mkdir -p ${target_tmp}
pushd ${target_tmp} >/dev/null

url=https://github.com/fsprojects/Paket/releases/download/5.241.2/paket.bootstrapper.exe
Header "Downloading: $(basename $url)"
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

Header "Downloading: paket.exe"
mono .paket/paket.bootstrapper.exe
Header "Downloading: unit test runners for NUnit and xUnit"
mono .paket/paket.exe install

cd packages
rm -rf System* 
find -name "*.nupkg" | xargs rm -f


popd >/dev/null

Header  "Downloading: link-unit-test-runners.sh"
curl -ksSL -o ${target_tmp}/link-unit-test-runners.sh https://raw.githubusercontent.com/devizer/test-and-build/master/lab/NET-TEST-RUNNERS-link.sh
chmod +x ${target_tmp}/link-unit-test-runners.sh

mkdir -p ${target}
cp -a ${target_tmp}/* ${target} && rm -rf ${target_tmp}

pushd "${target}" >/dev/null
bash link-unit-test-runners.sh
popd >/dev/null

echo "DONE. try nunit3-console and xunit.runner commands"
