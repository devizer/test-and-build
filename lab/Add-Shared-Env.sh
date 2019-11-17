#!/usr/bin/env bash
key=$1
script=$2
echo '#!/usr/bin/env bash
'$script'
' | sodu tee >> /etc/profile.d/${key}.sh
