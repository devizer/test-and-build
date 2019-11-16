|  Debian 10 Buster <u>**i386**</u> |
|-------|
| echo $ARCH |
|**`i386`**|
| . /etc/os-release && echo $PRETTY_NAME |
|**`Debian GNU/Linux 10 (buster)`**|
| dotnet --version |
|ERR: _dotnet: command not found_|
| .NET Core SDKs |
|ERR: _dotnet: command not found_|
| dotnet --list-runtimes |
|ERR: _dotnet: command not found_|
| pwsh --version |
|ERR: _pwsh: command not found_|
| mono --version |
|**`Mono JIT compiler version 6.4.0.198 (tarball Tue Sep 24 01:24:52 UTC 2019)`**|
| msbuild /version |
|**`Microsoft (R) Build Engine version 16.3.0-ci for Mono`**|
| nuget |
|**`NuGet Version: 5.2.0.6090`**|
| nunit3-console --version |
|**`NUnit Console Runner 3.10.0 (.NET 2.0)`**|
| xunit.console |
|**`xUnit.net Console Runner v2.4.1 (32-bit Desktop .NET 4.7.2, runtime: 4.0.30319.42000)`**|
| nvm --version  |
|ERR: _nvm: command not found_|
| node --version |
|ERR: _node: command not found_|
| npm --version |
|ERR: _npm: command not found_|
| yarn --version |
|ERR: _yarn: command not found_|
| docker version --format '{{.Server.Version}}' |
|**`18.09.1`**|
| docker-compose version |
|**`docker-compose version 1.21.0, build unknown`**|
| mysql -N -B -uroot -pPASS -e "SHOW VARIABLES LIKE 'version';" |
|**`version	10.3.17-MariaDB-0+deb10u1`**|
| cd /tmp; sudo -u postgres psql -t -c 'SELECT version();' |
|**` PostgreSQL 11.5 (Debian 11.5-1+deb10u1) on i686-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 32-bit`**|
| Redis Server |
|**`redis_version:5.0.3`**|
| uname -a |
|**`Linux debian-i386 4.19.0-6-686-pae #1 SMP Debian 4.19.67-2+deb10u2 (2019-11-11) i686 GNU/Linux`**|
| lscpu |
|**`Architecture:        i686`**<br>**`CPU op-mode(s):      32-bit`**<br>**`Byte Order:          Little Endian`**<br>**`Address sizes:       36 bits physical, 0 bits virtual`**<br>**`CPU(s):              6`**<br>**`On-line CPU(s) list: 0-5`**<br>**`Thread(s) per core:  1`**<br>**`Core(s) per socket:  1`**<br>**`Socket(s):           6`**<br>**`Vendor ID:           GenuineIntel`**<br>**`CPU family:          15`**<br>**`Model:               6`**<br>**`Model name:          Common 32-bit KVM processor`**<br>**`Stepping:            1`**<br>**`CPU MHz:             3492.080`**<br>**`BogoMIPS:            6984.16`**<br>**`Hypervisor vendor:   KVM`**<br>**`Virtualization type: full`**<br>**`L1d cache:           32K`**<br>**`L1i cache:           32K`**<br>**`L2 cache:            4096K`**<br>**`L3 cache:            16384K`**<br>**`Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 constant_tsc cpuid tsc_known_freq pni x2apic hypervisor cpuid_fault pti`**|
