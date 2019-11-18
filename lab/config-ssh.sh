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
# systemctl restart ssh
sudo kill -SIGHUP $sshId
Say "Restarted ssh server. The /etc/ssh/sshd_config is below"
cat /etc/ssh/sshd_config

if [[ false ]]; then 
    # TODO: extract it as a destructive separated command
    sshId="$(pgrep -f "sshd -D")"; Say "Restarting SSH Server (id is $sshId)"; sudo kill -SIGHUP "$(pgrep -f "sshd -D")"; Say "Restarted SSH Server";
fi
