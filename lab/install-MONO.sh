#!/usr/bin/env bash

function Install_Mono_on_RedHat() {
  if [[ "$(Is-RedHat 6)" ]]; then
    try-and-retry rpm --import "http://pool.sks-keyservers.net/pks/lookup?op=get&search=0x3fa7e0328081bff6a14da29aa6a19b38d3d831ef"
    Say "Installing RedHat/CentOS 6 repo using [https://download.mono-project.com/repo/centos6-stable.repo]"
    try-and-retry su -c 'curl https://download.mono-project.com/repo/centos6-stable.repo | tee /etc/yum.repos.d/mono-centos6-stable.repo'
  elif [[ "$(Is-RedHat 7)" ]]; then
    try-and-retry rpmkeys --import "http://pool.sks-keyservers.net/pks/lookup?op=get&search=0x3fa7e0328081bff6a14da29aa6a19b38d3d831ef"
    Say "Installing RedHat/CentOS 7 repo using [https://download.mono-project.com/repo/centos7-stable.repo]"
    try-and-retry su -c 'curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo'
  elif [[ "$(Is-RedHat 8)" || true ]]; then
    try-and-retry rpmkeys --import "http://pool.sks-keyservers.net/pks/lookup?op=get&search=0x3fa7e0328081bff6a14da29aa6a19b38d3d831ef"
    Say "Installing RedHat/CentOS 8 repo using [https://download.mono-project.com/repo/centos8-stable.repo]"
    try-and-retry su -c 'curl https://download.mono-project.com/repo/centos8-stable.repo | tee /etc/yum.repos.d/mono-centos8-stable.repo'
  fi
  
  yum install -y mono-complete msbuild nuget
}

function Install_Mono_on_Debians() {
  try-and-retry lazy-apt-update 
  try-and-retry sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6A19B38D3D831EF
#  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  source /etc/os-release
  def="deb https://download.mono-project.com/repo/$ID stable-$(lsb_release -s -c) main"
  if [[ "$ID" == "raspbian" ]]; then def="deb https://download.mono-project.com/repo/debian stable-raspbian$(lsb_release -cs) main"; fi
  echo "$def" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  time try-and-retry sudo apt-get --allow-unauthenticated update -qq 
  time smart-apt-install mono-complete nuget msbuild 
  sudo apt clean; 
  Say "Deleting monodoc*"
  apt purge "monodoc*" -y -qq || true 
  # sudo rm -f /etc/apt/sources.list.d/mono-official-stable.list; 
  # sudo apt update
  systemctl stop mono-xsp4
  systemctl disable mono-xsp4
}

if [[ "$(command -v mono)" == "" ]]; then
  if [[ "$(Is-RedHat)" ]]; then
    Install_Mono_on_RedHat
  else
    Install_Mono_on_Debians
  fi
fi

# it fails if nuget is absent 
# TOO SLOW IN QEMU: moved to host
# bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || true 

