@echo off
setlocal EnableDelayedExpansion

if "%~1"=="" (
  echo Usage: iddqd [username] [optional_command]
  exit /b 1
)

set "TARGET_USER=%~1"
call :BaseName "%TARGET_USER%" USER_BASE

set "USE_SAVECRED="
if /I "%USER_BASE%"=="riot" set "USE_SAVECRED=1"
if /I "%USER_BASE%"=="epic" set "USE_SAVECRED=1"
if /I "%USER_BASE%"=="steam" set "USE_SAVECRED=1"

if defined IDDQD (
  for %%N in (%IDDQD%) do (
    call :BaseName "%%~N" ENTRY_BASE
    if /I "!ENTRY_BASE!"=="%USER_BASE%" set "USE_SAVECRED=1"
  )
)

if defined USE_SAVECRED (
  set "RUNAS_FLAG=/savecred"
  set "SAVECRED_MODE=enabled"
) else (
  set "RUNAS_FLAG="
  set "SAVECRED_MODE=disabled"
)

if "%~2"=="" (
  echo [!] /savecred: %SAVECRED_MODE%
  runas %RUNAS_FLAG% /user:%TARGET_USER% "cmd /c cd /d %%USERPROFILE%% && powsh"
  goto :eof
)

set "USER_FLAG=%TARGET_USER%"
shift
set "COMMAND=%*"

echo [!] /savecred: %SAVECRED_MODE%
echo [!] Executing as %USER_FLAG%: %COMMAND%
runas %RUNAS_FLAG% /user:%USER_FLAG% "cmd /c cd /d %%USERPROFILE%% && %COMMAND%"

:eof
endlocal
exit /b

:BaseName
setlocal
set "VALUE=%~1"
:BaseNameLoop
for /f "tokens=1,* delims=\" %%A in ("%VALUE%") do (
  if not "%%B"=="" (
    set "VALUE=%%B"
    goto :BaseNameLoop
  )
)
endlocal & set "%~2=%VALUE%"
exit /b
