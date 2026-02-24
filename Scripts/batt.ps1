#!/usr/bin/env pwsh

$charge = (Get-CimInstance -ClassName Win32_Battery).EstimatedChargeRemaining
if ($null -eq $charge) {
  Write-Host
} else {
  Write-Host "$($charge)%"
}
