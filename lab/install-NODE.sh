#!/usr/bin/env bash
# should be run as ROOT

export NVM_DIR="/opt/nvm"
Say "Installing nvm to $NVM_DIR" 
mkdir -p "$NVM_DIR"
# 0.35.0 doesnt work on AMD64 without kvm
script=https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh; 
(wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
chown user:user -R "$NVM_DIR" 
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

is_386="$(uname -m | grep -E 'i.86' 2>/dev/null)"

if [[ "$ARCH" == i386 ]]; then
    Say "Installing build-essential"
    lazy-apt-update
    time sudo apt-get install build-essential libssl-dev -y
    apt clean -qq
fi

echo '#!/usr/bin/env bash
NVM_DIR=/opt/nvm
if [[ -s "$NVM_DIR/nvm.sh" ]]; then 
    . "$NVM_DIR/nvm.sh"  # This loads nvm
else
    unset NVM_DIR
fi 
' > /etc/profile.d/NVM.sh

Say "Installing NodeJS LTS"

if [[ -n "$TRAVIS" ]]; then
# without optimization it is also slow
    export CFLAGS="-O0"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
fi

time nvm install --lts # node  # 12.13
nvm cache clear
df -h
# Say "Installing NodeJS LATEST"
# time nvm install node          # 12.12
Say "Default NodeJS version: $(nvm current)"
# Say "switch to latest stable"
# nvm use node
# Say "New NodeJS version: $(nvm current)"
Say "Upgrading NPM & NPX, installing YARN"
# time npm install yarn npm npx npm-check-updates --global
time npm install yarn --global
time yarn config set network-timeout 600000 -g



pushd /tmp
# npx create-react-app my-react
# cd my-react
# yarn install # --verbose
# rm -rf 
# cd .. 
rm -rf my-react
popd

sed -i '/bash_completion/d' ~/.bashrc
Say "Deleted bash_completion from ~/.bashrc. Content of ~/.bashrc after cleanup"
cat ~/.bashrc

