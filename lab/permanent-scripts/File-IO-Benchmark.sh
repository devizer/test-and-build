#!/usr/bin/env bash

if [[ "$1" == "" || "$1" == "--help" ]]; then
echo "Usage: File-IO-Benchmark 'Root FS' / 1G 30 5
here 1G - working set size
     30 - test duration, in seconds
     5  - ramp duration (for VM, raids and ssd 30 seconds is recommended)
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

if [[ -n "$OS_X_VER" ]] && [[ "$OS_X_VER" -gt 0 ]]; then ioengine=posixaio; else ioengine=libaio; fi
if [[ "$(uname -r)" == *"Microsoft" ]] || [[ "$(uname -s)" == "MINGW"* ]]; then ioengine=sync; fi

 if [[ "$(command -v fio 2>/dev/null)" == "" || "$(command -v toilet 2>/dev/null)" == "" ]]; then
   if [[ "$(command -v apt-get 2>/dev/null)" != "" ]]; then
     echo "Installing fio and toilet using apt-get"
     sudo apt-get install -yqq fio toilet >/tmp/fio-install.log 2>&1 || sudo apt-get install -yqq fio toilet >/tmp/fio-install.log 2>&1 || sudo cat /tmp/fio-install.log
   fi
 fi

echo '
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=1G --readwrite=randread
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=1G --readwrite=randwrite
' > /dev/null

function Header() {
  local txt=$1
  local length=${#txt}
  local border="---"; while [[ $length -gt 0 ]]; do border="-${border}"; length=$((length-1)); done
  if [[ "${NEXT_HEADER:-}" == "" ]]; then NEXT_HEADER=true; else echo ""; fi
  echo "> ${txt}"; echo $border
}

# check DIRECT IO
# echo checking direct io on [$DISK]
pushd "$DISK" >/dev/null
direct=0; direct_info="Direct IO: Absent"
if fio --name=CHECK_DIRECT_IO --ioengine=$ioengine --direct=1 --gtod_reduce=1 --filename=fiotest.tmp --bs=4k --size=64k --runtime=1 --readwrite=randread >/dev/null 2>&1; then
  direct=1; direct_info="Direct IO: Present"
fi
if [[ -f fiotest.tmp ]]; then rm -f fiotest.tmp; fi
popd >/dev/null

info="INFO> IO Engine: ${ioengine}. $direct_info"
Header "$info"

 function go_fio_1test() {
   local cmd=$1
   local disk=$2
   local caption="$3"
   pushd "$disk" >/dev/null
   toilet -f term -F border "$caption ($(pwd))" 2>/dev/null || Header "$caption ($(pwd))"
   echo "Benchmark '$(pwd)' folder using '$cmd' test during $DURATION seconds and heating $RAMP secs, size is $SIZE"
   if [[ $cmd == "rand"* ]]; then
      fio --name=RUN_$cmd --randrepeat=1 --ioengine=$ioengine --direct=$direct --gtod_reduce=1 --filename=fiotest.tmp --bs=4k --iodepth=64 --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd
   else
      fio --name=RUN_$cmd --ioengine=$ioengine --direct=$direct --gtod_reduce=1 --filename=fiotest.tmp --bs=1024k --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd
   fi
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
   if [[ -f $disk/fiotest.tmp ]]; then rm -f $disk/fiotest.tmp; fi
 }
 
 go_fio_4tests "$DISK" "$CAPTION"
