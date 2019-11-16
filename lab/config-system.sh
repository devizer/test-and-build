#!/usr/bin/env bash

# 1st parameter - swap size in megabytes
swapSizeMb=$1
# 2nd parameter - arch (i386, arm, arm64)
ARCH=$2

timedatectl set-timezone UTC

# echo "Content of /etc/default/locale:"; cat /etc/default/locale
# echo "-----------------"

export DEBIAN_FRONTEND=noninteractive
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
# locale-gen "en_US.UTF-8" "en_GB.UTF-8" "es_ES.UTF-8 UTF-8"
dpkg-reconfigure locales 

Say "Purge man-db"
lazy-apt-update; apt purge man-db

echo '
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
' | sudo tee /etc/default/locale > /dev/null

echo '
export LC_ALL="en_US.UTF-8"
export TZ=Europe/London
' | sudo tee -a ~/.bashrc > /dev/null
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

# SMART lazy-apt-update - only for built-in debian repos
echo '#!/usr/bin/env bash
ls -1 /var/lib/apt/lists/deb* >/dev/null 2>&1 || sudo apt update --allow-unauthenticated -qq
' > /usr/local/bin/lazy-apt-update
chmod +x /usr/local/bin/lazy-apt-update


Say "Adding user to nopasswd sudoers"
echo 'user    ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

echo '
ARCH='$ARCH'
export ARCH
' >> /home/user/.bashrc

echo '
export ARCH='$ARCH'
' >> ~/.bashrc

echo '
export ARCH='$ARCH'
' >> /home/user/.bashrc
chown user:user /home/user/.bashrc

echo '
#!/usr/bin/env bash
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
' > /home/user/.profile
chmod +x /home/user/.profile
chown user:user /home/user/.profile

sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config
sed -i 's/AcceptEnv LANG LC_\*//g' /etc/ssh/sshd_config
echo '
SetEnv ARCH='$ARCH'
' >> /etc/ssh/sshd_config
Say "SSH config below:"
cat /etc/ssh/sshd_config
systemctl restart ssh

mkdir -p /home/user/.ssh
echo '
#!/usr/bin/env bash
# export ARCH='$ARCH'
ARCH='$ARCH'
' > /home/user/.ssh/environment
chmod +x /home/user/.ssh/environment
chown -R user:user /home/user/.ssh

Say "Disable apparmor"
systemctl stop apparmor
systemctl disable apparmor

Say "Add user to sudo group"
usermod -aG sudo user
