#!/usr/bin/env bash
if [[ "${1:-}" == "--name-only" ]]; then nameOnly="true"; fi

function get_kernel_file_1st_line() {
  local arg="$1"
  local copy="$(mktemp)"
  cp -f "$arg" "$copy" >/dev/null 2>&1 || true
  local ret=""
  if [[ -e "$copy" ]]; then 
    local substring
    while IFS= read -r -d '' substring || [[ $substring ]]; do
      ret+="$substring"
    done <"$copy"
  fi
  rm -f "$copy" >/dev/null 2>&1 || true
  echo "$ret"
}


function get_cpu_name() {
  local cpu;
  if [[ "$(uname -s)" == Linux ]]; then
    cpu="$(cat /proc/cpuinfo | grep -E '^(model name|Hardware)' | awk -F':' 'NR==1 {print $2}')"; 
    cpu="$(echo -e "${cpu:-}" | sed -e 's/^[[:space:]]*//')"
    # on raspberry, AWS, And Oracle Cloud it is empty for ARM
    if [[ -z "$cpu" ]]; then
      # /sys/firmware/devicetree/base/model: Raspberry Pi 5 Model B Rev 1.0
      # /proc/device-tree/model: Raspberry Pi 5 Model B Rev 1.0
      # /sys/firmware/devicetree/base/model: Xunlong Orange Pi PC
      # /proc/device-tree/model: Xunlong Orange Pi PC
      # unknown cpu
      local model="$(get_kernel_file_1st_line "/proc/device-tree/model")";
      if [[ "$model" == *"Raspberry"* ]]; then cpu="$model"; fi
      # Not a raspberry?
      if [[ -z "$cpu" ]]; then
        cpu="$(uname -m)"
      fi
    fi
    if [[ -z "$nameOnly" ]] && [[ -n "(command -v nproc)" ]]; then cpu="$cpu, $(nproc) Cores"; fi
    echo "${cpu}"
  elif [[ "$(uname -s)" == Darwin ]]; then
    cpu="$(sysctl -n machdep.cpu.brand_string)"
    if [[ -z "$nameOnly" ]]; then
      cpu="$cpu, $(sysctl -n machdep.cpu.core_count) Cores, $(sysctl -n machdep.cpu.thread_count) Threads"
    fi
    echo "${cpu}"
  elif [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]]; then
    if [[ -z "$nameOnly" ]]; then
      cpu="$(echo '$cpu="$((Get-WmiObject Win32_Processor).Name)".Trim([char] 32, [char] 10, [char] 13);"$cpu, $([Environment]::ProcessorCount) Cores"' | powershell -c -)"
    else
      cpu="$(echo '$cpu="$((Get-WmiObject Win32_Processor).Name)".Trim([char] 32, [char] 10, [char] 13);"$cpu"' | powershell -c -)"
    fi
    echo "$cpu"
  else
    cpu="Unknown '$(uname -m)' cpu name"
    if [[ -z "$nameOnly" ]] && [[ -n "$(command -v nproc)" ]]; then cpu="$cpu, $(nproc) Cores"; fi
  fi
}

echo "$(get_cpu_name)"
