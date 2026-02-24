@echo off
setlocal
if "%~1"=="" (
  echo Usage: sha256 [file]
  exit /b 1
)
powershell -NoProfile -Command "Get-FileHash '%~1' | Format-List"
endlocal
