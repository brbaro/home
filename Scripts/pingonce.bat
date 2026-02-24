@echo off
setlocal

set "query=%*"
if "%query%"=="" set "query=github.com"
set "query=%query: =+%"

ping -n 1 -w 1000 %query% >nul 2>nul

if %errorlevel% == 0 (
  echo connected
) else (
  echo offline
  exit /b 1
)
