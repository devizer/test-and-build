#!/usr/bin/env bash
output=/transient-builds/test-and-build-FULL
src="$HOME/build/devizer/test-and-build"
mkdir -p $output
rm -rf $output/*
cd $src 
git pull


logs="$HOME/logs"
mkdir -p $logs

(pwsh -c ./image-builder.ps1 -Images i386  -Only docker -MaxVmCores 3 -FinalSize 42G -OutputFolder $output 2>&1 | tee $logs/i386.log  ) &
job1=$!
(pwsh -c ./image-builder.ps1 -Images arm   -Only docker -MaxVmCores 2 -FinalSize 42G -OutputFolder $output 2>&1 | tee $logs/arm.log   ) &
job2=$!
(pwsh -c ./image-builder.ps1 -Images arm64 -Only docker -MaxVmCores 2 -FinalSize 42G -OutputFolder $output 2>&1 | tee $logs/arm64.log ) &
$job3=$!

echo WAITING 3 JOBS: $(date)
wait $job1
wait $job2
wait $job3
echo DONE $(date)
