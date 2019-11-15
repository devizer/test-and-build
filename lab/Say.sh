#!/usr/bin/env bash

    function print_header() {
      # if [[ -e /tmp/
      SYSTEM="${SYSTEM:-$(uname -s)}"
      if [[ ${SYSTEM} != Darwin ]]; then
          uptime=$(</proc/uptime);                  # 42645.93 240538.58
          IFS=' ' read -ra uptime <<< "$uptime";    # 42645.93 240538.58
          uptime="${uptime[0]}";                    # 42645.93
          uptime=$(printf "%.0f\n" "$uptime")       # 42645
          uptime=$(TZ=UTC date -d "@${uptime}" "+%H:%M:%S");
      fi
      Blue='\033[1;34m'; Gray='\033[1;37m'; LightGreen='\033[1;32m'; Yellow='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'; LightGray='\033[1;2m';
      printf "${Blue}$(hostname)${NC} ${LightGray}${uptime:-}${NC} ${LightGreen}$1${NC} ${Yellow}$2${NC}\n"; 
    }
    function SayIt() { 
      user="${LOGNAME:-$(whoami)}"
      user="${LOGNAME:-$(whoami)}"
      file="/tmp/.${user}-said-counter"
      if [[ -e "$file" ]]; then counter=$(< "$file"); else counter=1; fi
      print_header "#${counter}" "$1";
      counter=$((counter+1));
      echo $counter > "$file"
    }; 

SayIt "$@"
