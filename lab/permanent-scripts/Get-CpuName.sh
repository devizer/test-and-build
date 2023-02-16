#!/usr/bin/env bash
function get_cpu_name() {
  if [[ "$(uname -s)" == Linux ]]; then
    cpu="$(cat /proc/cpuinfo | grep -E '^(model name|Hardware)' | awk -F':' 'NR==1 {print $2}')"; 
    cpu="$(echo -e "${cpu:-}" | sed -e 's/^[[:space:]]*//')"
    if [[ -n "(command -v nproc)" ]]; then cpu="$cpu, $(nproc) Cores"; fi
    # todo: cat /proc/device-tree/model on raspberry
    echo "${cpu}"
  elif [[ "$(uname -s)" == Darwin ]]; then
    cpu="$(sysctl -n machdep.cpu.brand_string), $(sysctl -n machdep.cpu.core_count) Cores, $(sysctl -n machdep.cpu.thread_count) Threads"
    echo "${cpu}"
  elif [[ "$(uname -s)" == *"MINGW"* ]]; then
    cpu="$(echo 'Write-Host "$((Get-WmiObject Win32_Processor).Name), $([Environment]::ProcessorCount) Cores"' | powershell -c -)"
    echo "$cpu"
  else
    cpu="Unknown '$(uname -m)' cpu name"
    if [[ -n "(command -v nproc)" ]]; then cpu="$cpu, $(nproc) Cores"; fi
  fi
}

echo "$(get_cpu_name)"
