#!/usr/bin/env bash
cd ~/build/devizer/test-and-build; git pull; 
git pull; pwsh -c ./image-builder.ps1 -Images i386 -Skip nodejs -FinalSize 8G -MaxVmCores 8

