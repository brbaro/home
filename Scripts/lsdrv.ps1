function Get-LSDRV {
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

Get-LSDRV
