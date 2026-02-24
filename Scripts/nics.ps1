#!/usr/bin/env pwsh

param($action, $name)
if (!$action) {
  Write-Host "--- Network Interfaces ---" -ForegroundColor Cyan
  Get-NetAdapter | Select-Object Name, Status, InterfaceDescription | Format-Table
  Write-Host "Usage: nics [up/down] 'Interface Name'" -ForegroundColor Gray
  return
}
if (!$name) {
  Write-Host "[!] Error: Specify interface name (e.g., nics up 'Ethernet')" -ForegroundColor Red
  return
}
if ($action -eq "up") {
  Enable-NetAdapter -Name $name -Confirm:$false
  Write-Host "[+] Enabling $name..." -ForegroundColor Green
} elseif ($action -eq "down") {
  Disable-NetAdapter -Name $name -Confirm:$false
  Write-Host "[-] Disabling $name..." -ForegroundColor Yellow
}
Get-NetAdapter -Name $name | Select-Object Name, Status
