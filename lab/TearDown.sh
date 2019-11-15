#!/usr/bin/env bash
cd /
Say "Disk Usage On Finish"
df -h
if [[ -e "/tmp/swap" ]]; then
    Say "Disposing the /tmp/swap swap file "
    swapoff /tmp/swap
    rm -f /tmp/swap
fi