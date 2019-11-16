#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local
set -u
errors=0

function create_launcher() {
  name=$1
  search_in=$2
  search_the=$3
  eval "pushd $search_in"
    if [[ -f "$search_the" ]]; then 
        echo "[$search_in] found: [$(pwd)]"
        full_path="$(pwd)/$search_the"
        body="#!/usr/bin/env bash\n\nmono $full_path \"\$@\""
        echo "Creating link to $full_path as $name[.exe]"
        echo -e $body > /usr/local/bin/${name}
        chmod +x /usr/local/bin/${name}
        echo -e $body > /usr/local/bin/${name}.exe
        chmod +x /usr/local/bin/${name}.exe
        Say "Unit Test Runner [$search_the] SUCCESSFULLY FOUND as [$full_path]"
    else
        errors=$((errors+1))
        Say "ERROR: Unit Test runner [$search_the] NOT FOUND in [$search_in]. pwd is [$(pwd)]"   
    fi
    
  popd
}

pushd "$(dirname $0)" >/dev/null; ScriptDir="$(pwd)"; popd >/dev/null

pushd "${ScriptDir}"

create_launcher "nunit3-console" "NUnit.ConsoleRunner*/tools" "nunit3-console.exe"
create_launcher "xunit.console" "xunit.runner.console*/tools/net472" "xunit.console.exe"

popd

nunit3-console > /tmp/nunit3-console.version.tmp
cat /tmp/nunit3-console.version.tmp | head -3
rm -f /tmp/nunit3-console.version.tmp

xunit.console > /tmp/xunit.console.version.tmp
cat /tmp/xunit.console.version.tmp | head -3
rm -f /tmp/xunit.console.version.tmp

set +e


exit $errors
