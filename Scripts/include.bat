@echo off
setlocal enabledelayedexpansion

set "target_folder=%~f1"

if "%target_folder%"=="" (
  echo Usage: include [folder_path]
  exit /b 1
)

if not exist "%target_folder%" (
  echo [!] Error: Folder "%target_folder%" does not exist.
  exit /b 1
)

powershell -NoProfile -Command ^
  "$path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine'); " ^
  "if ($path -split ';' -contains '%target_folder%') { exit 100 } else { exit 0 }"

if %errorlevel% equ 100 (
  echo [!] Information: "%target_folder%" is already in your PATH.
  exit /b 0
)

echo [?] Found new directory: %target_folder%
set /p "confirm=Add this to your User PATH? (y/n): "

if /i "%confirm%" neq "y" (
  echo [!] Action cancelled.
  exit /b 0
)

echo [+] Updating User PATH...
powershell -NoProfile -Command ^
  "$oldPath = [Environment]::GetEnvironmentVariable('Path', 'User'); " ^
  "$newPath = $oldPath + ';' + '%target_folder%'; " ^
  "[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')"

if %errorlevel% equ 0 (
  echo [^!] Success! Please restart your terminal to apply changes.
) else (
  echo [!] Error: Failed to update environment variables.
)

exit /b
