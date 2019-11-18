#!/usr/bin/env bash
try_and_retry() {
  local ANSI_RED='\033[0;31m'; 
  local ANSI_RESET='\033[0m';
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${ANSI_RED}The command \"$@\" failed. Retrying, $count of 3.${ANSI_RESET}\n" >&2
    }
    # ! { } ignores set -e, see https://stackoverflow.com/a/4073372
    ! { "$@"; result=$?; }
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -gt 3 ] && {
    echo -e "\n${ANSI_RED}The command \"$@\" failed 3 times.${ANSI_RESET}\n" >&2
  }

  return $result
}

function apt_smart_install() {
    try_and_retry lazy-apt-update
    Say "Downloading deb-packages: $@"
    try_and_retry sudo apt-get -d --allow-unauthenticated install "$@" 
    Say "Installing deb-packages: $@"
    sudo apt-get --allow-unauthenticated install "$@" -y -q
    sudo apt clean
}
