#!/usr/bin/env bash
lazy-apt-update
Say "Upgrading to the latest Debian" 
export DEBIAN_FRONTEND=noninteractive 
sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade
sudo apt-get clean

Say "Content of the /boot folder"
ls -la /boot