#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local

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
    else
        Say "Unit Test runner [$search_the] NOT FOUND in [$search_in]. pwd is [$(pwd)]"   
    fi
    
  popd
}

target=/opt/mono-test-runners
mkdir -p $target
pushd $target
rm -rf *

packets='
NUnit.Console NUnit.ConsoleRunner NUnit.Extension.NUnitProjectLoader NUnit.Extension.NUnitV2Driver
NUnit.Extension.NUnitV2ResultWriter NUnit.Extension.TeamCityEventListener
NUnit3TestAdapter
xunit.abstractions xunit.analyzers xunit.assert xunit.core xunit.extensibility.core
xunit.extensibility.execution xunit.runner.console xunit.runner.msbuild
xunit.runner.reporters xunit.runner.utility 
'

mkdir -p packages
pushd packages

i=0
for packet in $packets; do
    echo Enqueue loading the $packet package
    nuget install $packet 2>&1 >.${packet}.log &
    pids[${i}]=$!
    i=$((i+1))
    sleep 0.7
done

total="${#pids[@]}"
counter=0
for pid in ${pids[*]}; do
    counter=$((counter+1))
    echo "${counter}/${total} wait for $pid job"
    wait $pid
done
rm -rf System* 
find -name "*.nupkg" | xargs rm -f

create_launcher "nunit3-console" "NUnit.ConsoleRunner*/tools" "nunit3-console.exe"
create_launcher "xunit.console" "xunit.runner.console*/tools/net472" "xunit.console.exe"

popd


