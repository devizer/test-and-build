#!/usr/bin/env bash
# export DOTNET_VERSIONS="3.1"
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/lab/install-DOTNET.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash; test -s /usr/share/dotnet/dotnet && sudo ln -f -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

DOTNET_VERSIONS="${DOTNET_VERSIONS:-2.1 2.2 3.0 3.1 5.0 6.0}"
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
    if [[ -z "${SKIP_DOTNET_ENVIRONMENT:-}" ]]; then
      printf "\n\n" >> /home/user/.bashrc
      sudo -u user cat /etc/profile.d/dotnet-core.sh >> /home/user/.bashrc
    fi
    sudo chown -R user /home/user
fi

mkdir -p ~/.dotnet/tools
Say "Configured shared environment for .NET Core"
. /etc/profile.d/dotnet-core.sh


      export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
      # export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
      if [[ "${SKIP_DOTNET_DEPENDENCIES:-}" != "True" ]]; then
        url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      fi
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
      
      for v in $DOTNET_VERSIONS; do
        pat='^[0-9]+\.[0-9]+$'
        if [[ $v =~ $pat ]]; then 
          __a="-c $v"
          __m="$v (channel)"
        else 
          __a="-version $v"
          __m="$v (version)"
        fi
        __machine="${__machine:-$(uname -m)}"
        Say "Installing .NET Core $__m SDK for $__machine"
        time try-and-retry timeout 666 sudo -E bash /tmp/_dotnet-install.sh $__a -i ${DOTNET_TARGET_DIR}
      done
      
