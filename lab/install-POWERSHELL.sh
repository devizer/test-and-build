#!/usr/bin/env bash
if [[ "$ARCH" != "i386" ]]; then
    script=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-and-nodejs.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash -s pwsh
else
    Say "Skipping Powershell for i386";
fi
