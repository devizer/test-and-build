#!/usr/bin/env sh
# export NET_TEST_RUNNERS_INSTALL_DIR=~/bin; script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-net-test-runners.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

function exec_cmd() {
  cmd="$1"
  sudo true >/dev/null 2>&1 && eval "sudo $cmd" || eval "$cmd"
}

url=https://raw.githubusercontent.com/devizer/test-and-build/master/lab/NET-TEST-RUNNERS-build.sh
file=$(basename $url)
cmd="curl -ksSL -o ~/${file} $url || wget --no-check-certificate -O ~/${file} $url" 
exec_cmd "$cmd" || exec_cmd "$cmd" || exec_cmd "$cmd"
bash ~/${file}
# same as NET-TEST-RUNNERS-build.sh
target="${NET_TEST_RUNNERS_INSTALL_DIR:-$HOME/build/devizer/NET-TEST-RUNNERS}"
pushd $target
set -e
bash link-unit-test-runners.sh
