#!/usr/bin/env bash

if [[ ! "$ARCH" == i386 ]]; then
  Say "Installing the latest docker from the official docker repo"
  # Recommended: aufs-tools cgroupfs-mount | cgroup-lite pigz libltdl7
  source /etc/os-release
  lazy-apt-update
  smart-apt-install apt-transport-https ca-certificates curl gnupg2 software-properties-common 
  try-and-retry bash -c "curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo apt-key add -"

  try-and-retry sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  try-and-retry sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
  sudo add-apt-repository \
     "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$ID \
     $(lsb_release -cs) \
     stable"
  sudo apt-get update
  apt-cache policy docker-ce
  sudo apt-get install -y docker-ce pigz
  sudo docker version
  
  Say "Installing docker-compose 1.24.1"
  # sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  
else
    Say "Installing the Docker 18.09.1, docker compose 1.21.0 (format 2.4) from debian repo "
    lazy-apt-update
    smart-apt-install  docker.io docker-compose pigz
fi
sudo systemctl status docker | head -n 88
docker version
docker-compose version

dockerVer="$(docker version --format '{{.Server.Version}}' 2>&1)"
Say "Installed Docker: $dockerVer"

dockerComposeVer="$(docker-compose version 2>&1)"
Say "Installed Docker Compose: $dockerComposeVer"

