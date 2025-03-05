#!/usr/bin/env bash
# https://perldoc.perl.org/functions/alarm
# https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x
# https://stackoverflow.com/questions/17751199/perl-script-in-bashs-heredoc

set -eu; set -o pipefail;
if [[ -n "$(command -v perl)" ]]; then
err=''
perl || err=$? <<'EOF' 
$timeout = shift;
print "[exec-with-timeout] Timeout=" . $timeout . ", Command is " . join(" ",@ARGV) . "\n";

local $SIG{ALRM} = sub { 
  print "\n\n[timeout] Command Terminated by timeout: " . @ARGV . "\n";
  print "\n\n\n\n WHAT THE HECK\n";
  exit(2);
  die "Timeout\n" 
}; 

alarm $timeout;
$exitCode = exec @ARGV or exit(1);
print "[timeout] Success\n";
exit (0);
EOF
if [[ "${err}" == "2" ]]; then
  shift;
  echo "[exec-with-timeout] Command terminated by timeout '$*'"
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
