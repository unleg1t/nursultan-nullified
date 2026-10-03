@echo off
rem Launches the Nursultan client (Windows).
setlocal
cd /d "%~dp0"

if not exist "libraries\libs" (
  echo [!] Libraries are missing. Run setup.ps1 first:
  echo     powershell -ExecutionPolicy Bypass -File .\setup.ps1
  pause
  exit /b 1
)

rem Windows java.exe resolution: %JAVA_WIN% > .\jre > PATH
set "JAVA=java"
if exist "jre\bin\java.exe" set "JAVA=jre\bin\java.exe"
if not "%JAVA_WIN%"=="" set "JAVA=%JAVA_WIN%"

"%JAVA%" ^
  -XX:+UnlockDiagnosticVMOptions ^
  -XX:-BytecodeVerificationRemote ^
  -XX:-BytecodeVerificationLocal ^
  -Xmx2G ^
  -Djava.library.path="libraries/natives" ^
  -cp "nursultan.jar;libraries/libs/*" ^
  we.are.sk3d.Launcher

echo.
echo Client exited.
pause
