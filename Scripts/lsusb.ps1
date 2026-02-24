function Get-LSUSB {
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

Get-LSUSB
