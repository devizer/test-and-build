#!/usr/bin/env bash
# Usage 1: if [[ "$(Is-RedHat 6)" ]]; then ... 
# Usage 2: if [[ "$(Is-RedHat 8)" ]]; then ... 
# Usage 3: if [[ "$(Is-RedHat)" ]]; then ...
 
if [ -e /etc/redhat-release ]; then
  redhatRelease=$(</etc/redhat-release)
  case $redhatRelease in 
    "CentOS release 6."*)                           ret=6 ;;
    "Red Hat Enterprise Linux Server release 6."*)  ret=6 ;;
  esac
fi

if [ -e /etc/os-release ]; then
  . /etc/os-release
  if [ "${ID:-}" = "rhel" ] || [ "${ID:-}" = "centos" ]; then
    case "${VERSION_ID:-}" in
        "7"*)   ret=7 ;;
        "8"*)   ret=8 ;;
        "9"*)   ret=9 ;;
    esac
  fi
fi

arg="$1"
if [ "$arg" = "" ]; then
    echo "$ret"
    exit 0
elif [ "$arg" = "$ret" ]; then
    echo "$ret"
    exit 0
else
    exit 1
fi
