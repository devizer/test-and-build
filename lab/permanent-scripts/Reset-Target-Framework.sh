#!/usr/bin/env bash

target_framework="$1"
if [[ "$target_framework" == "" ]]; then
    echo -e "\n  Usage: Reset-Target-Framework net471 [--dry]"
    exit 0;
fi

is_dry_run=false;
if [[ "$2" == "--dry"* ]]; then
  is_dry_run=true;
fi

find . | grep -E "\.csproj$" | while read csproj; do
  echo "csproj: $csproj"
done
