#!/usr/bin/env bash
if [[ "$(command -v mono)" == "" ]]; then
  lazy-apt-update 
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6A19B38D3D831EF
#  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  source /etc/os-release
  def="deb https://download.mono-project.com/repo/$ID stable-$(lsb_release -s -c) main"
  if [[ "$ID" == "raspbian" ]]; then def="deb https://download.mono-project.com/repo/debian stable-raspbian$(lsb_release -cs) main"; fi
  echo "$def" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  sudo apt-get --allow-unauthenticated update -qq && time sudo apt-get --allow-unauthenticated install mono-complete nuget msbuild -y -qq \
    && sudo apt purge 'monodoc*' -y -qq &&  \
  sudo apt clean; 
  # sudo rm -f /etc/apt/sources.list.d/mono-official-stable.list; 
  # sudo apt update
  systemctl stop mono-xsp4
  systemctl disable mono-xsp4
fi

# it fails if nuget is absent 
# TOO SLOW IN QEMU: moved to host
# bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || bash -e install-NET-TEST-Runners.sh || true 

pushd TestRunners
Say "Run Nuget Restore for [$(pwd)]"
nuget restore -Verbosity quiet
Say "Run msbuild for [$(pwd)]"
msbuild /t:Rebuild /p:Configuration=Debug /v:q

pushd TestRunners.xUnit/bin/Debug
Say "Test TestRunners.xUnit.dll at $(pwd)" 
xunit.console TestRunners.xUnit.dll
popd

pushd TestRunners.NUnit/bin/Debug
Say "Test TestRunners.NUnit.dll at $(pwd)"
nunit3-console TestRunners.NUnit.dll
popd  

popd

Say "Clearing mono cache"
du -h -d 1 ~/.nuget 
nuget locals all -clear
du -h -d 1 ~/.nuget
Say "Cleared mono cache"
