#!/usr/bin/env bash
# Usage 1: if [[ "$(Is-RedHat 6)" ]]; then ... 
# Usage 2: if [[ "$(Is-RedHat 8)" ]]; then ... 
# Usage 3: if [[ "$(Is-RedHat)" ]]; then ...
 
if [ -e /etc/os-release ]; then
  . /etc/os-release
  if [[ "${ID:-}" == "fedora"* ]]; then
  	ret="${VERSION_ID:-}"
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
