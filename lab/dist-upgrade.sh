#!/usr/bin/env bash
lazy-apt-update
Say "Upgrading to the latest Debian" 
sudo apt dist-upgrade

Say "Content of the /boot folder"
ls -la /boot