#!/usr/bin/env bash
sudo apt-get -y install subversion git p7zip-full mc wget htop iotop curl ca-certificates sudo \
   subversion git p7zip-full mc wget htop iotop curl ca-certificates \
   build-essential autoconf autoconf pkg-config \
   zlib1g zlib1g-dev make pv libncurses5-dev libncurses5 libncursesw5-dev libncursesw5 gettext \
   libgdiplus pv \
   cmake 

# postgres
apt install postgresql postgresql-contrib -y
sudo -u postgres psql -c "SELECT version();"

# mariadb
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'
sudo apt-get install -y mariadb-server
mysql -uroot -pPASS -e "SHOW VARIABLES LIKE '%Version%';"

apt-get install -y redis-server
echo info | redis-cli | grep version
