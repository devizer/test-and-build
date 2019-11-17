#!/usr/bin/env bash

# 1st parameter - swap size in megabytes
swapSizeMb=$1
# 2nd parameter - arch (i386, arm, arm64)
ARCH=$2


sudo cp /tmp/build/Say.sh /usr/local/bin/Say
chmod +x /usr/local/bin/Say

sudo cp /tmp/build/Add-Shared-Env.sh /usr/local/bin/Add-Shared-Env
chmod +x /usr/local/bin/Add-Shared-Env

sshId=$(pgrep -f "sshd -D")
Say "Configure ssh environment and restarting ssh server (id is $sshId)"
Say "Restarting ssh server"
sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config
sed -i 's/AcceptEnv LANG LC_\*//g' /etc/ssh/sshd_config
echo '
SetEnv ARCH='$ARCH'
' >> /etc/ssh/sshd_config
# systemctl restart ssh
sudo kill -SIGHUP $sshId
Say "Restarted ssh server. The /etc/ssh/sshd_config is below"
cat /etc/ssh/sshd_config

# SMART lazy-apt-update - only for built-in debian repos
echo '#!/usr/bin/env bash
ls -1 /var/lib/apt/lists/deb* >/dev/null 2>&1 || {
    Say "Updating apt metadata (/var/lib/apt/lists/)"
    sudo apt update --allow-unauthenticated -qq
}
' > /usr/local/bin/lazy-apt-update
chmod +x /usr/local/bin/lazy-apt-update


Say "Set UTC time-zone"
timedatectl set-timezone UTC

# echo "Content of /etc/default/locale:"; cat /etc/default/locale
# echo "-----------------"

Say "Configure locales"
export DEBIAN_FRONTEND=noninteractive
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo '
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
' | sudo tee /etc/default/locale > /dev/null
# locale-gen "en_US.UTF-8" "en_GB.UTF-8" "es_ES.UTF-8 UTF-8"
dpkg-reconfigure locales 

Say "Purge man-db"
lazy-apt-update; apt purge man-db

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


Say "Adding user to nopasswd sudoers"
echo 'user    ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

Say "Disable apparmor"
systemctl stop apparmor
systemctl disable apparmor

Say "Add user to sudo group"
usermod -aG sudo user

# https://en.wikibooks.org/wiki/OpenSSH/Client_Configuration_Files#~/.ssh/rc
echo "export Var_WITH_Export=here" >> /home/user/.ssh/environment
echo "Var_WITHOUT_Export=here" >> /home/user/.ssh/environment
# echo 'PATH="$PATH:/tmp"' >> /home/user/.ssh/environment
# echo 'export PATH="$PATH:/usr"' >> /home/user/.ssh/environment

sudo -u user mkdir -p /home/user/bin 
mkdir -p /home/user/bin 
echo '#!/usr/bin/env bash
if [[ -d "$HOME/bin" ]]; then
    export PATH="$PATH:$HOME/bin"
fi
' > /etc/profile.d/Path-To-Bin-At-Home.sh


# chown user:user /home/user/.profile
