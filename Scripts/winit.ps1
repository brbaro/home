#!/usr/bin/env pwsh

function SetProperty {
  param(
    [Parameter(Mandatory = $true)]
    $Path,

    [Parameter(Mandatory = $true)]
    $Name,

    [Parameter(Mandatory = $true)]
    $Value,

    $Type
  )

  $parts = @(
    "Path=$Path"
    "Name=$Name"
    "Value=$Value"
  )

  if ($PSBoundParameters.ContainsKey('Type')) {
    $parts += "Type=$Type"
  }

  Write-Host ($parts -join ' ') -ForegroundColor Gray

  Set-ItemProperty @PSBoundParameters
}

function Initialize-WindowsSetup {
  Write-Host "[*] Applying Windows Initializations..." -ForegroundColor Cyan

  Set-DesktopExperience
  Set-ExplorerPreferences
  Set-VisualThemes
  Set-MouseOptimization
  Set-ContentDeliveryDisabled

  Write-Host "[+] All tweaks applied successfully." -ForegroundColor Green
  $ask = Read-Host "Log out to apply changes? [y/N]"
  if ($ask -eq "y") {
    Write-Host "Logging out..." -ForegroundColor Cyan
    shutdown.exe /l
  }
}

function Set-ContentDeliveryDisabled {
  SetProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord
}

function Set-DesktopExperience {
  $desktop = "HKCU:\Control Panel\Desktop"
  $metrics = "HKCU:\Control Panel\Desktop\WindowMetrics"
  $colors  = "HKCU:\Control Panel\Colors"

  SetProperty -Path $colors -Name "Background" -Value "0 0 0"
  SetProperty -Path $desktop -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
  SetProperty -Path $desktop -Name "MenuShowDelay" -Value "0"
  SetProperty -Path $desktop -Name "Wallpaper" -Value ""
  SetProperty -Path $desktop -Name "WallpaperStyle" -Value "0"
  SetProperty -Path $desktop -Name "TileWallpaper" -Value "0"
  SetProperty -Path $metrics -Name "MinAnimate" -Value "0"
}

function Set-ExplorerPreferences {
  $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

  SetProperty -Path $advanced -Name "Hidden" -Value 1
  SetProperty -Path $advanced -Name "HideFileExt" -Value 0
  SetProperty -Path $advanced -Name "HideIcons" -Value 1
  SetProperty -Path $advanced -Name "TaskbarAl" -Value 1
  SetProperty -Path $advanced -Name "TaskbarAnimations" -Value 0
}

function Set-VisualThemes {
  $personalize = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
  $dwm = "HKCU:\Software\Microsoft\Windows\DWM"

  SetProperty -Path $personalize -Name "AppsUseLightTheme" -Value 0
  SetProperty -Path $personalize -Name "EnableTransparency" -Value 0
  SetProperty -Path $personalize -Name "SystemUsesLightTheme" -Value 0
  SetProperty -Path $dwm -Name "EnableAeroPeek" -Value 0
  SetProperty -Path $dwm -Name "Animations" -Value 0
}

function Set-MouseOptimization {
  $mouse = "HKCU:\Control Panel\Mouse"

  SetProperty -Path $mouse -Name "MouseHoverTime" -Value "0"
  SetProperty -Path $mouse -Name "MouseSpeed" -Value "0"
  SetProperty -Path $mouse -Name "MouseThreshold1" -Value "0"
  SetProperty -Path $mouse -Name "MouseThreshold2" -Value "0"
  SetProperty -Path $mouse -Name "MouseSensitivity" -Value "6"
}

function Set-SecureFirewallPolicy {
  Write-Host "[!] Configuring Firewall..." -ForegroundColor Cyan
  Set-NetFirewallProfile -All -DefaultInboundAction Block -DefaultOutboundAction Allow -Enabled True
  Write-Host "[+] Inbound connections blocked on all profiles." -ForegroundColor Green
  Write-Host "[+] Outbound connections remain allowed." -ForegroundColor Green
  Write-Host "[+] Firewall is active.`n" -ForegroundColor Green
}

function Set-AdminOptions {
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v "RealTimeIsUniversal" /t REG_DWORD /d 1 /f
  gpupdate /force
  powercfg /hibernate off
}

Initialize-WindowsSetup
