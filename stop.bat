@echo off
setlocal
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
if "%ROOT:~-1%"==":" set "ROOT=%ROOT%\"
cd /d "%ROOT%"
docker compose --project-directory "%ROOT%" -f "%ROOT%\compose.yaml" stop
if errorlevel 1 (
  echo Operation failed. Check the message above.
  pause
  exit /b 1
)
pause
