@echo off
setlocal

if "%~1"=="" (
  set "owner=%USERNAME%"
) else (
  set "owner=%~1"
)
taskkill /f /fi "USERNAME eq %owner%"

endlocal
