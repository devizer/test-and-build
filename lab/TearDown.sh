#!/usr/bin/env bash

for s in 'postgresql' 'redis-server' 'mariadb' 'docker'; do
    Say "Stop and disable [$s]"
    systemctl stop $s
    systemctl disable $s
done
Say "Preinstalled Services"
systemctl list-units --type=service

cd /
Say "Disk Usage On Finish"
df -h
if [[ -e "/tmp/swap" ]]; then
    Say "Disposing the /tmp/swap swap file "
    swapoff /tmp/swap
    rm -f /tmp/swap
fi
Say "Size of the /tmp:"
du /tmp -d 1 -h
