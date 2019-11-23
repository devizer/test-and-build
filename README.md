## Debian 10.latest

| OS    |  Debian 10.2 Buster **`arm64`** and **`arm32`** |
|-------|------------------------------------|
| echo $ARCH |**`arm64`**|
| nuget |**`NuGet Version: 5.2.0.6090`**|
| nunit3-console --version |**`NUnit Console Runner 3.10.0`**|
| xunit.console |**`xUnit.net Console Runner v2.4.1 (64-bit Desktop .NET 4.7.2, runtime: 4.0.30319.42000)`**|
| .NET Core SDKs |**`2.1.802 [/opt/dotnet/sdk]`**<br>**`2.2.402 [/opt/dotnet/sdk]`**<br>**`3.0.100 [/opt/dotnet/sdk]`**|
| mono --version |**`Mono JIT compiler version 6.4.0.198 (tarball Tue Sep 24 01:36:26 UTC 2019)`**|
| msbuild /version |**`Microsoft (R) Build Engine version 16.3.0-ci for Mono`**|
| pwsh --version |**`PowerShell 6.2.3`**|
| nvm --version  |**`0.35.0`**|
| node --version |**`v12.13.1`**|
| npm --version |**`6.12.1`**|
| yarn --version |**`1.19.2`**|
| docker version --format '{{.Server.Version}}' |**`19.03.5`**|
| docker-compose version |**`docker-compose version 1.24.1, build 85d94090`**|
| mysql -N -B -uroot -pPASS -e "SHOW VARIABLES LIKE 'version';" |**`version 10.3.18-MariaDB-0+deb10u1`**|
| cd /tmp; sudo -u postgres psql -t -c 'SELECT version();' |**` PostgreSQL 11.5 (Debian 11.5-1+deb10u1) on aarch64-unknown-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit`**|
| Redis Server |**`redis_version:5.0.3`**|
| uname -a |**`Linux debian-aarch64 4.19.0-6-arm64 #1 SMP Debian 4.19.67-2+deb10u2 (2019-11-11) aarch64 GNU/Linux`**|
| . /etc/os-release && echo "$PRETTY_NAME v$(cat /etc/debian_version)" |**`Debian GNU/Linux 10 (buster) v10.2`** |

### Software instaled outside of Debian repo
- docker & docker-compose
- dotnet & powershell
- msbuild, nuget, mono
- NUnit console runner, xUnit console runner
- NodeJS LTS, yarn, npm

Image is updated weekly and these soft is installed using latest versions

### Disabled services and timers
- postgresql, redis-server, mariadb, docker 

- unattended-upgrades, cron, apt-daily-upgrade.timer, apt-daily.timer, logrotate.timer

#### Credentials for preinstalled services:
```
mysql -N -B -uroot -pPASS -e "SHOW VARIABLES LIKE 'version'"
sudo -u postgres psql -t -c 'SELECT version();'
```

#### SSH configuration
root's password: pass

user's password: pass. it is a no-password sudoer

ssh configured for pass throwing environment variables for Azure Pipelines, travis-ci.org and AppVeyor:
```
SetEnv ARCH=arm|arm64
AcceptEnv APPVEYOR* TRAVIS* BUILD_* Build_*
```
