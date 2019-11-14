#!/usr/bin/env bash
script=https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

echo '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
' >> ~/.bashrc

# nvm install --lts node  # 10.16.3
time nvm install node          # 12.12
time npm install yarn npm npx npm-check-updates --global
time yarn config set network-timeout 600000 -g

pushd /tmp
npx create-react-app my-react
cd my-react
yarn install
popd
