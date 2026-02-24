@echo off
setlocal

if "%~1"=="" (
  echo Usage: unzip [file.zip] [optional_destination_folder]
  exit /b 1
)

set "source=%~1"
set "dest=%~2"
if "%dest%"=="" set "dest=%~n1"

echo [+] Unzipping %source% to folder \%dest%\...
powershell -NoProfile -Command "Expand-Archive -Path '%source%' -DestinationPath '%dest%' -Force"

endlocal
