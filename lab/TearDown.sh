#!/usr/bin/env bash
if [[ -e "/tmp/swap" ]]; then
    Say "Disposing the /tmp/swap swap file "
    swapoff /tmp/swap
    rm -f /tmp/swap
fi