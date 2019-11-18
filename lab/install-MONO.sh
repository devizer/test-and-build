#!/usr/bin/env bash
if [[ "$(command -v mono)" == "" ]]; then
  try-and-retry lazy-apt-update 
  try-and-retry sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6A19B38D3D831EF
#  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  source /etc/os-release
  def="deb https://download.mono-project.com/repo/$ID stable-$(lsb_release -s -c) main"
  if [[ "$ID" == "raspbian" ]]; then def="deb https://download.mono-project.com/repo/debian stable-raspbian$(lsb_release -cs) main"; fi
  echo "$def" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  time try-and-retry sudo apt-get --allow-unauthenticated update -qq 
  time apt-smart-install mono-complete nuget msbuild 
  sudo apt clean; 
  # sudo rm -f /etc/apt/sources.list.d/mono-official-stable.list; 
  # sudo apt update
  systemctl stop mono-xsp4
  systemctl disable mono-xsp4
fi

# it fails if nuget is absent 
# TOO SLOW IN QEMU: moved to host
# bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || true 

