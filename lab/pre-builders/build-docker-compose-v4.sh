#!/usr/bin/env bash
set -e
DOCKER_COMPOSE_VER=1.24.1
lazy-apt-update
apt install python-pip git -y
systemctl start docker || true
command -v docker || (echo "Error. Install Docker first for this script"; exit 1)
 
work=/compose
mkdir -p $work
cd $work
git clone https://github.com/docker/compose
cd compose
lastThreeVersions=$(git tag --sort=-v:refname | egrep -o "^([0-9]{1,}\.)+[0-9]{1,}$" | head -3)
echo $lastThreeVersions
git checkout $DOCKER_COMPOSE_VER

time ./script/build/linux
"./dist/docker-compose--$(uname -s)-$(uname -m)" version
