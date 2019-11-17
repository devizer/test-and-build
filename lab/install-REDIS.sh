#!/usr/bin/env bash
Say "Installing Redis-Server"
apt-get install -y redis-server
apt clean
echo info | redis-cli | grep version > /tmp/.redis-ver
Say "Installed Redis-Server: $(cat /tmp/.redis-ver | head -1)"
