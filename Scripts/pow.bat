@echo off
setlocal enabledelayedexpansion

for /f "tokens=2 delims=()" %%a in ('powercfg -getactivescheme') do set "previous=%%a"
set "current=%previous%"

if "%~1"=="" goto :output

for /f "tokens=3,4*" %%a in ('powercfg -list') do (
  echo %%c | findstr /i "%~1" >nul
  if !errorlevel! == 0 (
    set "targetGUID=%%b"
  )
)

if defined targetGUID (
  powercfg -setactive %targetGUID% >nul 2>&1
  for /f "tokens=2 delims=()" %%a in ('powercfg -getactivescheme') do set "current=%%a"
)

:output
if /i "%previous%" neq "%current%" (
  echo %previous% -^> %current%
) else (
  echo %current%
)

endlocal
