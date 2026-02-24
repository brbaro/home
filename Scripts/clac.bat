@echo off
setlocal enabledelayedexpansion

set "input=%*"
set "input=!input:$=!"
set "input=!input:,=!"

set "input=!input:x=*!"

if "%~1"=="" (
  echo Usage: clac [expression] OR clac [add|sub|mul|div|avg] [numbers...]
  exit /b 1
)

set "cmd=%~1"
set "is_op=0"

if /i "%cmd%"=="add" set "expr=($args -join '+')"; set "is_op=1"
if /i "%cmd%"=="sub" set "expr=($args -join '-')"; set "is_op=1"
if /i "%cmd%"=="mul" set "expr=($args -join '*')"; set "is_op=1"
if /i "%cmd%"=="div" set "expr=($args -join '/')"; set "is_op=1"
if /i "%cmd%"=="avg" set "expr='((' + ($args -join '+') + ')/' + $args.Count + ')'"; set "is_op=1"

if "%is_op%"=="1" (
  shift
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$args = @(%*); if ($args.Count -eq 0) { exit 1 }; Invoke-Expression %expr%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression '!input!'"
)

endlocal
