#!/usr/bin/env bash
cd /transient-builds/test-and-build
rm -rf *
cd ~/build/devizer/test-and-build
git pull

logs="$HOME/debian/builder"
mkdir -p $logs
(pwsh -command ./image-builder.ps1 -Images i386  2>&1 | tee $logs/i386.build.log  ) &
job1=$!
(pwsh -command ./image-builder.ps1 -Images arm   2>&1 | tee $logs/arm.build.log   ) &
job2=$1
(pwsh -command ./image-builder.ps1 -Images arm64 2>&1 | tee $logs/arm64.build.log ) &
$job3

echo WAITING 3 JOBS: $(date)
wait $job1
wait $job2
wait $job3
echo DONE $(date)
