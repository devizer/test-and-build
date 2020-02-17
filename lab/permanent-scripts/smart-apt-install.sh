#!/usr/bin/env bash

    try-and-retry lazy-apt-update
    Say "Downloading deb-package(s): $*"
    try-and-retry sudo apt-get -qq -d --allow-unauthenticated install "$@" 
    Say "Installing deb-package(s): $*"
    sudo DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated install "$@" -y -q
    sudo DEBIAN_FRONTEND=noninteractive apt-get clean
