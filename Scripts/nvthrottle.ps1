#!/usr/bin/env pwsh

param(
  [string]$Percentage = "75"
)

$ErrorActionPreference = 'Stop'

try {
  $powerInfo = nvidia-smi -q -d POWER

  $defaultPower = [double](
    [regex]::Match(
      ($powerInfo | Select-String 'Default Power Limit'),
      '(\d+(\.\d+)?)'
    ).Value
  )

  if (-not $defaultPower) {
    throw 'Could not determine GPU default power limit.'
  }

  if ($Percentage -eq '100') {
    Write-Host "Restoring GPU defaults..." -ForegroundColor Cyan

    Start-Process pwsh `
      -Verb RunAs `
      -Wait `
      -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-Command',
        "nvidia-smi -pl $defaultPower -rgc -rmc"
      )

    Write-Host 'GPU reset 🚀' -ForegroundColor Green
    exit 0
  }

  $targetPower = [math]::Round(
    $defaultPower * ([double]$Percentage / 100)
  )

  Write-Host "Detected Power: $($defaultPower)W"
  Write-Host "Setting Power:   $($targetPower)W ($Percentage%)" -ForegroundColor Yellow

  Start-Process pwsh `
    -Verb RunAs `
    -Wait `
    -ArgumentList @(
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-Command',
      "nvidia-smi -pl $targetPower"
    )

  Write-Host 'GPU throttled 🧘' -ForegroundColor Green
}
catch {
  Write-Error "GPU throttle failed: $($_.Exception.Message)"
  exit 1
}
