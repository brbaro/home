#!/usr/bin/env pwsh

function Get-PCI {
  $pciDevices = Get-CimInstance Win32_PnPEntity | Where-Object { $_.DeviceID -like "PCI*" }

  Write-Host "Slot/ID`t`tManufacturer`t`tName" -ForegroundColor Cyan
  Write-Host "-------`t`t------------`t`t----" -ForegroundColor Gray

  foreach ($dev in $pciDevices) {
    $id = $dev.DeviceID -split "\\" | Select-Object -Index 1
    $manufacturer = if ($dev.Manufacturer) { $dev.Manufacturer } else { "Unknown" }

    Write-Host "$id`t" -NoNewline -ForegroundColor Yellow
    Write-Host "$manufacturer`t`t" -NoNewline -ForegroundColor White
    Write-Host "$($dev.Name)" -ForegroundColor Gray
  }
}

function Get-USB {
  $usbDevices = Get-CimInstance Win32_PnPEntity | Where-Object { $_.DeviceID -like "*USB*" }

  Write-Host "VID/PID`t`t`tStatus`t`tName" -ForegroundColor Cyan
  Write-Host "-------`t`t`t------`t`t----" -ForegroundColor Gray

  foreach ($dev in $usbDevices) {
    # Extract VID and PID using regex
    if ($dev.DeviceID -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') {
      $idString = "ID $($Matches[1]):$($Matches[2])"
    } else {
      $idString = "ID [Generic]   "
    }

    $status = if ($dev.Status -eq "OK") { "Active" } else { "Error " }
    $sColor = if ($dev.Status -eq "OK") { "Green" } else { "Red" }

    Write-Host "$idString`t" -NoNewline -ForegroundColor Yellow
    Write-Host "$status`t`t" -NoNewline -ForegroundColor $sColor
    Write-Host "$($dev.Name)" -ForegroundColor White
  }
}

function Get-DRV {
  $disks = Get-PhysicalDisk | Sort-Object DeviceId

  Write-Host "ID`tType`tHealth`tSize`t`tModel" -ForegroundColor Cyan
  Write-Host "--`t----`t------`t----`t`t-----" -ForegroundColor Gray

  foreach ($d in $disks) {
    $hColor = if ($d.HealthStatus -eq 'Healthy') { "Green" } else { "Red" }
    $type = $d.MediaType
    if ($d.BusType -eq 'NVMe') { $type = "NVMe" }

    $sizeGB = [Math]::Round($d.Size / 1GB, 0)

    Write-Host "$($d.DeviceId)`t" -NoNewline -ForegroundColor Yellow
    Write-Host "$type`t" -NoNewline -ForegroundColor White
    Write-Host "$($d.HealthStatus)`t" -NoNewline -ForegroundColor $hColor
    Write-Host "$sizeGB GB`t`t" -NoNewline -ForegroundColor White
    Write-Host "$($d.FriendlyName)" -ForegroundColor Gray
  }
}

Get-PCI
Get-USB
Get-DRV
