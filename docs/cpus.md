#### kernel
```
root@debian-i386 ~ $ uname -a
Linux debian-i386 4.19.0-6-686-pae #1 SMP Debian 4.19.67-2+deb10u2 (2019-11-11) i686 GNU/Linux
```

kvm IvyBridge
```
root@debian-i386 ~ $ lscpu
Architecture:        i686
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
Address sizes:       36 bits physical, 48 bits virtual
CPU(s):              5
On-line CPU(s) list: 0-4
Thread(s) per core:  1
Core(s) per socket:  1
Socket(s):           5
Vendor ID:           GenuineIntel
CPU family:          6
Model:               58
Model name:          Intel Xeon E3-12xx v2 (Ivy Bridge)
Stepping:            9
CPU MHz:             3492.078
BogoMIPS:            6984.15
Hypervisor vendor:   KVM
Virtualization type: full
L1d cache:           32K
L1i cache:           32K
L2 cache:            4096K
L3 cache:            16384K
Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx rdtscp lm constant_tsc xtopology cpuid tsc_known_freq pni pclmulqdq ssse3 cx16 sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm cpuid_fault pti fsgsbase smep arat

```

kvm: kvm32
```
root@debian-i386 ~ $ lscpu
Architecture:        i686
CPU op-mode(s):      32-bit
Byte Order:          Little Endian
Address sizes:       36 bits physical, 0 bits virtual
CPU(s):              5
On-line CPU(s) list: 0-4
Thread(s) per core:  1
Core(s) per socket:  1
Socket(s):           5
Vendor ID:           GenuineIntel
CPU family:          15
Model:               6
Model name:          Common 32-bit KVM processor
Stepping:            1
CPU MHz:             3492.078
BogoMIPS:            6984.15
Hypervisor vendor:   KVM
Virtualization type: full
L1d cache:           32K
L1i cache:           32K
L2 cache:            4096K
L3 cache:            16384K
Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 constant_tsc cpuid tsc_known_freq pni x2apic hypervisor cpuid_fault pti
```