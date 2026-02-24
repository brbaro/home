@echo off
setlocal enabledelayedexpansion

set "SCRIPTS_DIR=%~dp0"
if "%SCRIPTS_DIR:~-1%"=="\" set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"

set "NEW_PATHS=%SCRIPTS_DIR%"

if exist "%SCRIPTS_DIR%\Bats" (
  set "NEW_PATHS=!NEW_PATHS!;%SCRIPTS_DIR%\Bats"
)

if exist "%SCRIPTS_DIR%\Local" (
  set "NEW_PATHS=!NEW_PATHS!;%SCRIPTS_DIR%\Local"
)

set "PATH=%NEW_PATHS%;%PATH%"

doskey qq=exit
doskey l=dir
doskey ll="dir /all"
clear
prompt $P$G$_^>:

cmd /k "echo BATSH & echo."

endlocal
