#!/usr/bin/env pwsh

function Zen {
  $processes = @(
    'explorer', 'StartMenuExperienceHost', 'ShellExperienceHost', 'SearchHost', 'TextInputHost',
    'Widgets', 'WidgetService', 'Copilot', 'YourPhone', 'PhoneExperienceHost', 'Teams', 'MSTeams',
    'GameBar', 'GameBarFTServer', 'GameBarPresenceWriter', 'XboxPcApp', 'XboxGameBarWidgets',
    'OneDrive', 'msedge', 'msedgewebview2', 'MicrosoftEdgeUpdate'
  ) # 'SystemSettings','ShellAppRuntime'

  try {
    foreach ($name in $processes) {
      Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    $shellScript = 'Set-Location -LiteralPath $HOME; $rc = Join-Path $env:USERPROFILE ''Scripts\pwshrc.ps1''; if (Test-Path -LiteralPath $rc) { . $rc }'
    $shellCommand = '"' + (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') + '" -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass -Command "' + $shellScript + '"'

    Set-ItemProperty `
      -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' `
      -Name 'Shell' `
      -Type String `
      -Value $shellCommand

    Set-ItemProperty `
      -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' `
      -Name 'AutoRestartShell' `
      -Type DWord `
      -Value 1

    Write-Host 'Tranquilo 🧘' -ForegroundColor Cyan
  }
  catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
  }
}

function Unzen {
  try {
    Set-ItemProperty `
      -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' `
      -Name 'AutoRestartShell' `
      -Type DWord `
      -Value 1 `
      -ErrorAction SilentlyContinue

    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
      Start-Process explorer.exe
    }
    Set-ItemProperty `
      -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' `
      -Name 'Shell' `
      -Type String `
      -Value 'explorer.exe'

    Write-Host 'Bárbaro! 🚀' -ForegroundColor Green
  }
  catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
  }
}

if ($args.Count -gt 0 -and $args[0].ToLower() -eq 'off') { Unzen }
else { Zen }
