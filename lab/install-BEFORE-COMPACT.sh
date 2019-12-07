#!/usr/bin/env bash
# sudo /etc/cron.daily/logrotate
echo '#!/usr/bin/env bash
cd /var/log
printf "\nDELETE LOGS in /var/log: "
for f in $(sudo find .); do
  if [[ -f "$f" ]]; then printf "$f "; sudo rm -f "$f"; fi
done
echo ""

sudo yum clean all || true
dotnet nuget locals all --clear || true

cd /
rm -rf $HOME/.cache/mozilla
rm -rf $HOME/.cache/google-chrome

sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /var/cache/apt/*
sudo rm -rf /var/tmp/*
sudo rm -rf /tmp/*

df -hT | grep -E /$
' | sudo tee /usr/local/bin/del-cache >/dev/null
sudo chmod +x /usr/local/bin/del-cache

echo '#!/usr/bin/env bash
del-cache
sudo bash -c "rm -f /zero; touch /zero; btrfs property set /zero compression \"\"; chattr -c /zero; time (dd if=/dev/zero bs=1M | pv >> /zero; rm -f /zero)"
' | sudo tee /usr/local/bin/before-compact >/dev/null
sudo chmod +x /usr/local/bin/before-compact

echo '#!/bin/bash
sync
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
' | sudo tee /usr/bin/drop-caches >/dev/null
sudo chmod 755 /usr/bin/drop-caches
