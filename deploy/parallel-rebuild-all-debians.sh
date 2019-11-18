#!/usr/bin/env bash
rm /transient-builds/test-and-build/*
cd ~/build/devizer/test-and-build
git pull

logs="$HOME/logs"
mkdir -p $logs
(pwsh -command ./image-builder.ps1 -Images i386  -FinalSize 42G 2>&1 | tee $logs/i386.log  ) &
job1=$!
(pwsh -command ./image-builder.ps1 -Images arm   -FinalSize 42G 2>&1 | tee $logs/arm.log   ) &
job2=$1
(pwsh -command ./image-builder.ps1 -Images arm64 -FinalSize 42G 2>&1 | tee $logs/arm64.log ) &
$job3

echo WAITING 3 JOBS: $(date)
wait $job1
wait $job2
wait $job3
echo DONE $(date)
