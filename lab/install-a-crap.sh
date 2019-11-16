#!/usr/bin/env bash
lazy-apt-update
apt-get -y install sudo subversion git p7zip-full wget htop ncdu iotop curl ca-certificates sudo \
   subversion git p7zip-full wget htop iotop curl ca-certificates \
   build-essential autoconf autoconf pkg-config libssl-dev \
   zlib1g zlib1g-dev make pv libncurses5-dev libncurses5 libncursesw5-dev libncursesw5 gettext \
   libgdiplus pv \
   cmake 

apt clean

# postgres
export LC_ALL=en_US.UTF-8
apt install postgresql postgresql-contrib -y
apt clean
pg_createcluster 11 main --start
pg_ctlcluster 11 main start
sudo -u postgres psql -c 'SELECT version();'

# mariadb
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'
sudo apt-get install -y mariadb-server
apt clean
mysql --table -uroot -pPASS -e "SHOW VARIABLES LIKE '%Version%';"

apt-get install -y redis-server
apt clean
echo info | redis-cli | grep version


