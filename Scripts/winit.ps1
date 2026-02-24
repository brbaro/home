function Initialize-WindowsSetup {
  Write-Host "[*] Applying Windows Initializations..." -ForegroundColor Cyan

  Set-DesktopExperience
  Set-ExplorerPreferences
  Set-VisualThemes
  Set-MouseOptimization
  Invoke-SystemTweaks
  Initialize-FirewallConfig

  Write-Host "[+] All tweaks applied successfully." -ForegroundColor Green

  $ask = Read-Host "Log out to apply changes? [y/N]"
  if ($ask -eq "y") {
    Write-Host "Logging out..." -ForegroundColor Cyan
    shutdown.exe /l
  }
}

function Set-DesktopExperience {
  $desktop = "HKCU:\Control Panel\Desktop"
  $metrics = "HKCU:\Control Panel\Desktop\WindowMetrics"
  $colors  = "HKCU:\Control Panel\Colors"

  Set-ItemProperty -Path $colors -Name "Background" -Value "0 0 0"
  Set-ItemProperty -Path $desktop -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
  Set-ItemProperty -Path $desktop -Name "MenuShowDelay" -Value "0"
  Set-ItemProperty -Path $desktop -Name "Wallpaper" -Value ""
  Set-ItemProperty -Path $desktop -Name "WallpaperStyle" -Value "0"
  Set-ItemProperty -Path $desktop -Name "TileWallpaper" -Value "0"
  Set-ItemProperty -Path $metrics -Name "MinAnimate" -Value "0"
}

function Set-ExplorerPreferences {
  $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

  Set-ItemProperty -Path $advanced -Name "Hidden" -Value 1
  Set-ItemProperty -Path $advanced -Name "HideFileExt" -Value 0
  Set-ItemProperty -Path $advanced -Name "HideIcons" -Value 1
  Set-ItemProperty -Path $advanced -Name "TaskbarAl" -Value 1
  Set-ItemProperty -Path $advanced -Name "TaskbarAnimations" -Value 0
}

function Set-VisualThemes {
  $personalize = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
  $dwm = "HKCU:\Software\Microsoft\Windows\DWM"

  Set-ItemProperty -Path $personalize -Name "AppsUseLightTheme" -Value 0
  Set-ItemProperty -Path $personalize -Name "EnableTransparency" -Value 0
  Set-ItemProperty -Path $personalize -Name "SystemUsesLightTheme" -Value 0
  Set-ItemProperty -Path $dwm -Name "EnableAeroPeek" -Value 0
  Set-ItemProperty -Path $dwm -Name "Animations" -Value 0
}

function Set-MouseOptimization {
  $mouse = "HKCU:\Control Panel\Mouse"

  Set-ItemProperty -Path $mouse -Name "MouseHoverTime" -Value "0"
  Set-ItemProperty -Path $mouse -Name "MouseSpeed" -Value "0"
  Set-ItemProperty -Path $mouse -Name "MouseThreshold1" -Value "0"
  Set-ItemProperty -Path $mouse -Name "MouseThreshold2" -Value "0"
  Set-ItemProperty -Path $mouse -Name "MouseSensitivity" -Value "6"
}

function Invoke-SystemTweaks {
  $disableHibernate = Read-Host "Disable hibernation? [y/N]"
  if ($disableHibernate -eq "y") {
    Write-Host "[!] Disabling hibernation..." -ForegroundColor Yellow
    wudo powercfg -h off
  }

  $utcTime = Read-Host "Set RealTimeIsUniversal (Dual Boot Fix)? [y/N]"
  if ($utcTime -eq "y") {
    $tzPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
    wudo powershell -Command "Set-ItemProperty -Path '$tzPath' -Name 'RealTimeIsUniversal' -Value 1 -Type DWord"
  }
}

function Test-AdministrativePrivileges {
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Elevate-ToAdministrator {
  Write-Host "[!] Not running as Admin. Elevating with wudo..." -ForegroundColor Yellow
  wudo "powershell -ExecutionPolicy Bypass -File ""$PSCommandPath"""
  exit
}

function Set-SecureFirewallPolicy {
  Write-Host "[!] Configuring Firewall..." -ForegroundColor Cyan
  Set-NetFirewallProfile -All -DefaultInboundAction Block -DefaultOutboundAction Allow -Enabled True
}

function Show-FirewallStatus {
  Write-Host "[+] Inbound connections blocked on all profiles." -ForegroundColor Green
  Write-Host "[+] Outbound connections remain allowed." -ForegroundColor Green
  Write-Host "[+] Firewall is active.`n" -ForegroundColor Green
  Write-Host "Current Status:" -ForegroundColor Gray
  Write-Host "------------------------------------------------------------" -ForegroundColor Gray
  Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table
  Write-Host "------------------------------------------------------------" -ForegroundColor Gray
}

function Initialize-FirewallConfig {
  $initFirewall = Read-Host "Initialize Firewall? [y/N]"
  if ($initFirewall -eq "y") {
    if (-not (Test-AdministrativePrivileges)) {
      Elevate-ToAdministrator
    }
    Set-SecureFirewallPolicy
    Show-FirewallStatus
  }
}

Initialize-WindowsSetup
