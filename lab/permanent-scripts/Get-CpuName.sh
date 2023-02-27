#!/usr/bin/env bash
if [[ "$1" == "--name-only" ]]; then nameOnly="true"; fi
function get_cpu_name() {
  if [[ "$(uname -s)" == Linux ]]; then
    cpu="$(cat /proc/cpuinfo | grep -E '^(model name|Hardware)' | awk -F':' 'NR==1 {print $2}')"; 
    cpu="$(echo -e "${cpu:-}" | sed -e 's/^[[:space:]]*//')"
    if [[ -z "$nameOnly" ]] && [[ -n "(command -v nproc)" ]]; then cpu="$cpu, $(nproc) Cores"; fi
    # todo: cat /proc/device-tree/model on raspberry
    echo "${cpu}"
  elif [[ "$(uname -s)" == Darwin ]]; then
    cpu="$(sysctl -n machdep.cpu.brand_string)"
    if [[ -z "$nameOnly" ]]; then
      cpu="$cpu, $(sysctl -n machdep.cpu.core_count) Cores, $(sysctl -n machdep.cpu.thread_count) Threads"
    fi
    echo "${cpu}"
  elif [[ "$(uname -s)" == *"MINGW"* ]]; then
    if [[ -z "$nameOnly" ]]; then
      cpu="$(echo 'Write-Host "$((Get-WmiObject Win32_Processor).Name), $([Environment]::ProcessorCount) Cores"' | powershell -c -)"
    else
      cpu="$(echo 'Write-Host "$((Get-WmiObject Win32_Processor).Name)"' | powershell -c -)"
    fi
    echo "$cpu"
  else
    cpu="Unknown '$(uname -m)' cpu name"
    if [[ -z "$nameOnly" ]] && [[ -n "(command -v nproc)" ]]; then cpu="$cpu, $(nproc) Cores"; fi
  fi
}

echo "$(get_cpu_name)"
