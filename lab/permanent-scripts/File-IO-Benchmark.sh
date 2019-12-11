#!/usr/bin/env bash

# TODO: doesnt work in stable way 
# V2
SIZE=1000M
RUNTIME=7
RAMP_TIME=15

# --ramp_time=$RAMP_TIME
ramp="--ramp_time=$RAMP_TIME"
# ramp=
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=$SIZE --readwrite=randread  --runtime=$RUNTIME $ramp 

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=$SIZE --readwrite=randwrite --runtime=$RUNTIME $ramp

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --iodepth=64 --size=$SIZE --readwrite=write --runtime=$RUNTIME $ramp

fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --iodepth=64 --size=$SIZE --readwrite=read  --runtime=$RUNTIME $ramp


FILE=fiobnch.42
SIZE=100M

      function go_fio_1test() {
        local cmd=$1
        local disk=$2
        local caption="$3"
        pushd "$disk" >/dev/null
        toilet -f term -F border "$caption ($(pwd))"
        echo "File-IO-Benchmark folder is '$(pwd)'"
SIZE=1G
RUNTIME=30
RAMP_TIME=10
SIZE=100M
RUNTIME=5
RAMP_TIME=1
fio --name=RAND_READ  --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest --bs=4k --iodepth=64 --size=$SIZE --runtime=$RUNTIME --ramp_time=$RAMP_TIME --readwrite=randread  
fio --name=RAND_WRITE --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest --bs=4k --iodepth=64 --size=$SIZE --runtime=$RUNTIME --ramp_time=$RAMP_TIME --readwrite=randwrite

        fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --runtime=30 --ramp_time=10 \
           --name=Read --stonewall --bs=1024k --iodepth=64 --size=$SIZE --readwrite=read --runtime=30 --ramp_time=10 \
           --name=Write --stonewall --bs=1024k --iodepth=64 --size=$SIZE --readwrite=write --runtime=30 --ramp_time=10 \
           --name=RandRead --stonewall --bs=4k --iodepth=64 --size=$SIZE --readwrite=randread --runtime=30 --ramp_time=10 \
           --name=RandWrite --stonewall --bs=4k --iodepth=64 --size=$SIZE --readwrite=randwrite --runtime=30 --ramp_time=10
        
        if [[ $cmd == "rand"* ]]; then
           fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=2G --readwrite=$cmd --runtime=30 --ramp_time=10
        else
           fio --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --size=2G --readwrite=$cmd --runtime=30 --ramp_time=10
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
        rm -f $disk/fiotest
      }
      
      sudo chown -R $(whoami) /mnt
      go_fio_4tests /mnt "sdb1 (default)"
      go_fio_4tests .    "sda1"
      
      file=/dev/sdb1
      path="/sdb1-accelerated"
      echo "Accelerating $file as $path"
      sudo mkdir -p "$path"
      sudo umount /mnt
      sudo mkfs.ext2 -L ext2-accelerated "$file"
      sudo mount -t ext2 "$file" "$path" -o rw,noatime,nodiratime,errors=remount-ro
      sudo chown -R $(whoami) "$path"
      df -h -T
      echo ""
      
      go_fio_4tests $path "sdb1 (Accelerated)"
      sudo umount "$path"

