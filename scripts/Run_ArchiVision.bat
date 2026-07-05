@echo off
setlocal
cd /d "%~dp0"

if not exist "archi_vision.exe" (
  echo archi_vision.exe was not found in this folder.
  pause
  exit /b 1
)

start "" "%~dp0archi_vision.exe"
