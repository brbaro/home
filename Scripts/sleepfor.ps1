#!/usr/bin/env pwsh

function Sleep-For {
  param(
    [Parameter(Position = 0)]
    [string]$Time
  )

  if ([string]::IsNullOrWhiteSpace($Time)) { return }

  $seconds = Convert-TimeToSeconds -TimeInput $Time
  if ($seconds -gt 0) { Start-Sleep -Seconds $seconds }
}

function Convert-TimeToSeconds {
  param([string]$TimeInput)

  if ($TimeInput -match '^(\d+)([smh])?$') {
    $amount = [int]$Matches[1]
    $unit = if ($Matches[2]) { $Matches[2] } else { 's' }

    switch ($unit) {
      's' { return $amount }
      'm' { return $amount * 60 }
      'h' { return $amount * 3600 }
    }
  }

  return 0
}

Sleep-For @args
