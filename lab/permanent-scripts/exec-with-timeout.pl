# https://perldoc.perl.org/functions/alarm
# https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x

$timeout = shift;
print "[timeout] Timeout=" . $timeout . ", Command is " . join(" ",@ARGV) . "\n";

local $SIG{ALRM} = sub { 
  print "\n\n[timeout] Command Terminated by timeout: " . @ARGV . "\n";
  print "\n\n\n\n WHAT THE HECK\n";
  exit(2);
  die "Timeout\n" 
}; 

alarm $timeout;
# my $nread = sysread $socket, $buffer, $size;
print "[timeout] ARGV: " . @ARGV . "\n";
$exitCode = exec @ARGV or exit(1);
print "[timeout] Success\n";
exit (0);
