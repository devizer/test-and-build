#!/usr/bin/env bash

# Possible $FILE_IO_BENCHMARK_OPTIONS: --eta=always --time_based
# KEEP_FIO_TEMP_FILES - non empty string keeps a file between benchmarks

function To_Lower_String() {
  # https://stackoverflow.com/questions/2264428/how-to-convert-a-string-to-lower-case-in-bash
  local a="$1"
  if [[ "$BASH_VERSION" == 3* ]]; then
    echo "$a" | awk '{print tolower($0)}'
  else
    echo "${a,,}"
  fi
}

function Trim_String() {
  # Works on bash 3.x and above
  # https://stackoverflow.com/a/3352015
  local var="$*"
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}
# echo "Trimmed: [$(Trim_String " Hello World! ")]"

function Extract_IOPS_from_Output() {
  local file="$1"
  cat "$file" | while IFS='' read -r line; do
    local cmd="$(echo $line | awk -F':' '{print $1}')"
    cmd="$(Trim_String "$cmd")"
    cmd="$(To_Lower_String "$cmd")"
    if [[ "$cmd" == "read" ]] || [[ "$cmd" == "write" ]]; then
      local tail="$(echo $line | awk -F':' '{print $2}')"
      # echo "TAIL: [$tail]"
      local tailPart;
      for tailPart in ${tail//,/ }
      do
        local header="$(echo "$tailPart" | awk -F'=' '{print $1}')"
        header="$(Trim_String "$header")"; header="$(To_Lower_String "$header")"; 
        if [[ "$header" == "iops" ]]; then
          local rawIops="$(echo "$tailPart" | awk -F'=' '{print $2}')"
          rawIops="$(Trim_String "$rawIops")"
          # rawIops is number or 123.4k
          echo "$rawIops" 
        fi
        # echo "HEADER=[$header]; Value=[$value]"
      done
    fi
  done
}
# sudo rm -f /usr/local/bin/File-IO-Benchmark; sudo nano /usr/local/bin/File-IO-Benchmark; sudo chmod +x /usr/local/bin/File-IO-Benchmark


function Has_Unicode() {
  if [[ -n "${FORCE_UNICODE:-}" ]]; then echo "true"; return; fi
  if [[ -n "${DISABLE_UNICODE:-}" ]]; then echo "false"; return; fi
  if [[ -z "${hasUnicode:-}" ]]; then
    if [[ "$(locale charmap 2>/dev/null)" == "UTF"* ]]; then
      hasUnicode="true"
    else
      hasUnicode="false"
    fi
  fi
  echo $hasUnicode
}

function Header() {
  local char_arrow='>'; local char_dash='-'
  if [[ "$(Has_Unicode)" == "true" ]]; then
    char_arrow='\U27A4'; char_dash='\U2500'
  fi
  local txt=$1
  local length=${#txt}
  local border="${char_dash}${char_dash}${char_dash}"; while [[ $length -gt 0 ]]; do border="${char_dash}${border}"; length=$((length-1)); done
  # if [[ "${NEXT_HEADER:-}" == "" ]]; then NEXT_HEADER=true; else echo ""; fi
  tput bold 2>/dev/null || true
  echo -e "${char_arrow} ${txt}"; echo -e $border
  tput sgr0 2>/dev/null || true
}

if [[ "$1" == "" || "$1" == "--help" ]]; then
echo "Usage: File-IO-Benchmark 'Root FS' / 1G 30 5
here 1G - working set size
     30 - test duration, in seconds
     5  - ramp duration (for VM, raids and ssd 30 seconds is recommended)
Possible \$FILE_IO_BENCHMARK_OPTIONS: --eta=always --time_based
"
exit 0;
fi

CAPTION=$1
DISK=$2
SIZE=$3
DURATION=$4
RAMP=$5

CAPTION=${CAPTION:-Current Folder}
DISK=${DISK:-$(pwd)}
SIZE=${SIZE:-1G}
DURATION=${DURATION:-30}
RAMP=${RAMP:-5}

export SYSTEM_VERSION_COMPAT=${SYSTEM_VERSION_COMPAT:-1}
OS_X_VER=$(sw_vers 2>/dev/null | grep BuildVer | awk '{print $2}' | cut -c1-2 || true); OS_X_VER=$((OS_X_VER-4)); [ "$OS_X_VER" -gt 0 ] || unset OS_X_VER

# DETECT io engine
if [[ -n "$OS_X_VER" ]] && [[ "$OS_X_VER" -gt 0 ]]; then ioengine=posixaio; else ioengine=libaio; fi
if [[ "$(uname -r)" == *"Microsoft" ]] || [[ "$(uname -s)" == "MINGW"* ]] || [[ "$(uname -s)" == "MSYS"* ]]; then ioengine=windowsaio; fi
if [[ -n "$FILE_IO_BENCHMARK_ENGINE" ]]; then ioengine=$FILE_IO_BENCHMARK_ENGINE; fi

# install fio
 if [[ "$(command -v fio 2>/dev/null)" == "" ]]; then
   if [[ "$(command -v apt-get 2>/dev/null)" != "" ]]; then
     echo "Installing fio using apt-get"
     sudo apt-get install -yqq fio >/tmp/fio-install.log 2>&1 || sudo apt-get install -yqq fio >/tmp/fio-install.log 2>&1 || sudo cat /tmp/fio-install.log
   elif [[ "$(command -v yum 2>/dev/null)" != "" ]]; then
     echo "Installing fio and toilet using yum"
     sudo yum install -y fio >/tmp/fio-install.log 2>&1 || sudo yum install -y fio >/tmp/fio-install.log 2>&1 || sudo cat /tmp/fio-install.log
   fi
 fi

# check libaio support
pushd "$DISK" >/dev/null
if [[ "$ioengine" == libaio ]]; then
if fio --name=CHECK_LIBAIO --ioengine=$ioengine --gtod_reduce=1 --filename=fiodiag.tmp --bs=4k --size=64k --runtime=1 --readwrite=randread >/dev/null 2>&1; then
  ioengine=libaio
else
  ioengine=posixaio
fi
fi

# check DIRECT IO
direct=0; direct_info="Direct IO: [Absent]"
if fio --name=CHECK_DIRECT_IO --ioengine=$ioengine --direct=1 --gtod_reduce=1 --filename=fiodig.tmp --bs=4k --size=64k --runtime=1 --readwrite=randread >/dev/null 2>&1; then
  direct=1; direct_info="Direct IO: [Present]"
fi
if [[ -f fiodiag.tmp ]]; then rm -f fiodiag.tmp; fi
popd >/dev/null

info="Detected IO Engine: [${ioengine}]. $direct_info"
echo "$info" # Header "$info"

errorCode=1; exitCode=0;

function go_fio_1test() {
  local cmd=$1
  local disk=$2
  local caption="$3"
  pushd "$disk" >/dev/null
  Header "$caption ($(pwd))"
  echo "Benchmark '$(pwd)' folder using '$cmd' test during $DURATION seconds and heating $RAMP secs, size is $SIZE"
  if [[ $cmd == "rand"* ]]; then
     fio_shell_cmd="fio $FILE_IO_BENCHMARK_OPTIONS --name=RUN_$cmd --randrepeat=1 --ioengine=$ioengine --direct=$direct --gtod_reduce=1 --filename=fiotest.tmp --bs=4k --iodepth=64 --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd --eta=always"
  else
     fio_shell_cmd="fio $FILE_IO_BENCHMARK_OPTIONS --name=RUN_$cmd --ioengine=$ioengine --direct=$direct --gtod_reduce=1 --filename=fiotest.tmp --bs=1024k --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd --eta=always"
  fi
  if [[ -n "$FILE_IO_BENCHMARK_DUMP_FOLDER" ]]; then
    fio_version="$(fio --version)"
    fio_version="${fio_version:-unknown}"
    mkdir -p "$FILE_IO_BENCHMARK_DUMP_FOLDER/$fio_version"
    fio_shell_cmd="$fio_shell_cmd | tee \"$FILE_IO_BENCHMARK_DUMP_FOLDER/$fio_version/$cmd.log\""
  fi
  set -o pipefail
  output="$(mktemp)"
  eval $fio_shell_cmd | tee "$output"
  if [[ $? == 0 ]]; then isError=0; else isError=1; fi
  exitCode=$((isError*errorCode + exitCode)); errorCode=$((errorCode*2))
  iops="$(Extract_IOPS_from_Output "$output")"
  # echo "..... iops=$iops"
  eval iops_$cmd=$iops
  rm -f "$output"
  popd >/dev/null
  echo ""
}
 
 function go_fio_4tests() {
   local disk=$1
   local caption=$2
   go_fio_1test read      $disk "${caption}: Sequential read"
   go_fio_1test write     $disk "${caption}: Sequential write"
   go_fio_1test randread  $disk "${caption}: Random read"
   go_fio_1test randwrite $disk "${caption}: Random write"
   if [[ -f $disk/fiotest.tmp ]] && [[ -z "${KEEP_FIO_TEMP_FILES:-}" ]]; then 
      rm -f $disk/fiotest.tmp; 
   fi
 }
 
 go_fio_4tests "$DISK" "$CAPTION"
 
 if [[ -n "$iops_read" ]] && [[ -n "$iops_write" ]] && [[ -n "$iops_randread" ]] && [[ -n "$iops_randwrite" ]]; then
   bold="$(tput bold 2>/dev/null)"; normal="$(tput sgr0 2>/dev/null)"
   echo "Summary:"
   echo "   Sequential Read: ${bold}$iops_read MB/s${normal}; Sequential Write: ${bold}$iops_write MB/s${normal}" 
   echo "   Random Read 4K: ${bold}$iops_randread IOPS${normal}; Random Write 4K: ${bold}$iops_randwrite IOPS${normal}"
 fi

 exit $exitCode
