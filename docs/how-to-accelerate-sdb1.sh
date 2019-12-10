file=/dev/sdb1
path="/sdb1-accelerated"
sudo mkdir -p "$path"
sudo umount /mnt
mkfs.ext2 -f -L ext2-accelerated "$file"
sudo mount -t ext2 "$file" "$path" -o rw,noatime,nodiratime,errors=remount-ro

