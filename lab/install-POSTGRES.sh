#!/usr/bin/env bash
Say "Installing Postgres SQL"
export LC_ALL=en_US.UTF-8
apt install postgresql postgresql-contrib -y
apt clean
pg_createcluster 11 main --start
pg_ctlcluster 11 main start
pgVer=$(sudo -u postgres psql -t -c 'show server_version;')
Say "Installed Postgres SQL: $pgVer"
sudo -u postgres psql -c 'SELECT version();'
