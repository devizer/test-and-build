#!/usr/bin/env bash
# export SKIP_DOTNET_DEPENDENCIES=False
# export DOTNET_VERSIONS="3.1 5.0 6.0 7.0 8.0"
# export DOTNET_VERSIONS="3.1:aspnetcore 5.0:aspnetcore 6.0:aspnetcore 7.0:aspnetcore 8.0"
# kind: default|sdk, aspnetcore, dotnet, windowsdesktop
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/lab/install-DOTNET.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash; test -s /usr/share/dotnet/dotnet && sudo ln -f -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet; test -s /usr/local/share/dotnet/dotnet && sudo ln -f -s /usr/local/share/dotnet/dotnet /usr/local/bin/dotnet; 

DOTNET_VERSIONS="${DOTNET_VERSIONS:-2.1 2.2 3.0 3.1 5.0 6.0}"
DOTNET_VERSIONS2=" ${DOTNET_VERSIONS} "
script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools-bundle.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash >/dev/null

function smart_sudo() {
  if [[ "$(command -v sudo)" ]]; then 
    sudo -E "$@"
  else
    eval "$@"
  fi
}

# echo "[env]"
# printenv | sort
# echo "[~/.bashrc]"
# cat ~/.bashrc

defdir=/usr/share/dotnet; 
is_windows=""
if [[ "$(uname -s)" == Darwin ]]; then defdir=/usr/local/share/dotnet; fi
if [[ "$(uname -s)" == *MINGW* ]]; then defdir='C:\Program Files\dotnet'; is_windows="True"; fi
DOTNET_TARGET_DIR="${DOTNET_TARGET_DIR:-$defdir}"
test -n $is_windows && smart_sudo mkdir -p /etc/profile.d

# crazy fix 
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$VERSION_CODENAME" == "buster" ]]; then
        Say "Installing actual CA Bundle for Buster $(uname -m)"
        file=/usr/local/share/ssl/cacert.pem
        url=https://curl.haxx.se/ca/cacert.pem
        smart_sudo mkdir -p $(dirname $file)
        smart_sudo wget -q -nv --no-check-certificate -O $file $url 2>/dev/null || smart_sudo curl -ksSL $url -o $url
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
if [[ -s "'"'"${DOTNET_TARGET_DIR}"'"'/dotnet" ]]; then 
    DOTNET_ROOT='"'"${DOTNET_TARGET_DIR}"'"'
    export DOTNET_ROOT 
    PATH="'"'"${DOTNET_TARGET_DIR}"'"':$PATH"
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
' | smart_sudo tee /etc/profile.d/dotnet-core.sh >/dev/null
smart_sudo chmod +x /etc/profile.d/dotnet-core.sh

if [[ -n "$(command -v sudo)" ]] && sudo test -d /home/user; then
    # sudo as user
    sudo -u user mkdir -p /home/user/.dotnet/tools
    if [[ -z "${SKIP_DOTNET_ENVIRONMENT:-}" ]]; then
      printf "\n\n" >> /home/user/.bashrc
      # sudo as user
      sudo -u user cat /etc/profile.d/dotnet-core.sh >> /home/user/.bashrc
    fi
    smart_sudo chown -R user /home/user
fi

mkdir -p ~/.dotnet/tools
Say "Configured shared environment for .NET Core"
. /etc/profile.d/dotnet-core.sh


      export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
      # export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDsmart_LER=0
      if [[ "${SKIP_DOTNET_DEPENDENCIES:-}" != "True" ]]; then
        url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      fi
      [[ "$(command -v apt-get)" != "" ]] && smart_sudo apt-get clean
      DOTNET_Url=https://dot.net/v1/dotnet-install.sh; 
      if [[ -n "$is_windows" ]]; then DOTNET_Url=https://dot.net/v1/dotnet-install.ps1; fi
      mkdir -p ~/.dotnet/tools;
      smart_sudo mkdir -p ${DOTNET_TARGET_DIR};
      export PATH="${DOTNET_TARGET_DIR}:$HOME/.dotnet/tools:$PATH"
      export DOTNET_ROOT="${DOTNET_TARGET_DIR}"
      smart_sudo mkdir -p /etc/dotnet
      echo ${DOTNET_TARGET_DIR} | smart_sudo tee /etc/dotnet/install_location >/dev/null
      # for arm it starts from 2.1
      if [[ "$(uname -s)" == Darwin ]]; then dotnet_install="$(mktemp -t dotnet-install.sh)"; else dotnet_install="$(mktemp -t dotnet-install.sh.XXXXXXXX)"; fi
      if [[ -n "$is_windows" ]]; then TMPDIR="$USERPROFILE"'\Temp'; mkdir -p $TMPDIR; dotnet_install="$TMPDIR"'\'"dotnet-install.$(date +%s.%6N).ps1"; echo "DOWNLOAD SCRIPT TO: [$dotnet_install]"; fi
      if [[ "$(command -v try-and-retry)" == "" ]]; then
        curl -o "${dotnet_install}" -ksSL $DOTNET_Url
      else
        try-and-retry curl -o "${dotnet_install}" -ksSL $DOTNET_Url
      fi
      export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
      
      for arg in $DOTNET_VERSIONS; do
        v="$(echo "$arg" | awk -F":" '{print $1}')"
        kind="$(echo "$arg" | awk -F":" '{print $2}')"
        case $kind in 
          # kind: default|sdk, aspnetcore, dotnet, windowsdesktop
          aspnetcore|asp|aspnet) runtime="-runtime aspnetcore"; runtimeName="ASP.NET Core Runtime (includes .NET runtime)";;
          dotnet|net) runtime="-runtime dotnet"; runtimeName=".NET Runtime (minimal)";;
          windowsdesktop) runtime="-runtime windowsdesktop"; runtimeName="Windows Desktop .NET Core Runtime";;
          *) runtime=""; runtimeName="Full SDK";;
        esac
        pat='^[0-9]+\.[0-9]+$'
        if [[ $v =~ $pat ]]; then 
          __a="-c $v"
          __m="$v (channel)"
        else 
          __a="-version $v"
          __m="$v (version)"
        fi
        __machine="${__machine:-$(uname -m)}"
        Say "Installing .NET Core $__m $runtimeName for $__machine"
        if [[ -n "$is_windows" ]]; then
          powershell -f "${dotnet_install}" $runtime $__a -i "${DOTNET_TARGET_DIR}"
        elif [[ "$(command -v timeout)" == "" ]]; then
          time smart_sudo try-and-retry bash "${dotnet_install}" $runtime $__a -i ${DOTNET_TARGET_DIR}
        else
          time smart_sudo try-and-retry timeout 1000 bash "${dotnet_install}" $runtime $__a -i ${DOTNET_TARGET_DIR}
        fi
      done
      
