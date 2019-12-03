#!/usr/bin/env bash

# 1st parameter - arch (i386, arm, arm64)
ARCH=$1

# COMMAND LINE TOOLS
for f in "Say" "Show-System-Stat" "try-and-retry" "smart-apt-install" "lazy-apt-update" "list-packages"; do
    if [[ -f permanent-scripts/${f}.sh ]]; then
        sudo cp permanent-scripts/${f}.sh /usr/local/bin/${f}
    else
        echo "Downloading https://raw.githubusercontent.com/devizer/test-and-build/master/lab/permanent-scripts/${f}.sh"
        cmd="sudo curl -ksSL -o /usr/local/bin/${f} https://raw.githubusercontent.com/devizer/test-and-build/master/lab/permanent-scripts/${f}.sh"
        eval $cmd || eval $cmd || eval $cmd
    fi
    chmod +x /usr/local/bin/${f}
done

function config_loc() {
    # echo "Content of /etc/default/locale:"; cat /etc/default/locale
    # echo "-----------------"

    # Say "Configure locales"
    export DEBIAN_FRONTEND=noninteractive
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    # echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo '
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
'   | sudo tee /etc/default/locale > /dev/null
    # locale-gen "en_US.UTF-8" "en_GB.UTF-8" "es_ES.UTF-8 UTF-8"
    dpkg-reconfigure locales

}

for s in 'cron' 'unattended-upgrades' 'apt-daily-upgrade.timer' 'apt-daily.timer' 'logrotate.timer'; do
    Say "Stop and disable [$s]"
    systemctl stop $s
    systemctl disable $s
done

config_loc
echo "Say command: $(command -v Say)"


Say "Configure ssh environment"
sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config
sed -i 's/AcceptEnv LANG LC_\*//g' /etc/ssh/sshd_config
sed -i 's/#Compression delayed/Compression no/g' /etc/ssh/sshd_config
echo '
SetEnv ARCH='$ARCH'
# Next Line doesnt work
AcceptEnv Build_* APPVEYOR* TRAVIS* BUILD_*
' >> /etc/ssh/sshd_config

echo '
export SORRY_BASH_completion_is_ALIVE_and_Kicking=true
' >> /etc/profile.d/bash_completion.sh

mkdir -p ~/bin
sudo -u user mkdir -p /home/user/bin /home/user/.ssh
echo "A_VAR_for_USER_via_SSH_Environment='here is it'" | sudo -u user tee -a /home/user/.ssh/environment

# systemctl restart ssh
# sudo kill -SIGHUP $sshId
Say "SSH server will be restarted. The /etc/ssh/sshd_config is below"
cat /etc/ssh/sshd_config

if [[ false ]]; then 
    # TODO: extract it as a destructive separated command
    # sshId="$(pgrep -f "sshd -D")"; Say "Restarting SSH Server (id is $sshId)"; sudo kill -SIGHUP "$(pgrep -f "sshd -D")"; Say "Restarted SSH Server";
    x=42;
fi

e2label /dev/sda1 Debian || true
true