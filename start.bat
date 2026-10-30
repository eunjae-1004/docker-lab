@echo off
cd /d "%~dp0"
docker compose up -d
if errorlevel 1 (
  echo Operation failed. Check the message above.
  pause
  exit /b 1
)
pause
