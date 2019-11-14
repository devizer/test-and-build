#!/usr/bin/env bash
echo "Content of /etc/default/locale:"; cat /etc/default/locale
echo "-----------------"

sudo locale-gen "en_US.UTF-8" "en_GB.UTF-8"
echo '
LC_ALL="en_GB.UTF-8"
' | sudo tee /etc/default/locale > /dev/null
sudo timedatectl set-timezone UTC

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
