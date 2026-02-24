@echo off
setlocal

if "%~1"=="" (
  echo Usage: get-node [version]
  echo Example: get-node v20.11.1
  exit /b 1
)

set "VERSION=%~1"
set "ARCH=x64"
set "NODE_DIR=%USERPROFILE%\Scripts\node-%VERSION%"
set "ZIP_FILE=%TEMP%\node-%VERSION%.zip"
set "URL=https://nodejs.org/dist/%VERSION%/node-%VERSION%-win-%ARCH%.zip"

echo [+] Fetching Node.js %VERSION% from official mirrors...
curl -L "%URL%" -o "%ZIP_FILE%"

if %errorlevel% neq 0 (
  echo [!] Failed to download Node.js. Is the version correct?
  exit /b 1
)

if not exist "%NODE_DIR%" mkdir "%NODE_DIR%"

echo [+] Extracting to %NODE_DIR%...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%USERPROFILE%\Scripts\temp-node' -Force"

move "%USERPROFILE%\Scripts\temp-node\node-%VERSION%-win-%ARCH%\*" "%NODE_DIR%\" >nul

echo [+] Cleaning up...
del "%ZIP_FILE%"
rmdir /s /q "%USERPROFILE%\Scripts\temp-node"

echo.
echo [+] Node.js %VERSION% is now available at: %NODE_DIR%
echo [!] Add the following to your PATH:
echo     %NODE_DIR%
echo.
echo [?] Try running: %NODE_DIR%\node.exe -v

endlocal
