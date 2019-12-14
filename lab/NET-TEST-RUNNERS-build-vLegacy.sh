#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local

toClear=""; if [[ "$1" == "--clear" ]]; then toClear="true"; fi
 
target="${NET_TEST_RUNNERS_INSTALL_DIR:-$HOME/build/devizer/NET-TEST-RUNNERS}"
target_tmp=${target}.$(basename "$(mktemp)")
mkdir -p ${target_tmp}
pushd ${target_tmp} >/dev/null

packets='
NUnit.ConsoleRunner NUnit.Extension.NUnitV2Driver
NUnit.Extension.NUnitV2ResultWriter NUnit.Extension.TeamCityEventListener
xunit.abstractions xunit.analyzers xunit.assert xunit.core xunit.extensibility.core
xunit.extensibility.execution xunit.runner.console xunit.runner.msbuild
xunit.runner.reporters xunit.runner.utility 
'

# NUnit.Console NUnit3TestAdapter NUnit.Extension.NUnitProjectLoader  

mkdir -p packages
cd packages >/dev/null
rm -rf *

i=0
errors=0
for packet in $packets; do
    echo Enqueue loading the $packet package
    cmd="nuget install $packet 2>&1 >.${packet}.log"
    eval $cmd || eval $cmd || eval $cmd || eval $cmd || errors=$((errors+1)) &
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

popd >/dev/null

curl -ksSL -o ${target_tmp}/link-unit-test-runners.sh https://raw.githubusercontent.com/devizer/test-and-build/master/lab/NET-TEST-RUNNERS-link.sh
chmod +x ${target_tmp}/link-unit-test-runners.sh

if [[ $errors == 0 ]]; then
    mkdir -p ${target}
    cp -a ${target_tmp}/* ${target}
    rm -rf ${target_tmp}
else
    echo "ERRORS: $errors packages cant be installed"
    exit $errors
fi

