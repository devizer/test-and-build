#!/usr/bin/env bash

# 1st parameter - swap size in megabytes
swapSizeMb=$1

sudo timedatectl set-timezone UTC

echo "Content of /etc/default/locale:"; cat /etc/default/locale
echo "-----------------"

sudo locale-gen "en_US.UTF-8" "en_GB.UTF-8"
echo '
LC_ALL="en_GB.UTF-8"
' | sudo tee /etc/default/locale > /dev/null

echo '
export LC_ALL="en_GB.UTF-8"
export TZ=Europe/London
' | sudo tee ~/.bashrc > /dev/null
sudo timedatectl set-timezone UTC

# cat /tmp/build/Say.sh >> ~/.bashrc
# cat /tmp/build/Say.sh >> ~/.profile
sudo cp /tmp/build/Say.sh /usr/local/bin/Say
chmod +x /usr/local/bin/Say

# apt-get install -qq libunwind8 -y 
echo "Environment:"; 
printenv | sort
echo "-----------------"

echo "Info: /etc/localtime is a symlink to [$(readlink /etc/localtime)]"
echo "Finally, try a sudo command"
sudo true

echo '
APT::Install-Recommends "0";
' | sudo tee /etc/apt/apt.conf.d/42NoRecommend >/dev/null

if [[ -n "${swapSizeMb}" ]]; then
    Say "Creating swap file $swapSizeMb Mb as /tmp/swap"
    sudo dd if=/dev/zero of=/tmp/swap bs=1M count=${swapSizeMb}
    sudo mkswap /tmp/swap
    sudo swapon /tmp/swap
 fi

currentSwap=$(free -m | grep Swap | awk '{print $2}')
Say "Current Swap Size: $currentSwap MB" 

# SMART apt-update - only for built-in debian repos
echo '#!/usr/bin/env bash
ls -1 /var/lib/apt/lists/deb* >/dev/null 2>&1 || sudo apt update --allow-unauthenticated
' > /usr/local/bin/apt-update
chmod +x /usr/local/bin/apt-update

