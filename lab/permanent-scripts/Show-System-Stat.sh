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
  if [[ ${days} -eq 0 ]]; then 
    echo ${elapsed}
  elif [[ ${days} -eq 1 ]]; then
    echo "1 day, $elapsed"
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

function format_label() {
    local label="$1"
    label="${label} ";local n=0; while [[ $n -lt 55 && "${#label}" -lt 38 ]]; do n=$((n+1));label="${label}."; done
    echo "$label"
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
  local total=$((user_normal + user_nice + system))
  local uptime=$(GetUptimeInSeconds)
  # echo uptime in seconds: $uptime 
  
  local user_normal_formatted="$(format_seconds ${user_normal})"
  local user_nice_formatted="$(format_seconds ${user_nice})"
  local system_formatted="$(format_seconds ${system})"
  local total_formatted="$(format_seconds ${total})"
  local uptime_formatted="$(format_seconds ${uptime})"
  
  
  echo "User CPU Usage (normal priority) ..... $user_normal_formatted
User CPU Usage (low priority) ........ $user_nice_formatted
System CPU Usage ..................... $system_formatted
TOTAL CPU Usage ...................... $total_formatted
Uptime ............................... $uptime_formatted"
}

function FormatBytes() {
    local bytes=$1
    if [[ "$bytes" -lt 9000 ]]; then bytes="$bytes B"; 
    elif [[ "$bytes" -lt 9000000 ]]; then bytes=$((bytes/1024)); bytes="$bytes KB";
    elif [[ "$bytes" -lt 9000000000 ]]; then bytes=$((bytes/1048576)); bytes="$bytes MB";
    elif [[ "$bytes" -lt 9000000000000 ]]; then bytes=$((bytes/1073741824)); bytes="$bytes GB";
    else bytes=$((bytes/1099511627776)); bytes="$bytes TB";
    fi
    echo $bytes
}

function ShowNetStat() {
    if [[ ! -f /proc/net/dev ]]; then return; fi
    local line
    cat /proc/net/dev | sed -n '3,$p' | sort | while read line; do
        local name=$(echo $line | awk '{print $1}')
        if [[ "$name" == *":" ]]; then
            local recv=$(echo $line | awk '{print $2}')
            local sent=$(echo $line | awk '{print $10}')
            name=$(format_label "$name");
            if [[ "$sent" -gt 0 && "$recv" -gt 0 ]]; then
                sent=$(FormatBytes $sent)
                recv=$(FormatBytes $recv)
                local sent_formatted=`printf %-7s "$sent"`
                local recv_formatted=`printf %-7s "$recv"`
                echo "$name ${sent_formatted} [sent] + ${recv_formatted} [recieved]"
            fi  
        fi 
    done
}

function parseStat() {
    # args: statDir, statTitle
    local size="$(cat $statDir/size 2>/dev/null)"
    if [[ "$size" != "0" && "$size" != "" && "$size" -gt 0 ]]; then
        local line="$(cat $statDir/stat)";
        IO_MILLISECONDS=$(echo $line | awk '{print $10}');
        READ_SECTORS=$(echo $line | awk '{print $3}');
        WRITE_SECTORS=$(echo $line | awk '{print $7}');
        if [[ $IO_MILLISECONDS -gt 0 && $READ_SECTORS -gt 0 && $WRITE_SECTORS -gt 0 ]]; then
            local read=$(FormatBytes $((READ_SECTORS*512)))
            local wrote=$(FormatBytes $((WRITE_SECTORS*512)))
            local read_formatted=`printf %-7s "$read"`
            local wrote_formatted=`printf %-7s "$wrote"`
            local io_time_formatted=$(format_seconds $((IO_MILLISECONDS/1000)))
            local title_formatted=$(format_label "$statTitle")
            echo "$title_formatted ${wrote_formatted} [wrote] + ${read_formatted} [read], ${io_time_formatted} io"
        fi 
    fi
}

function ShowBlockStat() {
    local blockDirs=$(ls -1 /sys/block 2>/dev/null);
    for blockDirName in $blockDirs; do
        local blockDir=/sys/block/$blockDirName
        if [[ -d $blockDir ]]; then
            statDir="${blockDir}";
            statTitle="/dev/$(basename $blockDir)";
            parseStat
            volDirs=$(ls -1 $blockDir 2>/dev/null);
            for volDirName in $volDirs; do
                local volDir="$blockDir/$volDirName"
                # echo "VOL: $volDir" 
                if [[ -d $volDir ]]; then
                    statDir="${volDir}";
                    statTitle=" --- $(basename $volDirName)";
                    parseStat
                fi 
            done 
        fi
    done;
    
}

# while true; do clear; ShowSystemStat; sleep 2; done
ShowSystemStat
echo "------------NETWORK-------------------"
ShowNetStat
echo "------------DISKS---------------------"
ShowBlockStat
