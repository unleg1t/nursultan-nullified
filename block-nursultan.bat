@echo off
rem Null-routes Nursultan's backend in the Windows hosts file.
rem Run as Administrator. The repo jar is already patched; this is optional.
set HOSTS=%SystemRoot%\System32\drivers\etc\hosts
findstr /C:"nursultan.fun" "%HOSTS%" >nul 2>&1 && (
  echo [=] Already present in hosts file.
  goto :flush
)
echo.>>"%HOSTS%"
echo 0.0.0.0 nursultan.fun>>"%HOSTS%"
echo 0.0.0.0 www.nursultan.fun>>"%HOSTS%"
echo [+] Blocked nursultan.fun in %HOSTS%
:flush
ipconfig /flushdns >nul
echo To undo, remove the two nursultan.fun lines from %HOSTS%
