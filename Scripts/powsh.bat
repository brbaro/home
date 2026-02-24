@echo off
setlocal

set "PS_PROFILE=%~dp0profile.ps1"

if not exist "%PS_PROFILE%" (
  echo [!] Error: %PS_PROFILE% not found.
  set "LOAD_CMD= "
) else (
  set "LOAD_CMD=. '%PS_PROFILE%'"
)

if /i "%~1"=="wudo" (
  set "args_list="
  shift
  goto :parse_args
)

if /i "%~x1"==".ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~1"
  goto :eof
)

if not "%~1"=="" (
  powershell -NoProfile -Exit -ExecutionPolicy Bypass -Command "%LOAD_CMD%; %*"
) else (
  powershell -NoProfile -NoExit -ExecutionPolicy Bypass -Command "%LOAD_CMD%"
)
goto :eof

:parse_args
if "%~1"=="" goto :elevate
set "args_list=%args_list% %1"
shift
goto :parse_args

:elevate
powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command \"%LOAD_CMD%; %args_list%; Write-Host `\"`n[Process Finished]`\" -Fore Yellow; Read-Host `\"Press Enter to close`\"\"' -Verb RunAs"
goto :eof

:eof
endlocal
