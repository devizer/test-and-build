#!/usr/bin/env bash

DOCKER_COMPOSE_VER=1.24.1
cmd='
apt update;
apt install python-pip git docker.io -y;
work=/compose;
mkdir -p $work;
cd $work;
git clone https://github.com/docker/compose;
cd compose;
git checkout '$DOCKER_COMPOSE_VER';
time ./script/build/linux;
"./dist/docker-compose--$(uname -s)-$(uname -m)" version;
'

docker run --rm --privileged multiarch/qemu-user-static:register --reset
for arch in "arm64" "armhf" "i386" ; do
    image=multiarch/debian-debootstrap:${arch}-stretch
    container=dc-${arch}
    docker run -d --name $container -t "${image}" bash -c 'sleep 424242' || docker start $container   
    echo -e "\n\n"
    docker exec $container bash -c "uname -m"
    docker exec $container bash -c "$cmd"
 done
    