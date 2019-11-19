#!/usr/bin/env bash
lazy-apt-update
apt-get -y install sudo subversion git p7zip-full wget htop ncdu iotop curl ca-certificates sudo \
   subversion git p7zip-full wget htop iotop curl ca-certificates \
   build-essential autoconf autoconf pkg-config libssl-dev \
   zlib1g zlib1g-dev make pv libncurses5-dev libncurses5 libncursesw5-dev libncursesw5 gettext \
   libgdiplus pv \
   cmake \
   ffmpeg imagemagick

apt clean

