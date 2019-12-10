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

Say "Configuring shared environment for .NET Core"

if [[ "$(uname -r)" != 2* ]]; then 
    var_HTTP_SOCKET="DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0" 
fi

echo '#!/usr/bin/env bash
if [[ -s "/opt/dotnet/dotnet" ]]; then 
    DOTNET_ROOT=/opt/dotnet
    export DOTNET_ROOT 
    PATH="/opt/dotnet:$PATH"
    if [[ -d "$HOME/.dotnet/tools" ]]; then
        PATH="$PATH:$HOME/.dotnet/tools"
    fi
    export PATH 
    
    '$var_HTTP_SOCKET'
    export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER
    
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE
    
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT
    
    DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_CLI_TELEMETRY_OPTOUT
fi
' | sudo tee /etc/profile.d/dotnet-core.sh >/dev/null
sudo -u user mkdir -p /home/user/.dotnet/tools
mkdir -p ~/.dotnet/tools
Say "Configured shared environment for .NET Core"
. /etc/profile.d/dotnet-core.sh


      export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
      # export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
      url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      [[ ! "$(Is-RedHat)" ]] && sudo apt clean
      DOTNET_Url=https://dot.net/v1/dotnet-install.sh; 
      mkdir -p ~/.dotnet/tools;
      sudo mkdir -p /opt/dotnet;
      export PATH="/opt/dotnet:$HOME/.dotnet/tools:$PATH"
      export DOTNET_ROOT="/opt/dotnet"
      mkdir -p /etc/dotnet
      echo '/opt/dotnet' > /etc/dotnet/install_location
      # for arm it starts from 2.1
      try-and-retry curl -o /tmp/_dotnet-install.sh -ksSL $DOTNET_Url
      
      if false && [[ "$(uname -m)" == "x86_64" ]]; then
          # rzc fails if .NET Core SDK 2.0 installed
          Say "Installing .NET Core 1.0 SDK"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 1.0 -i /opt/dotnet
          Say "Installing .NET Core 1.1 SDK"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 1.1 -i /opt/dotnet
          Say "Installing .NET Core 2.0 SDK"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.0 -i /opt/dotnet
      fi
      
      Say "Installing .NET Core 2.1 SDK"
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.1 -i /opt/dotnet
      Say "Installing .NET Core 2.2 SDK"
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.2 -i /opt/dotnet
      Say "Installing .NET Core 3.0 SDK"
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 3.0 -i /opt/dotnet
      Say "Installing BenchmarkDotNet.Tool (globally)"
      try-and-retry dotnet tool install -g BenchmarkDotNet.Tool || true
      Say "Installing .NET Core 3.1 SDK"
      time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 3.1 -i /opt/dotnet
      Say ".NET Core benchmark tool version: [$(dotnet benchmark --version 2>&1)]"


# todo: BenchmarkDotNet.Tool for root