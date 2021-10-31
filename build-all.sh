#!/usr/bin/env bash
mkdir -p /transient-builds/src
cd /transient-builds/src; git clone https://github.com/devizer/test-and-build; cd test-and-build; git pull
cd /transient-builds/src/test-and-build; export INSTALL_NODE_FOR_i386=True; time pwsh -command ./image-builder.ps1 -Images Debian-10-arm -Skip dotnet,local-redis,local-postgres,local-mariadb -FinalSize 42G
cd /transient-builds/src/test-and-build; export INSTALL_NODE_FOR_i386=True; time pwsh -command ./image-builder.ps1 -Images Debian-10-arm64 -Skip dotnet,local-redis,local-postgres,local-mariadb -FinalSize 42G


