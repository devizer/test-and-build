#!/usr/bin/env bash

pushd TestRunners
Say "Run Nuget Restore for [$(pwd)]"
try-and-retry nuget restore -Verbosity quiet
Say "Run msbuild for [$(pwd)]"
msbuild /t:Rebuild /p:Configuration=Debug /v:q

pushd TestRunners.xUnit/bin/Debug
Say "Test TestRunners.xUnit.dll at $(pwd)" 
xunit.console TestRunners.xUnit.dll
popd

pushd TestRunners.NUnit/bin/Debug
Say "Test TestRunners.NUnit.dll at $(pwd)"
nunit3-console TestRunners.NUnit.dll
popd  

popd # TestRunners

Say "Clearing mono cache"
du -h -d 1 ~/.nuget 
nuget locals all -clear
du -h -d 1 ~/.nuget
Say "Cleared mono cache"
