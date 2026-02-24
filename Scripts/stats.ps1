param([bool]$Elevated = $false)

function Get-SystemInfo {
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor
  $uptime = (Get-Date) - $os.LastBootUpTime
  $uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

  Write-Host "[System]" -ForegroundColor Cyan
  Write-Host "  Uptime:   $uptimeStr"
  Write-Host "  Model:    $($cpu.Name)"
  Write-Host "  Cores:    $($cpu.NumberOfCores) Cores / $($cpu.ThreadCount) Threads"
}

function Get-MemoryInfo {
  $os = Get-CimInstance Win32_OperatingSystem
  $totalMem = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
  $freeMem = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)

  Write-Host "`n[Memory]" -ForegroundColor Cyan
  Write-Host "  Total:    $totalMem GB"
  Write-Host "  Free:     $freeMem GB"
}

function Get-GpuInfo {
  $gpu = Get-CimInstance Win32_VideoController
  Write-Host "`n[GPU]" -ForegroundColor Cyan
  foreach ($g in $gpu) {
    Write-Host "  Name:     $($g.Name)"
    Write-Host "  Driver:   $($g.DriverVersion)"
  }
}

function Get-ThermalInfo {
  param([bool]$IsAdmin)
  Write-Host "`n[Thermal]" -ForegroundColor Cyan
  if ($IsAdmin) {
    $temp = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($temp) {
      foreach ($t in $temp) {
        $celsius = [Math]::Round(($t.CurrentTemperature / 10) - 273.15, 1)
        Write-Host "  Sensor:   $celsius°C"
      }
    } else {
      Write-Host "  [!] No ACPI thermal data returned." -ForegroundColor Gray
    }
  } else {
    Write-Host "  [!] Run with 'wudo' to view temperature data." -ForegroundColor Gray
  }
}

Write-Host "`n--- System Statistics ---" -ForegroundColor Yellow
Get-SystemInfo
Get-MemoryInfo
Get-GpuInfo
Get-ThermalInfo -IsAdmin $Elevated
Write-Host
