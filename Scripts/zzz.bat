@echo off

powershell -Command "Add-Type -AssemblyName 'System.Windows.Forms'; [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false)"
::rundll32.exe powrprof.dll,SetSuspendState Sleep
