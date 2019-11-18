#!/usr/bin/env bash
cd ~/build/devizer/test-and-build; git pull; 
pwsh -c ./image-builder.ps1 -Images i386 -Only local-postgres -FinalSize 7G -MaxVmCores 8
