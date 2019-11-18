#!/usr/bin/env bash

    try-and-retry lazy-apt-update
    Say "Downloading deb-package(s): $@"
    try-and-retry sudo apt-get -d --allow-unauthenticated install "$@" 
    Say "Installing deb-package(s): $@"
    sudo apt-get --allow-unauthenticated install "$@" -y -q
    sudo apt clean
