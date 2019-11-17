#!/usr/bin/env bash
# should be run as ROOT

export NVM_DIR="/opt/nvm"
Say "Installing nvm to $NVM_DIR" 
mkdir -p "$NVM_DIR"
script=https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
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
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
' > /etc/profile.d/NVM.sh

# cat > /tmp/nvm-env << EOL
# NVM_DIR='$NVM_DIR'
# export NVM_DIR 
# [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
# EOL

# for file in "/etc/profile.d/nvm" "$HOME/.profile" "$HOME/.bashrc" "/home/user/.profile" "/home/user/.bashrc"; do
#    cat /tmp/nvm-env >> "$file"
#    chmod +x "$file"
#    if [[ "$file" == "/home/user"* ]]; then chown user:user "$file"; fi
#done

Say "Installing NodeJS LTS"

if [[ -n "$TRAVIS" ]]; then
# without optimization it is also slow
    export CFLAGS="-O0"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
fi

# if [[ "$INSTALL_NODE_FOR_i386" == "true" || "$ARCH" != i386 ]]; then 
    time nvm install --lts node  # 12.13
# fi
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


node_base=/home/user/.nvm/versions/node
node_path="${node_base}/$(ls -1 $node_base | sort -hr | head -1)bin"
Say "Pre-loaded NodeJS LTS Path: [${node_path}]"


pushd /tmp
# npx create-react-app my-react
# cd my-react
# yarn install # --verbose
# rm -rf 
# cd .. 
rm -rf my-react
popd


