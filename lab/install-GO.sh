#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/lab/install-GO.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

# https://golang.org/dl/

set -e
script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools-bundle.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

GO_TARGET_DIR="${GO_TARGET_DIR:-/usr/local}"
# GO_VER="${GO_VER:-1.14.3}"
GO_VER="${GO_VER:-1.15}"

machine="$(uname -m)"
if [[ "$machine" == i?86 ]]; then
	dl=https://dl.google.com/go/go${GO_VER}.linux-386.tar.gz
elif [[ "$machine" == x86_64 ]]; then
	dl=https://dl.google.com/go/go${GO_VER}.linux-amd64.tar.gz
elif [[ "$machine" == aarch64 ]]; then
	dl=https://dl.google.com/go/go${GO_VER}.linux-arm64.tar.gz
elif [[ "$machine" == armv6* || "$machine" == armv7* ]]; then
	dl=https://dl.google.com/go/go${GO_VER}.linux-armv6l.tar.gz
else
  echo unsupported arch: $machine
fi

Say "Downloading $dl"

work=$HOME/build/go-dl
mkdir -p $work
pushd $work >/dev/null
cmd="wget --no-check-certificate -O _go.tgz $dl  || curl -kfSL -o _go.tgz $dl"
try-and-retry eval "$cmd"
tar xzf _go.tgz
rm -f _go.tgz

# https://tecadmin.net/install-go-on-debian/
test -d $GO_TARGET_DIR/go && sudo rm -rf $GO_TARGET_DIR/go || true
sudo mv go $GO_TARGET_DIR
export GOROOT=$GO_TARGET_DIR/go
# export GOPATH=$HOME/Projects/Proj1
export PATH=$GOROOT/bin:$PATH # $GOPATH/bin
go version
go env
sudo ln -f -s $GOROOT/bin/go /usr/local/bin/go || true

popd
rm -rf $work
