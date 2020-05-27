#!/usr/bin/env bash
usystem="$(uname -s)"
if [[ "$usystem" == "Linux" ]]; then
  sync; sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
elif [[ "$usystem" == "Darwin" ]]; then
  sync; sudo sync; sudo purge
else 
  echo 'Drop-FS-Cache: Only Linux and macOS are currently supported'
fi

