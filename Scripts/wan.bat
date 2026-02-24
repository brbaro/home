@echo off
setlocal enabledelayedexpansion

set "target=https://brbaro.web.app/ping"

for /f "delims=" %%A in ('curl -sL --max-time 7 "!target!"') do (
  set "res=%%A"
)

set "res=!res: =!"

if /i "!res!"=="pong" (
  echo connected
) else (
  echo offline
)

endlocal
