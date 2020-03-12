#!/usr/bin/env bash

work=~/build/ubiquiti.docker-compose-aarch64
mkdir -p $work
pushd $work
git clone https://github.com/ubiquiti/docker-compose-aarch64 || true
cd docker-compose-aarch64
git pull --all

rm -f docker-compose*
time docker build . -t docker-compose-aarch64-builder
time docker run --rm -v "$(pwd)":/dist docker-compose-aarch64-builder
file docker-compose*
# popd

