#!/usr/bin/env bash

DOCKER_COMPOSE_VER=1.24.1
cmd='
work=~/build/docker-compose
mkdir -p $work
cd $work
git clone https://github.com/docker/compose
cd compose
git checkout '$DOCKER_COMPOSE_VER'
./script/build/linux
"./dist/docker-compose--$(uname -s)-$(uname -m)" version
'

for arch in "i386" "arm32v7" "arm64v8"; do
    arch=arm64v8
    image="${arch}/python:stretch"
    container="dc-$arch"
    docker pull "${image}"
    docker rm -f $container; 
    docker run --name $container -h "dc-$arch" -t $image sh -c 'uname -a'
    # docker start $container 
    docker exec $container bash -c uname -a
done
