#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/lab/install-DOTNET.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

DOTNET_VERSIONS="${DOTNET_VERSIONS:-2.1 2.2 3.0 3.1}"
DOTNET_VERSIONS2=" ${DOTNET_VERSIONS} "
script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools-bundle.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash


# echo "[env]"
# printenv | sort
# echo "[~/.bashrc]"
# cat ~/.bashrc

DOTNET_TARGET_DIR="${DOTNET_TARGET_DIR:-/usr/share/dotnet}"

# crazy fix 
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$VERSION_CODENAME" == "buster" ]]; then
        Say "Installing actual CA Bundle for Buster $(uname -m)"
        file=/usr/local/share/ssl/cacert.pem
        url=https://curl.haxx.se/ca/cacert.pem
        sudo mkdir -p $(dirname $file)
        sudo wget -q -nv --no-check-certificate -O $file $url 2>/dev/null || sudo curl -ksSL $url -o $url
        test -s $file && export CURL_CA_BUNDLE="$file"
    fi
fi 


test -n "$ARCH" && echo "I'm [$(whoami)]. Net Core Should be installed as ROOT. Arch is $ARCH"

if [[ "$ARCH" == "i386" ]]; then
    Say "Skipping Net Core on $ARCH"  
    exit 0; 
fi

Say "Configuring shared environment for .NET Core. Install Dir: ${DOTNET_TARGET_DIR}"

if [[ "$(uname -r)" == 2* ]]; then
    # centos/redhat 6 
    var_HTTP_SOCKET="DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0"
    export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0 
else
    export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=1
fi

echo '#!/usr/bin/env bash
if [[ -s "'${DOTNET_TARGET_DIR}'/dotnet" ]]; then 
    DOTNET_ROOT='${DOTNET_TARGET_DIR}'
    export DOTNET_ROOT 
    PATH="'${DOTNET_TARGET_DIR}':$PATH"
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
sudo chmod +x /etc/profile.d/dotnet-core.sh

if sudo test -d /home/user; then
    sudo -u user mkdir -p /home/user/.dotnet/tools
    printf "\n\n" >> /home/user/.bashrc
    sudo -u user cat /etc/profile.d/dotnet-core.sh >> /home/user/.bashrc
    sudo chown -R user /home/user
fi

mkdir -p ~/.dotnet/tools
Say "Configured shared environment for .NET Core"
. /etc/profile.d/dotnet-core.sh


      export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
      # export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
      url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      [[ ! "$(Is-RedHat)" ]] && sudo apt-get clean
      DOTNET_Url=https://dot.net/v1/dotnet-install.sh; 
      mkdir -p ~/.dotnet/tools;
      sudo mkdir -p ${DOTNET_TARGET_DIR};
      export PATH="${DOTNET_TARGET_DIR}:$HOME/.dotnet/tools:$PATH"
      export DOTNET_ROOT="${DOTNET_TARGET_DIR}"
      sudo mkdir -p /etc/dotnet
      echo ${DOTNET_TARGET_DIR} | sudo tee /etc/dotnet/install_location
      # for arm it starts from 2.1
      try-and-retry curl -o /tmp/_dotnet-install.sh -ksSL $DOTNET_Url
      export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
      
      if false && [[ "$(uname -m)" == "x86_64" ]]; then
          # rzc fails if .NET Core SDK 2.0 installed
          Say "Installing .NET Core 1.0 SDK for $(uname -m)"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 1.0 -i ${DOTNET_TARGET_DIR}
          Say "Installing .NET Core 1.1 SDK for $(uname -m)"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 1.1 -i ${DOTNET_TARGET_DIR}
          Say "Installing .NET Core 2.0 SDK for $(uname -m)"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.0 -i ${DOTNET_TARGET_DIR}
      fi
      
      
      if [[ "$DOTNET_VERSIONS2" == *" 2.1 "* ]]; then
          Say "Installing .NET Core 2.1 SDK for $(uname -m)"
          time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.1 -i ${DOTNET_TARGET_DIR}
      fi
      
      if [[ "$DOTNET_VERSIONS2" == *" 2.2 "* ]]; then
        Say "Installing .NET Core 2.2 SDK for $(uname -m)"
        time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 2.2 -i ${DOTNET_TARGET_DIR}
      fi

      
      if [[ "$(command -v dotnet || true)" == "" ]]; then
          BenchmarkDotNet_Installed=false        
      elif [[ "$(command -v dotnet-benchmark || true)" == "" ]]; then
          Say "Installing BenchmarkDotNet.Tool (globally) for $(uname -m)"
          Say "DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER is '${DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER}'"
          try-and-retry dotnet tool install -g BenchmarkDotNet.Tool || true
          BenchmarkDotNet_Installed=true
      else
          Say "BenchmarkDotNet.Tool already installed"
          BenchmarkDotNet_Installed=true
      fi

      if [[ "$DOTNET_VERSIONS2" == *" 3.0 "* ]]; then
        Say "Installing .NET Core 3.0 SDK for $(uname -m)"
        time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 3.0 -i ${DOTNET_TARGET_DIR}
      fi
      
      if [[ "$DOTNET_VERSIONS2" == *" 3.1 "* ]]; then
        Say "Installing .NET Core 3.1 SDK for $(uname -m)"
        time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh -c 3.1 -i ${DOTNET_TARGET_DIR}
      fi
      
      if [[ "$BenchmarkDotNet_Installed" == "false" ]]; then
          Say "Installing BenchmarkDotNet.Tool (globally) for $(uname -m)"
          try-and-retry dotnet tool install -g BenchmarkDotNet.Tool || true
      fi
      
      # ! { Say ".NET Core benchmark tool version: [$(dotnet benchmark --version 2>&1 || true)]" }
      dotnet benchmark --version >/dev/null 2>&1 || true;
      Say ".NET Core benchmark tool version: [$(dotnet benchmark --version 2>/dev/null || true)]"
      true


# todo: BenchmarkDotNet.Tool for root