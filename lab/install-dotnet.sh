#!/usr/bin/env bash
      url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      DOTNET_Url=https://dot.net/v1/dotnet-install.sh; 
      mkdir -p ~/.dotnet/tools; export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
      # time (curl -ksSL $DOTNET_Url | bash /dev/stdin -c 1.0 -i ~/.dotnet)
      # time (curl -ksSL $DOTNET_Url | bash /dev/stdin -c 1.1 -i ~/.dotnet)
      # time (curl -ksSL $DOTNET_Url | bash /dev/stdin -c 2.0 -i ~/.dotnet)
      # for arm it starts from 2.1
      time (curl -ksSL $DOTNET_Url | bash /dev/stdin -c 2.1 -i ~/.dotnet)
      time (curl -ksSL $DOTNET_Url | bash /dev/stdin -c 2.2 -i ~/.dotnet)
      time (curl -ksSL $DOTNET_Url | bash /dev/stdin -c 3.0 -i ~/.dotnet)
      export DOTNET_ROOT="$HOME/.dotnet"
      # time dotnet tool install -g BenchmarkDotNet.Tool || true
      # time dotnet --info || true
      echo '
export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"  
export DOTNET_ROOT="$HOME/.dotnet"
' >> ~/.bashrc