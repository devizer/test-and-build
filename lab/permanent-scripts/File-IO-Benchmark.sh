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

# echo one IOPS line per job (123, 19.5k, etc)
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

function Parse_Human_Number() { 
  local raw="$1"
  # [bash 3.2] error -1: substring expression < 0
  if [[ "${raw}" == *k ]] || [[ "${raw}" == *K ]]; then 
      raw="${raw::${#raw}-1}"; 
      raw="$(awk -v t="$raw" 'BEGIN { print t * 1000}')";
  elif [[ "${raw}" == *m ]] || [[ "${raw}" == *M ]]; then 
      raw="${raw::${#raw}-1}"; 
      raw="$(awk -v t="$raw" 'BEGIN { print t * 1000000}')";
  fi
  echo "${raw}"
}
# echo "Parse_Human_Number. 0=$(Parse_Human_Number "0"), 1234.56k=$(Parse_Human_Number "1234.56k"), 7654=$(Parse_Human_Number "7654"), 1.234m=$(Parse_Human_Number "1.234m"), k=$(Parse_Human_Number "k")"

function Format_Thousand() {
  local num="$1"
  # LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$num" # but it is locale dependent
  # Next is locale independent version for positive integers
  awk -v n="$num" 'BEGIN { len=length(n); res=""; for (i=0;i<=len;i++) { res=substr(n,len-i+1,1) res; if (i > 0 && i < len && i % 3 == 0) { res = "," res } }; print res }' 2>/dev/null || echo "$num"
}
# printf "\n1\n10\n100\n1000\n10000\n100000\n1000000\n10000000\n100000000\n" | while read -r n; do echo "[$n]: '$(Format_Thousand "$n")'"; done


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
or     File-IO-Benchmark 'Root FS' / 1G 4T 30 5
here 1G - working set size
     4T - 4 concurrent jobs (threads) for random access benchmark, recommended for nvme, intel optane, etc.
     30 - test duration, in seconds
     5  - ramp duration (for VM, raids and ssd 30 seconds is recommended)
Possible \$FILE_IO_BENCHMARK_OPTIONS: --time_based, etc
"
exit 0;
fi

CAPTION=$1
DISK=$2
SIZE=$3
if [[ "$4" == *T ]]; then
  NUMJOBS="$4"
  NUMJOBS="${NUMJOBS::${#NUMJOBS}-1}"; 
  DURATION=$5
  RAMP=$6
else
  NUMJOBS=1
  DURATION=$4
  RAMP=$5
fi

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
  local type=$2
  local numjobs=$3
  local disk=$4
  local caption="$5"
  pushd "$disk" >/dev/null
  Header "$caption ($(pwd))"
  echo "Benchmark '$(pwd)' folder using '$cmd' test during $DURATION seconds and heating $RAMP secs, size is $SIZE"
  if [[ $cmd == "rand"* ]]; then
     fio_shell_cmd="fio $FILE_IO_BENCHMARK_OPTIONS --name=RUN_$cmd --randrepeat=1 --ioengine=$ioengine --direct=$direct --gtod_reduce=1 --filename=fiotest.tmp --bs=4k --iodepth=64 --numjobs=$numjobs --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd --eta=always"
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
  # output="$(mktemp)"
  if [[ "$(uname -s)" == Darwin ]]; then output="$(mktemp -t fio-output)"; else output="$(mktemp)"; fi
  eval $fio_shell_cmd | tee "$output"
  if [[ $? == 0 ]]; then isError=0; else isError=1; fi
  exitCode=$((isError*errorCode + exitCode)); errorCode=$((errorCode*2))
  local iopsRaw="$(Extract_IOPS_from_Output "$output")"
  # echo "..... iops=$iops for cmd=$cmd"
  # Trim first line. TODO: Sum line by line
  local sumIops;
  sumIops="$(echo $iopsRaw | awk 'NR==1{print $1}')"
  sumIops=0;
  while IFS= read -r iops1raw; do
    local iops1="$(Parse_Human_Number "$iops1raw")";
    # echo "  ......... iops1 = [$iops1] by raw value '$iops1raw'"
    sumIops=$((sumIops+iops1))
    # echo "  ......... iops1 = [$iops1], sumIops = [$sumIops]"
  done < <(printf '%s\n' "$iopsRaw")
  eval iops_$type=$sumIops
  rm -f "$output"
  popd >/dev/null
  echo ""
}
 
 function go_fio_4tests() {
   local disk=$1
   local caption=$2
   go_fio_1test read read            1        $disk "${caption}: Sequential read"
   go_fio_1test write write          1        $disk "${caption}: Sequential write"
   go_fio_1test randread randread1   1        $disk "${caption}: Random read"
   go_fio_1test randwrite randwrite1 1        $disk "${caption}: Random write"
   if [[ "$NUMJOBS" != 1 ]]; then
   go_fio_1test randread randreadN   $NUMJOBS $disk "${caption}: Random read $NUMJOBS jobs"
   go_fio_1test randwrite randwriteN $NUMJOBS $disk "${caption}: Random write $NUMJOBS jobs"
   fi
   if [[ -f $disk/fiotest.tmp ]] && [[ -z "${KEEP_FIO_TEMP_FILES:-}" ]]; then 
      rm -f $disk/fiotest.tmp; 
   fi
 }
 
 go_fio_4tests "$DISK" "$CAPTION"
 
bold="$(tput bold 2>/dev/null)"; normal="$(tput sgr0 2>/dev/null)"
 if [[ -n "$iops_read" ]] && [[ -n "$iops_write" ]]; then
   echo "Summary:"
   echo "   Sequential Read: ${bold}$iops_read MB/s${normal}; Sequential Write: ${bold}$iops_write MB/s${normal}" 
 fi
 if [[ -n "$iops_randread1" ]] && [[ -n "$iops_randwrite1" ]]; then
   echo "   Random 4K Read: ${bold}$(Format_Thousand "$iops_randread1") IOPS${normal}; Random Write 4K: ${bold}$(Format_Thousand "$iops_randwrite1") IOPS${normal}"
 fi
 if [[ -n "$iops_randreadN" ]] && [[ -n "$iops_randwriteN" ]]; then
   echo "   Random 4K Read $NUMJOBS jobs: ${bold}$(Format_Thousand "$iops_randreadN") IOPS${normal}; Random 4K Write $NUMJOBS jobs: ${bold}$(Format_Thousand "$iops_randwriteN") IOPS${normal}"
 fi

 exit $exitCode
