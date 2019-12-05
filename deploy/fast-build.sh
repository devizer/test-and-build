#!/usr/bin/env bash
cd ~/build/devizer/test-and-build; git pull; 
# git pull; pwsh -c ./image-builder.ps1 -Images AMD64 -Skip None -FinalSize 0 -MaxVmCores 2
# git pull; pwsh -c ./image-builder.ps1 -Images AMD64 -Only nothing -FinalSize 0 -MaxVmCores 2
# git pull; pwsh -c ./image-builder.ps1 -Images AMD64 -Only nodejs -FinalSize 0 -MaxVmCores 2
# git pull; pwsh -c ./image-builder.ps1 -Images AMD64 -Only Mini -FinalSize 0 -MaxVmCores 2
git pull; pwsh -c ./image-builder.ps1 -Images arm64 -Only Nothing -FinalSize 7500M -MaxVmCores 2


