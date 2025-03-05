#!/usr/bin/env bash
# https://perldoc.perl.org/functions/alarm
# https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x
# https://stackoverflow.com/questions/17751199/perl-script-in-bashs-heredoc
# v6

set -eu; set -o pipefail;
if [[ -n "$(command -v perl)" ]]; then
err=''
set +e
perl -E '
$timeout = shift;
print "[exec-with-timeout] Timeout=" . $timeout . ", Command is " . join(" ",@ARGV) . "\n";
$SIG{ALRM} = sub { exit(2); };
alarm $timeout;
$exitCode = exec @ARGV or exit(1);
exit (0);
' -- "$@" || err=$?
set -e

if [[ "${err}" == "2" ]]; then
  shift;
  echo "";
  echo "[exec-with-timeout] Command terminated by timeout "$*""
  exit 2
fi

elif [[ -n "$(command -v timeout)" ]]; then
  # using bsdutils timeout
  timeout "$@"
else
  echo "[exec-with-timeout] Warning! perf and bsdutil timeout are missing, timeout parameter ignored"
  shift
  "$@"
fi
