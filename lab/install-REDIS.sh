#!/usr/bin/env bash
Say "Installing Redis-Server"
smart-apt-install redis-server
echo info | redis-cli | grep version > /tmp/.redis-ver
Say "Installed Redis-Server: $(cat /tmp/.redis-ver | head -1)"
