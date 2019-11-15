#!/usr/bin/env bash
apt-get -y install sudo subversion git p7zip-full mc wget htop iotop curl ca-certificates sudo \
   subversion git p7zip-full wget htop iotop curl ca-certificates \
   build-essential autoconf autoconf pkg-config libssl-dev \
   zlib1g zlib1g-dev make pv libncurses5-dev libncurses5 libncursesw5-dev libncursesw5 gettext \
   libgdiplus pv \
   cmake 

apt clean

# postgres
apt install postgresql postgresql-contrib -y
apt clean
sudo -u postgres psql -c "SELECT version();"

# mariadb
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'
sudo apt-get install -y mariadb-server
apt clean
mysql -uroot -pPASS -e "SHOW VARIABLES LIKE '%Version%';"

apt-get install -y redis-server
apt clean
echo info | redis-cli | grep version
