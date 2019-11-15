#!/usr/bin/env bash

echo "[env]"
printenv | sort
echo "[~/.bashrc]"
cat ~/.bashrc

echo "I'm [$(whoami)]. Net Core Should be installed as USER. Arch is $ARCH"

if [[ "$ARCH" == "i386" ]]; then
    Say "Skipping Net Core on $ARCH"  
    exit 0; 
fi

      url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      DOTNET_Url=https://dot.net/v1/dotnet-install.sh; 
      mkdir -p ~/.dotnet/tools;
      sudo mkdir -p /opt/dotnet;
      export PATH="/opt/dotnet:$HOME/.dotnet/tools:$PATH"
      # for arm it starts from 2.1
      time (curl -ksSL $DOTNET_Url | sudo bash /dev/stdin -c 2.1 -i /opt/dotnet)
      time (curl -ksSL $DOTNET_Url | sudo bash /dev/stdin -c 2.2 -i /opt/dotnet)
      time (curl -ksSL $DOTNET_Url | sudo bash /dev/stdin -c 3.0 -i /opt/dotnet)
      export DOTNET_ROOT="/opt/dotnet"
      time dotnet tool install -g BenchmarkDotNet.Tool || true
      # time dotnet --info || true

      echo '
export PATH="/opt/dotnet:$PATH:$HOME/.dotnet/tools"  
export DOTNET_ROOT="/opt/dotnet"
' >> ~/.bashrc      

echo '
export PATH="/opt/dotnet:$PATH:$HOME/.dotnet/tools"  
export DOTNET_ROOT="/opt/dotnet"
' | sudo tee -a /root/.bashrc

# todo: BenchmarkDotNet.Tool for root