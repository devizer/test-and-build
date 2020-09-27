#!/usr/bin/env bash

# git ls-remote --tags https://github.com/git/git | awk '{n=$2; gsub(/^refs\/tags\//,"", n); if (n ~ /^v?[0-9.]*$/) { print n } }' | sort -V

# ^{}: https://stackoverflow.com/questions/15472107/when-listing-git-ls-remote-why-theres-after-the-tag-name/15472310
# remove ^{}
# Get-Git-Tags https://github.com/PowerShell/PowerShell --pre | awk '{ n=$1; if (! (n ~ /\^\{\}$/) ) { print $n } }'

# output tags ordered as versions
function get_git_tags() {
  local repo="$1"; repo="${repo:-https://github.com/nodejs/node}"
  local need_pre_release="$2"; 
  if [[ "$need_pre_release" == "pre"* || "$need_pre_release" == "--pre"* ]]; then 
    need_pre_release=true; else need_pre_release=false; 
  fi
  
  cmd='git ls-remote --tags '$repo' | awk '"'"'{n=$2; gsub(/^refs\/tags\//,"", n);'
  if [[ $need_pre_release == false ]]; then
    cmd="$cmd if (n ~ /^v?[0-9.]*$/ && ! ( n ~ /\^\{\}$/ ))"
  else 
    cmd="$cmd if (! ( n ~ /\^\{\}$/ ))"
  fi
  cmd="$cmd { print n } }' | sort -V"
  eval "$cmd"
}

if [[ "$1" == "" ]]; then
    echo "Usage Get-Git-Tags https://github.com/nodejs/node [--pre-release|--pre]"
    exit 0; 
fi

get_git_tags $1 $2
