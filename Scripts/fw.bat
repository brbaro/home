@echo off
setlocal

openfiles >nul 2>&1
if %errorlevel% neq 0 (
  echo [!] Not running as Admin. Elevating with wudo...
  wudo "%~f0" %*
  exit /b
)

echo [!] Configuring Firewall...

(
  netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound
  netsh advfirewall set allprofiles state on
) >nul

echo [+] Inbound connections blocked on Domain, Private, and Public profiles.
echo [+] Outbound connections remain allowed.
echo [+] Firewall is active.

echo.
echo Current Status:
------------------------------------------------------------
netsh advfirewall show allprofiles | findstr /C:"Policy" /C:"State"
------------------------------------------------------------

endlocal
