#!/usr/bin/env bash

  function get_stopwatch_file_name() {
    user="${LOGNAME:-$(whoami)}"
    file1="/tmp/.${user}-stopwatch-for-say"
    echo $file1
  }

  function get_counter_file_name() {
    user="${LOGNAME:-$(whoami)}"
    file2="/tmp/.${user}-counter-for-say"
    echo $file2
  }
  
  function format2digits() {
    if [[ $1 -gt 9 ]]; then echo $1; else echo 0$1; fi
  }

  function get_global_seconds() {
    theSYSTEM="${theSYSTEM:-$(uname -s)}"
    if [[ ${theSYSTEM} != "Darwin" ]]; then
        # uptime=$(</proc/uptime);                                # 42645.93 240538.58
        uptime="$(cat /proc/uptime 2>/dev/null)";                 # 42645.93 240538.58
        if [[ -z "${uptime:-}" ]]; then
          # secured, use number of seconds since 1970
          echo "$(date +%s)"
          return
        fi
        IFS=' ' read -ra uptime <<< "$uptime";                    # 42645.93 240538.58
        uptime="${uptime[0]}";                                    # 42645.93
        uptime=$(LC_ALL=C LC_NUMERIC=C printf "%.0f\n" "$uptime") # 42645
        echo $uptime
    else 
        # https://stackoverflow.com/questions/15329443/proc-uptime-in-mac-os-x
        boottime=`sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//g'`
        unixtime=`date +%s`
	    timeAgo=$(($unixtime - $boottime))
	    echo $timeAgo
    fi
  }

  function format_total_seconds() {
    timeAgo=$1
    seconds1=$((timeAgo % 86400));
    seconds=$((seconds1 % 60));
    minutes1=$((seconds1 / 60));
    minutes=$((minutes1 % 60));
    hours=$((minutes1 / 60));
    echo "$(format2digits $hours):$(format2digits $minutes):$(format2digits $seconds)"
  }

  function print_header() {
    global_seconds="$(get_global_seconds)"

    # zero is 0?
    stopwatch_file="$(get_stopwatch_file_name)"
    if [[ -s "$stopwatch_file" ]]; then
      zero_seconds=$(<$stopwatch_file)
      global_seconds=$((global_seconds-zero_seconds))
    fi
    
    uptime="$(format_total_seconds $global_seconds)"

    black_circle='\xE2\x97\x8f'
    white_circle='\xE2\x97\x8b'
    # BUILD_DEFINITIONNAME
    # if [[ -z "$BUILD_DEFINITIONNAME" ]]; then 
    if [[ -z "$SAY_COLORLESS" ]]; then # skip colors for azure pipelines
      Blue='\033[1;34m'; Gray='\033[1;37m'; LightGreen='\033[1;32m'; Yellow='\033[1;33m'; 
      LightRED='\033[1;31m'; RED='\033[0;31m'; LightGray='\033[1;2m';
      NC='\033[0m';
    fi
    hostname="$(hostname 2>/dev/null)"
    hostname="${hostname:-$HOSTNAME}"
    message_color="${Yellow}"
    [[ "${MESSAGE_TYPE}" == Error ]] && message_color="${LightRED}"
    printf "${Blue}${black_circle} ${hostname}${NC} ${LightGray}[${uptime:-}]${NC} ${LightGreen}$1${NC} ${message_color}"; echo -n "$2"; printf "${NC}\n";
    echo "${hostname} ${uptime:-} $1 $2" >> "/tmp/Said-by-$(whoami).log" 2>/dev/null 
  }

  function SayIt() { 
    counter_file="$(get_counter_file_name)"
    if [[ -e "$counter_file" ]]; then counter=$(< "$counter_file"); else counter=1; fi
    print_header "#${counter}" "$1";
    counter=$((counter+1));
    echo $counter > "$counter_file"
  }; 


if [[ "$1" == "--Reset-Stopwatch" ]]; then
  echo "$(get_global_seconds)" > "$(get_stopwatch_file_name)"
  echo 1 > "$(get_counter_file_name)"
  exit 0;
fi

if [[ "${1:-}" == "--Display-As="* ]]; then
  option="${1}";
  MESSAGE_TYPE="Info";
  [[ "${option:-}" == "--Display-As=Error" ]] &&   MESSAGE_TYPE="Error"
  [[ "${option:-}" == "--Display-As=Warning" ]] && MESSAGE_TYPE="Warning"
  shift
fi

SayIt "$@"
