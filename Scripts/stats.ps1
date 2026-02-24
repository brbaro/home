#!/usr/bin/env pwsh

function Get-SystemInfo {
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor
  $board = Get-CimInstance Win32_BaseBoard
  $uptime = (Get-Date) - $os.LastBootUpTime
  $uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
  Write-Host "[System]" -ForegroundColor Cyan
  Write-Host "  Model:    $($cpu.Name)"
  Write-Host "  Board:    $($board.Manufacturer) $($board.Product)"
  Write-Host "  Cores:    $($cpu.NumberOfCores) Cores / $($cpu.ThreadCount) Threads"
  Write-Host "  Awake:    $uptimeStr"
}

function Get-MemoryInfo {
  $os = Get-CimInstance Win32_OperatingSystem
  $totalMem = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
  $freeMem = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
  Write-Host "`n[Memory]" -ForegroundColor Cyan
  Write-Host "  Total:    $totalMem GB"
  Write-Host "  Free:     $freeMem GB"
}

function Get-DiskInfo {
  $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"
  Write-Host "`n[Disk]" -ForegroundColor Cyan
  foreach ($disk in $disks) {
    $totalGB = [Math]::Round($disk.Size / 1GB, 2)
    $freeGB = [Math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = [Math]::Round($totalGB - $freeGB, 2)
    $usedPercent = if ($totalGB -gt 0) { [Math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
    Write-Host "  Mount:    $($disk.DeviceID)"
    Write-Host "  Usage:    $usedPercent%"
    Write-Host "  Storage:  $usedGB GB used / $totalGB GB total ($freeGB GB free)"
  }
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
  Write-Host "`n[Thermal]" -ForegroundColor Cyan
  $temp = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if ($temp) {
    foreach ($t in $temp) {
      $celsius = [Math]::Round(($t.CurrentTemperature / 10) - 273.15, 1)
      Write-Host "  Sensor:   $celsius°C"
    }
  } else {
    Write-Host "  [!] No ACPI thermal data returned." -ForegroundColor Gray
  }
}

Write-Host "`n--- System Statistics ---" -ForegroundColor Yellow
Get-SystemInfo
Get-MemoryInfo
Get-DiskInfo
Get-GpuInfo
Get-ThermalInfo
Write-Host
