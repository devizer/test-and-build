#!/usr/bin/env bash
swapSizeMb=$1
if [[ -n "${swapSizeMb}" ]]; then
    Say "Creating swap file $swapSizeMb Mb as /tmp/swap"
    sudo dd if=/dev/zero of=/tmp/swap bs=1M count=$swapSizeMb
    sudo mkswap /tmp/swap
    sudo swapon /tmp/swap
 fi
