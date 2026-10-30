@echo off
cd /d "%~dp0"
docker compose stop
if errorlevel 1 (
  echo Operation failed. Check the message above.
  pause
  exit /b 1
)
pause
