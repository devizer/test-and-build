@echo off
call bash-win Say.sh Message One Two
echo "RESET STOPWATCH"
call bash-win Say.sh --Reset-Stopwatch
call bash-win Say.sh Message Three Four
echo "PAUSE 3 Seconds"
ping -n 4 127.0.0.1 >nul
call bash-win Say.sh Message Five Six
call bash-win Say.sh --Display-As=Error Error Message
