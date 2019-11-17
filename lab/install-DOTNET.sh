#!/usr/bin/env bash

# echo "[env]"
# printenv | sort
# echo "[~/.bashrc]"
# cat ~/.bashrc

echo "I'm [$(whoami)]. Net Core Should be installed as USER. Arch is $ARCH"

if [[ "$ARCH" == "i386" ]]; then
    Say "Skipping Net Core on $ARCH"  
    exit 0; 
fi

      url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      sudo apt clean
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

Say "Configuring shared environment for .NET Core"
echo '#!/usr/bin/env bash
if [[ -s "/opt/dotnet/dotnet" ]]; then 
    DOTNET_ROOT=/opt/dotnet
    PATH="/opt/dotnet:$PATH"
    if [[ -d "$HOME/.dotnet/tools" ]]; then
        PATH="$PATH:$HOME/.dotnet/tools"
    fi
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    DOTNET_CLI_TELEMETRY_OPTOUT=1
fi
' > /etc/profile.d/NVM.sh
sudo -u user mkdir -p /home/user/.dotnet/tools
mkdir -p ~/.dotnet/tools
Say "Configured shared environment for .NET Core"

# todo: BenchmarkDotNet.Tool for root