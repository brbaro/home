@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
  echo --- Network Interfaces ---
  netsh interface show interface
  echo.
  echo Usage: nics [up/down] "Interface Name"
  goto :eof
)

set "action=%~1"
set "nic_name=%~2"

if "%nic_name%"=="" (
  echo [!] Error: Please specify the interface name.
  echo Example: nics %action% "Ethernet"
  goto :eof
)

if /i "%action%"=="up" (
  echo [+] Enabling interface: %nic_name%...
  netsh interface set interface name="%nic_name%" admin=enabled
) else if /i "%action%"=="down" (
  echo [-] Disabling interface: %nic_name%...
  netsh interface set interface name="%nic_name%" admin=disabled
) else (
  echo [!] Unknown action: %action%
  echo Use 'up' or 'down'.
)

echo.
netsh interface show interface | findstr /i "%nic_name%"

endlocal
