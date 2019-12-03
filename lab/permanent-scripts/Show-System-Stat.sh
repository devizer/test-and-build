#!/usr/bin/env bash
function uname_system() {
  cached_uname_system=${cached_uname_system:-$(uname -s)}
  echo $cached_uname_system
}

function format_seconds() {
  local elapsed=$1
  local days=$((elapsed/86400))
  if [[ "$(uname_system)" != Darwin ]]; then
     elapsed=$(TZ=UTC date -d "@${elapsed}" "+%H:%M:%S");
  else 
     elapsed=$(TZ=UTC date -r "${elapsed}" "+%H:%M:%S");
  fi
  if [[ $days -eq 0 ]]; then 
    echo ${elapsed}
  else 
    echo "$days days, $elapsed"  
  fi
}

function GetUptimeInSeconds() {
   local uptime=$(</proc/uptime);                  # 42645.93 240538.58
   IFS=' ' read -ra uptime <<< "$uptime";    # 42645.93 240538.58
   uptime="${uptime[0]}";                    # 42645.93
   uptime=$(printf "%.0f\n" "$uptime")       # 42645
   echo $uptime
}

function ShowSystemStat() {
  if [[ "$(uname_system)" == Darwin || ! -f /proc/stat ]]; then
    uptime
    return;
  fi
  
  local first_line=$(cat /proc/stat | sed -n 1p)
  local user_normal=$(echo $first_line | awk '{print $2}')
  user_normal=$((user_normal/100))
  local user_nice=$(echo $first_line | awk '{print $3}')
  user_nice=$((user_nice/100))
  local system=$(echo $first_line | awk '{print $4}')
  system=$((system/100))
  local total=$((user_normal + user_nice + user_normal))
  local uptime=$(GetUptimeInSeconds)
  # echo uptime in seconds: $uptime 
  
  local user_normal_formatted="$(format_seconds ${user_normal})"
  local user_nice_formatted="$(format_seconds ${user_nice})"
  local system_formatted="$(format_seconds ${system})"
  local total_formatted="$(format_seconds ${total})"
  local uptime_formatted="$(format_seconds ${uptime})"
  
  
  echo "User Normal CPU Usage ......... $user_normal_formatted
User low-priority CPU Usage ... $user_nice_formatted
System CPU Usage .............. $system_formatted
-------------------------------
Total CPU Usage ............... $total_formatted
Uptime ........................ $uptime_formatted"
}

# while true; do clear; ShowSystemStat; sleep 2; done
ShowSystemStat
