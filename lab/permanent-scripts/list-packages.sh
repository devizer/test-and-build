#!/usr/bin/env bash
echo '#!/usr/bin/env bash
packages=$(dpkg --get-selections | grep -v deinstall | awk "{print $1}")
apt-cache --no-all-versions show $packages |
    awk '"'"'
        $1 == "Package:" { p = $2; v="" }
        $1 == "Version:" { v = $2 }
        $1 == "Size:"    { printf("%10d %s %s\n", $2, p, v) }
    '"'"' | sort -k1 -n
' | sudo tee /usr/local/bin/list-packages >/dev/null
chmod +x /usr/local/bin/list-packages
