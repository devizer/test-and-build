#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/test-and-build/master/lab/Install-DOCKER.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

if [[ ! "$ARCH" == i386 ]]; then
  Say "Installing the latest docker from the official docker repo"
  # Recommended: aufs-tools cgroupfs-mount | cgroup-lite pigz libltdl7
  source /etc/os-release
  lazy-apt-update
  smart-apt-install apt-transport-https ca-certificates curl gnupg2 software-properties-common 
  try-and-retry bash -c "curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo apt-key add -"

  try-and-retry sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  # second is optional
  # try-and-retry sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
  sudo add-apt-repository \
     "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$ID \
     $(lsb_release -cs) \
     stable"
  sudo apt-get update
  apt-cache policy docker-ce
  sudo apt-get install -y docker-ce pigz
  sudo docker version
  
  dock_comp_ver=1.25.0 # is not yet compiled for arm64
  dock_comp_ver=1.24.1 # compiled for both armv7 and v7
  dock_comp_ver=1.25.5 # compiled for both armv7 and v7
  Say "Installing docker-compose $dock_comp_ver"
  # sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  sudo curl --fail -ksSL -o /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/$dock_comp_ver/docker-compose-$(uname -s)-$(uname -m)" || true
  if [[ ! -f /usr/local/bin/docker-compose ]]; then
    sudo curl --fail -ksSL -o /usr/local/bin/docker-compose "https://raw.githubusercontent.com/devizer/test-and-build/master/docker-compose/$dock_comp_ver/docker-compose-$(uname -s)-$(uname -m)" || true    
  fi
  if [[ -f /usr/local/bin/docker-compose ]]; then
    sudo chmod +x /usr/local/bin/docker-compose
  else
    Say "docker-compose $dock_comp_ver can not be installed for $(uname -s) $(uname -m)" 
  fi
  
else
    Say "Installing the Docker 18.09.1, docker compose 1.21.0 (format 2.4) from debian repo "
    lazy-apt-update
    smart-apt-install  docker.io docker-compose pigz
fi

# 1.21
docker-compose version || (smart-apt-install docker-compose)

sudo systemctl status docker | head -n 88
docker version
docker-compose version

dockerVer="$(docker version --format '{{.Server.Version}}' 2>&1)"
Say "Installed Docker: $dockerVer"

dockerComposeVer="$(docker-compose version 2>&1)"
Say "Installed Docker Compose: $dockerComposeVer"

if [[ "$Alternative" ]]; then
    # 1st
    lazy-apt-update
    smart-apt-install python3-pip
    pip3 --version
    sudo pip3 install docker-compose
    
    # 2nd: main contrib non-free
    
    # 3rd (1.7 ... 1.9)
    echo "deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ jessie main" | sudo tee /etc/apt/sources.list.d/hypriot.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 37BBEE3F7AD95B3F
    apt update
    apt-cache policy docker-compose
    
    # 4th
    sudo curl -L --fail https://github.com/docker/compose/releases/download/1.24.1/run.sh -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose    
fi