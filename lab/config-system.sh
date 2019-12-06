#!/usr/bin/env bash

# 1st parameter - swap size in megabytes
swapSizeMb=$1
# systemctl restart ssh
# sudo kill -SIGHUP $sshId

Say "Set UTC time-zone"
timedatectl set-timezone UTC

Say "Purge man-db"
lazy-apt-update; apt purge man-db | grep -vE 'Reading database.*(%|\.\.\. )$'

echo "Environment:"; 
printenv | sort
echo "-----------------"

echo "Info: /etc/localtime is a symlink to [$(readlink /etc/localtime)]"
echo "Finally, try a sudo command"
sudo true

echo '
APT::Install-Recommends "0";
' | sudo tee /etc/apt/apt.conf.d/42NoRecommend >/dev/null

if [[ "${swapSizeMb}" -gt 0 ]]; then
    Say "Creating swap file $swapSizeMb Mb as /tmp/swap"
    sudo dd if=/dev/zero of=/tmp/swap bs=1048577 count=${swapSizeMb}
    sudo mkswap /tmp/swap
    sudo swapon /tmp/swap
 fi

currentSwap=$(free -m | grep Swap | awk '{print $2}')
Say "Current Swap Size: $currentSwap MB" 


Say "Adding user to nopasswd sudoers"
echo 'user    ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

# https://www.kernel.org/doc/Documentation/security/apparmor.txt
Say "Disable apparmor"
systemctl stop apparmor
systemctl disable apparmor

Say "Add user to sudo group"
usermod -aG sudo user

# https://en.wikibooks.org/wiki/OpenSSH/Client_Configuration_Files#~/.ssh/rc
# echo 'PATH="$PATH:/tmp"' >> /home/user/.ssh/environment
# echo 'export PATH="$PATH:/usr"' >> /home/user/.ssh/environment

echo '#!/usr/bin/env bash
if [[ -d "$HOME/bin" ]]; then
    PATH="$PATH:$HOME/bin"
    export PATH
fi
' > /etc/profile.d/Path-To-Bin-At-Home.sh

bash install-BEFORE-COMPACT.sh
