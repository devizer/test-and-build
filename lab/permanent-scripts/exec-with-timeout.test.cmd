@set url_fail=https://archive.org/download/sql_server_2014_sp3_developer_edition_x64.7z/sql_server_2014_sp3_developer_edition_x64.7z
@set url_ok=https://google.com
@echo "* TEST OK"
C:\Apps\Git\usr\bin\perl.exe exec-with-timeout.pl 10 curl -kfSL -o w:\Temp\sql_server_2014_sp3_developer_edition_x64.7z %url_ok%
@echo off
if errorlevel 2 (echo ERROR TIMEOUT) Else (
  If errorlevel 1 (echo ERROR COMMAND FAILED) Else (echo OK)
)

echo.
echo "* TEST TIMEOUT"
C:\Apps\Git\usr\bin\perl.exe exec-with-timeout.pl 10 curl -kfSL -o w:\Temp\sql_server_2014_sp3_developer_edition_x64.7z %url_fail%
@echo off
if errorlevel 2 (echo. && echo ERROR TIMEOUT) Else (
  If errorlevel 1 (echo ERROR COMMAND FAILED) Else (echo OK)
)

echo.
echo "* TEST ERROR"
C:\Apps\Git\usr\bin\perl.exe exec-with-timeout.pl 10 curl777 -kfSL -o w:\Temp\sql_server_2014_sp3_developer_edition_x64.7z %url_fail%
@echo off
if errorlevel 2 (echo. && echo ERROR TIMEOUT) Else (
  If errorlevel 1 (echo ERROR COMMAND FAILED) Else (echo OK)
)
