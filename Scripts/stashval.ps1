function Get-ValStashRoot {
  return $env:LOCALAPPDATA
}

function Show-ValStashHelp {
  $root = Get-ValStashRoot
  $stashDir = Join-Path $root ".stash"
  Write-Host "Usage: stashval [label] | stashval [label] pop" -ForegroundColor Yellow
  Write-Host "`nCurrent Riot/Val stashes in Local AppData:" -ForegroundColor Gray
  if (Test-Path $stashDir) {
    Get-ChildItem -Path $stashDir -Directory | Select-Object -ExpandProperty Name
  } else {
    Write-Host "No stashes found in $root" -ForegroundColor DarkGray
  }
}

function Invoke-ValStash {
  param($Label, $Action)

  $env:STASH_ROOT = Get-ValStashRoot

  if ($Action -eq "pop") {
    Write-Host "[VAL-STASH] Restoring VALORANT and Riot Games from stash: $Label..." -ForegroundColor Cyan
    & "$PSScriptRoot\stash.ps1" $Label pop
  } else {
    Write-Host "[VAL-STASH] Stashing VALORANT and Riot Games into: $Label..." -ForegroundColor Green
    & "$PSScriptRoot\stash.ps1" $Label "VALORANT" "Riot Games"
  }
}

function Initialize-ValStash {
  param($Args)

  if ($Args.Count -eq 0) {
    Show-ValStashHelp
    return
  }

  $label = $Args[0]
  $action = if ($Args.Count -ge 2) { $Args[1] } else { $null }

  Invoke-ValStash -Label $label -Action $action
}

Initialize-ValStash -Args $args
