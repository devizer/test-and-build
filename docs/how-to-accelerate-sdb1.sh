file=/dev/sdb1
path="/sdb1-accelerated"
sudo mkdir -p "$path"
sudo umount /mnt
mkfs.ext2 -f -L ext2-accelerated "$file"
sudo mount -t ext2 "$file" "$path" -o defaults,noatime,nodiratime,


if [ true ]; then
    
    
else
    file="/mnt/BTRFS.disk"
    sudo dd if=/dev/zero of="/$file" bs=1 seek=12800M count=1
fi

sudo mkfs.btrfs -f -L a-disk "$file" -O ^extref,^skinny-metadata
echo "MOUNTING $file as $path"
sudo mount -t btrfs "$file" "$path" -o defaults,noatime,nodiratime,compress-force
sudo chown $(whoami) $path
touch $path/hi
df -T -h
