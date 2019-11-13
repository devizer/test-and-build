#!/usr/bin/env bash

ephemeral_path=/.ephemeral
eph_disk=/dev/sdb

function move_folder() {
  folder=$1
  mkdir -p "${folder}"
  target_name="${ephemeral_path}/$(echo "${folder#/}" | tr / .)"
  mkdir -p "${target_name}"
  echo "Moving ${folder} to ${target_name}"
  cp -a "$folder" "${target_name}"
  rm -rf "$folder"
  ln -f -s "${target_name}/$(basename ${folder})" "$folder" 
}

e2label /dev/sda1 Debian

# create 1st volume
echo 'n
p



w
' | fdisk ${eph_disk}

fdisk -l ${eph_disk}

# format
mkfs.ext4 -L Ephemeral "${eph_disk}1"

# mount now
mkdir -p "${ephemeral_path}"
options=noatime,nodiratime,data=writeback,journal_async_commit
mount -t ext4 "${eph_disk}1" "${ephemeral_path}" -o "${options}"

# mount on reboot
echo '
'${eph_disk}1' '${ephemeral_path}' ext4 '${options}' 0 0
' | tee /etc/fstab

move_folder /home
move_folder /root 
move_folder /opt 
move_folder /tmp
move_folder /snap
move_folder /usr/games
move_folder /usr/include
move_folder /usr/local
move_folder /usr/share
move_folder /usr/src

# move_folder /var # ???????????? 
move_folder /var/lib/apt/lists
move_folder /var/cache/apt
move_folder /var/tmp
