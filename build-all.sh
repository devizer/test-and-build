#!/usr/bin/env bash
export INSTALL_NODE_FOR_i386=True
pwsh -command ./image-builder.ps1 -Images arm,i386,arm64
