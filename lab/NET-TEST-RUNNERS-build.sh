#!/usr/bin/env bash
# need a permission to /opt and /usr/bin/local

target=$HOME/build/devizer/NET-TEST-RUNNERS
mkdir -p ${target}.tmp
pushd ${target}.tmp

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
rm -rf *

i=0
errors=0
for packet in $packets; do
    echo Enqueue loading the $packet package
    cmd="nuget install $packet 2>&1 >.${packet}.log"
    eval $cmd || eval $cmd || eval $cmd || eval $cmd || eval $cmd || errors=$((errors+1)) &
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

curl -ksSL -o ${target}.tmp/link-unit-test-runners.sh https://raw.githubusercontent.com/devizer/test-and-build/master/lab/NET-TEST-RUNNERS-link.sh
chmod +x ${target}.tmp/link-unit-test-runners.sh

if [[ $errors == 0 ]]; then
    mkdir -p ${target}
    cp -a ${target}.tmp/* ${target}
    # rm -rf ${target}.tmp
else
    echo "ERRORS: $errors packages cant be installed"
    exit $errors
fi

popd
