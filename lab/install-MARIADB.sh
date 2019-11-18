#!/usr/bin/env bash
# mariadb
Say "Installing MariaDB"
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'
smart-apt-install mariadb-server
mysqlVersion=$(mysql -N -B -uroot -pPASS -e "SHOW VARIABLES LIKE 'version';")
Say "Installed MariaDB ${mysqlVersion}" 
mysql --table -uroot -pPASS -e "SHOW VARIABLES LIKE '%Version%';"
