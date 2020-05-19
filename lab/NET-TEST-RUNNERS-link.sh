#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local
set -u
errors=0

function create_launcher() {
  name=$1
  search_in=$2
  search_the=$3
  eval "pushd $search_in" >/dev/null
    if [[ -f "$search_the" ]]; then 
        # echo "[$search_in] found: [$(pwd)]"
        full_path="$(pwd)/$search_the"
        body="#!/usr/bin/env bash\nset -e\nmono $full_path \"\$@\""
        # echo "Creating link to $full_path as $name[.exe]"
        echo -e $body | sudo tee  /usr/local/bin/${name} >/dev/null
        sudo chmod +x /usr/local/bin/${name}
        echo -e $body | sudo tee /usr/local/bin/${name}.exe >/dev/null
        sudo chmod +x /usr/local/bin/${name}.exe
        # echo "ok: Unit Test Runner [$search_the] SUCCESSFULLY LINKED as [$full_path] to /usr/local/bin/${name}"
    else
        errors=$((errors+1))
        echo "ERROR: Unit Test runner [$search_the] NOT FOUND in [$search_in]. pwd is [$(pwd)]"   
    fi
    
  popd >/dev/null
}

pushd "$(dirname $0)" >/dev/null; ScriptDir="$(pwd)"; popd >/dev/null
# paket.exe: ${ScriptDir}/paket.exe

echo '#!/usr/bin/env bash
set -e
mono ${ScriptDir}/paket.exe "$@"
' | sudo tee /usr/local/bin/paket >/dev/null
cp -f /usr/local/bin/paket /usr/local/bin/paket.exe


pushd "${ScriptDir}" >/dev/null

create_launcher "nunit3-console" "packages/NUnit.ConsoleRunner*/tools" "nunit3-console.exe"
create_launcher "xunit.console"  "packages/xunit.runner.console*/tools/net472" "xunit.console.exe"

popd >/dev/null

printf "Check nunit3-console version ... "
nunit3-console > /tmp/nunit3-console.version.tmp
cat /tmp/nunit3-console.version.tmp | head -1
rm -f /tmp/nunit3-console.version.tmp

printf "Check xunit.console version .... "
xunit.console > /tmp/xunit.console.version.tmp
cat /tmp/xunit.console.version.tmp | head -1
rm -f /tmp/xunit.console.version.tmp

set +e


exit $errors
