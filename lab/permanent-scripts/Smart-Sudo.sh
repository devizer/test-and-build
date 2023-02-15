#!/usr/bin/env bash
if [[ -n "$(command -v sudo)" ]]; then
  sudo -E "$@"
else
  eval "$@"
fi
