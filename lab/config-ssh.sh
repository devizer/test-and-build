#!/usr/bin/env bash

# 1st parameter - arch (i386, arm, arm64)
ARCH=$1

# COMMAND LINE TOOLS
for f in "Say" "try-and-retry" "smart-apt-install" "lazy-apt-update"; do
    sudo cp permanent-scripts/${f}.sh /usr/local/bin/${f}
    chmod +x /usr/local/bin/${f}
done

echo "Say command: $(command -v Say)"

sshId=$(pgrep -f "sshd -D")
Say "Configure ssh environment and restarting ssh server (id is $sshId)"
Say "Restarting ssh server"
sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config
sed -i 's/AcceptEnv LANG LC_\*//g' /etc/ssh/sshd_config
sed -i 's/#Compression delayed/Compression no/g' /etc/ssh/sshd_config
echo '
SetEnv ARCH='$ARCH'
AcceptEnv Build_*
' >> /etc/ssh/sshd_config

echo '
export SORRY_BASH_completion_is_ALIVE_and_Kicking=true
' >> /etc/profile.d/bash_completion.sh

sudo -u user mkdir -p /home/user/bin /home/user/.ssh
echo "A_VAR_for_USER_via_SSH_Environment='here is it'" | sudo -u user tee -a /home/user/.ssh/environment


# systemctl restart ssh
# sudo kill -SIGHUP $sshId
Say "SSH server will be restarted. The /etc/ssh/sshd_config is below"
cat /etc/ssh/sshd_config

if [[ false ]]; then 
    # TODO: extract it as a destructive separated command
    sshId="$(pgrep -f "sshd -D")"; Say "Restarting SSH Server (id is $sshId)"; sudo kill -SIGHUP "$(pgrep -f "sshd -D")"; Say "Restarted SSH Server";
fi

function config_loc() {
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
'   | sudo tee /etc/default/locale > /dev/null
    # locale-gen "en_US.UTF-8" "en_GB.UTF-8" "es_ES.UTF-8 UTF-8"
    dpkg-reconfigure locales

}

config_loc