#!/usr/bin/env bash
# if Is-Docker-Container; then
if [[ "$(Is-Docker-Container -v)" == true ]]; then
    ip r | grep -E '^default via ' | awk '{print $3}'
else
    echo "127.0.0.1"
fi
