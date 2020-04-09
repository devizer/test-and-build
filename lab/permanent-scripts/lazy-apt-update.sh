#!/usr/bin/env bash
# SMART lazy-apt-update - only for built-in Debian repos
# try-and-retry is NOT for here
ls -1 /var/lib/apt/lists/deb* >/dev/null 2>&1 || ls -1 /var/lib/apt/lists/lock >/dev/null 2>&1 || {
    Say "Updating apt metadata (/var/lib/apt/lists/)"
    sudo apt-get update --allow-unauthenticated -qq
}

