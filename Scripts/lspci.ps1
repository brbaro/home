function Get-LSPCI {
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

Get-LSPCI
