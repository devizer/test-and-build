#!/usr/bin/env bash

# echo "[env]"
# printenv | sort
# echo "[~/.bashrc]"
# cat ~/.bashrc

echo "I'm [$(whoami)]. Net Core Should be installed as ROOT. Arch is $ARCH"

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
      export DOTNET_ROOT="/opt/dotnet"
      mkdir -p /etc/dotnet
      echo '/opt/dotnet' > /etc/dotnet/install_location
      # for arm it starts from 2.1
      try-and-retry curl -o /tmp/_dotnet-install.sh -ksSL $DOTNET_Url
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.1 -i /opt/dotnet
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.2 -i /opt/dotnet
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 3.0 -i /opt/dotnet
      try-and-retry dotnet tool install -g BenchmarkDotNet.Tool || true
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 3.1 -i /opt/dotnet
      time dotnet --info || true

Say "Configuring shared environment for .NET Core"
echo '#!/usr/bin/env bash
if [[ -s "/opt/dotnet/dotnet" ]]; then 
    DOTNET_ROOT=/opt/dotnet
    export DOTNET_ROOT 
    PATH="/opt/dotnet:$PATH"
    if [[ -d "$HOME/.dotnet/tools" ]]; then
        PATH="$PATH:$HOME/.dotnet/tools"
    fi
    export PATH 
    
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
    export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER
    
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER
    
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT
    
    DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER
fi
' | sudo tee /etc/profile.d/dotnet-core.sh >/dev/null
sudo -u user mkdir -p /home/user/.dotnet/tools
mkdir -p ~/.dotnet/tools
Say "Configured shared environment for .NET Core"

# todo: BenchmarkDotNet.Tool for root