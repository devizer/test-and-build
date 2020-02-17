#!/usr/bin/env bash
lazy-apt-update
Say "Upgrading to the latest Debian" 
export DEBIAN_FRONTEND=noninteractive 
sudo DEBIAN_FRONTEND=noninteractive apt dist-upgrade
sudo apt clean

Say "Content of the /boot folder"
ls -la /boot