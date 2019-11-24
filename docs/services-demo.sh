
# Start MariaDB and wait for it
docker rm -f a_mariadb >/dev/null 2>/dev/null
printf '[mysqld]\nbind-address = 0.0.0.0\n' > mariadb.config
time docker run -d --name a_mariadb -v $(pwd)/mariadb.config:/etc/mysql/my.cnf -e MYSQL_ROOT_PASSWORD=PASS -p 3306:3306 mariadb:10.4
docker logs -f a_mariadb 2>&1 &
parallel-wait-for -timeout=600 \
  "-MySQL=Server=localhost; Port=3306; Uid=root; Pwd=PASS; Connect Timeout=20; Pooling=false;"
# 260 seconds for 1.6GHz and 150 secs for 3.7Ghz


docker rm -f a_postgres >/dev/null 2>/dev/null
time docker run -d --name a_postgres -e POSTGRES_PASSWORD=PASS -p 5432:5432 postgres:12
docker logs -f a_postgres 2>&1 &
parallel-wait-for -timeout=400 \
  "-PostgreSQL=Host=localhost; Port=5432; User ID=postgres; Password=PASS; Database=postgres; Pooling=false;"
# 55 seconds for 12.1 @ 3.7Ghz, 84 seconds for 9.4 @ 3.7 GHz

docker rm -f a_redis >/dev/null 2>/dev/null
time docker run -d --name a_redis -p 6379:6379 redis:3
docker logs -f a_redis 2>&1 &
parallel-wait-for -timeout=100 "-Redis=localhost:6379"
# 17 seconds for v4/v5 @ 3.7Ghz

# Local MYSQL is ready in 12 seconds
systemctl stop mysql
time systemctl start mysql
time mysql -u root -p'PASS' -e "SHOW VARIABLES LIKE \"%version%\";"

# Local PostgreSQL is ready in 11 seconds
systemctl stop postgresql
time systemctl start postgresql
sudo -u postgres psql -c 'SELECT version();'

# Local PostgreSQL is ready in 3 seconds
systemctl stop redis-server
time systemctl start redis-server
echo info | redis-cli | grep version
