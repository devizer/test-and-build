#!/usr/bin/env bash
set -e

function build_docker_compose() {
    echo "BUILDING docker-compose $DOCKER_COMPOSE_VER for $(uname -s)-$(uname -m)" 
    git checkout $DOCKER_COMPOSE_VER 
    time ./script/build/linux
    # pattern: dist/1.24.1/docker-compose-Linux-armv7l-1.24.1
    "./dist/docker-compose-$(uname -s)-$(uname -m)" version && (
        artifact="~/docker-compose-artifact/$DOCKER_COMPOSE_VER/docker-compose-$(uname -s)-$(uname -m)-$DOCKER_COMPOSE_VER"
        mkdir -p $(dirname $artifact) 
        sudo cp -f "./dist/docker-compose-$(uname -s)-$(uname -m)" $artifact
    ) || echo "Error building docker-compose $DOCKER_COMPOSE_VER"
}

lazy-apt-update
apt-get install python-pip git -y
systemctl start docker || true
command -v docker || (echo "Error. Install Docker first for this script"; exit 1)
 
work=/compose
mkdir -p $work
cd $work
git clone https://github.com/docker/compose || (cd compose; git checkout master; git pull)
cd $work/compose
lastThreeVersions=$(git tag --sort=-v:refname | egrep -o "^([0-9]{1,}\.)+[0-9]{1,}$" | head -3)
echo "Last three non-rc versions: $lastThreeVersions"
for DOCKER_COMPOSE_VER in $lastThreeVersions; do
    echo "next: $DOCKER_COMPOSE_VER"
    # build_docker_compose
    skip=skip;
done
 

DOCKER_COMPOSE_VER=1.24.1
build_docker_compose

