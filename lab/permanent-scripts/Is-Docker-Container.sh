#!/usr/bin/env bash

if [[ "${container:-}" == "docker" || "$(grep 'docker' /proc/1/cgroup 2>/dev/null || true)" != "" ]]; then
  if [[ "$1" == "-v" ]]; then echo "true"; fi
  exit 1;
else
  if [[ "$1" == "-v" ]]; then echo "false"; fi
  exit 0;
fi