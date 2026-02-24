@echo off
setlocal

if "%~1"=="" (
  echo Usage: zip [file_or_folder] [optional_output_name]
  exit /b 1
)

set "source=%~1"
set "dest=%~2"
if "%dest%"=="" set "dest=%~n1.zip"

echo [+] Zipping %source% into %dest%...
powershell -NoProfile -Command "Compress-Archive -Path '%source%' -DestinationPath '%dest%' -Force"

endlocal
