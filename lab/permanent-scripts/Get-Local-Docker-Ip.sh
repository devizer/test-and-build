#!/usr/bin/env bash
if [[ Is-Docker-Container ]]; then
    ip r | grep -E '^default via ' | awk '{print $3}'
else
    echo "127.0.0.1"
fi
