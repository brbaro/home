@echo off
setlocal enabledelayedexpansion

if not "%STASH_ROOT%"=="" (
  if not exist "%STASH_ROOT%" (
    echo [!] Error: STASH_ROOT "%STASH_ROOT%" does not exist.
    exit /b 1
  )
  cd /d "%STASH_ROOT%"
)

set "STASH_FOLDER=.stash"

if "%~1"=="list" goto :list_logic
if "%~2"==""   goto :help
if /i "%~2"=="pop" goto :pop_logic
goto :stash_logic

:help
echo Usage: stash [label] [files...] or [label] pop
exit /b

:list_logic
if not exist "%STASH_FOLDER%" (echo No stashes found. & exit /b)
echo [ Stash Directory: %CD%\%STASH_FOLDER% ]
dir /b /ad "%STASH_FOLDER%"
exit /b

:pop_logic
set "label=%~1"
set "target_dir=%STASH_FOLDER%\%label%"

if not exist "%target_dir%" (echo [!] Stash '%label%' not found. & exit /b 1)

echo [!] Popping stash: %label%
pushd "%target_dir%"
for /f "delims=" %%i in ('dir /b /a') do (
  set "item=%%i"
  if exist "..\..\%item%" (
    set /p "confirm=[?] Overwrite ..\..\%item%? (y/n): "
    if /i "!confirm!"=="y" (
      if exist "..\..\%item%\" (rd /s /q "..\..\%item%") else (del /f /q "..\..\%item%")
      move /y "%%i" "..\..\" >nul
    )
  ) else (
    move "%%i" "..\..\" >nul
  )
)
popd
rd /q "%target_dir%" 2>nul
exit /b

:stash_logic
set "label=%~1"
set "target_dir=%STASH_FOLDER%\%label%"

if not exist "%STASH_FOLDER%" mkdir "%STASH_FOLDER%"
if not exist "%target_dir%" mkdir "%target_dir%"

shift
:stash_loop
if "%~1"=="" goto :eof
if exist "%~1" (
  echo [^>] Stashing: %~1
  move "%~1" "%target_dir%\" >nul
) else (
  echo [!] Skipping: %~1 (Not found in %CD%)
)
shift
goto :stash_loop

:eof
exit /b
