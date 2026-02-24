function Get-StashRoot {
  if ($env:STASH_ROOT -and (Test-Path $env:STASH_ROOT)) {
    return $env:STASH_ROOT
  }
  return $PWD
}

function Get-StashDirectory {
  param($Root)
  return Join-Path $Root "_STASH_"
}

function Show-StashHelp {
  Write-Host "Usage:   stash [label] [files...] or [label] pop" -ForegroundColor Yellow
}

function List-Stashes {
  param($StashFolder)
  if (-not (Test-Path $StashFolder)) {
    Write-Host "No stashes found." -ForegroundColor Gray
    return
  }
  Write-Host "[ Stash Directory: $StashFolder ]" -ForegroundColor Cyan
  Get-ChildItem -Path $StashFolder -Directory | Select-Object -ExpandProperty Name
}

function Pop-Stash {
  param($Label, $StashFolder, $CurrentRoot)
  $targetDir = Join-Path $StashFolder $Label
  if (-not (Test-Path $targetDir)) {
    Write-Host "[!] Stash '$Label' not found." -ForegroundColor Red
    return
  }

  Write-Host "[!] Popping stash: $Label" -ForegroundColor Cyan
  Get-ChildItem -Path $targetDir | ForEach-Object {
    $destination = Join-Path $CurrentRoot $_.Name
    if (Test-Path $destination) {
      $confirm = Read-Host "[?] Overwrite $($_.Name)? (y/n)"
      if ($confirm -eq 'y') {
        Remove-Item -Path $destination -Recurse -Force
        Move-Item -Path $_.FullName -Destination $CurrentRoot -Force
      }
    } else {
      Move-Item -Path $_.FullName -Destination $CurrentRoot -Force
    }
  }

  Remove-Item -Path $targetDir -Force
}

function Create-Stash {
  param($Label, $Files, $StashFolder)
  $targetDir = Join-Path $StashFolder $Label
  $root = Get-StashRoot # Get the base (LocalAppdata)

  if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  }

  foreach ($file in $Files) {
    $fullSourcePath = Join-Path $root $file

    if (Test-Path $fullSourcePath) {
      Write-Host "[>] Stashing: $file" -ForegroundColor Green
      Move-Item -Path $fullSourcePath -Destination $targetDir -Force
    } else {
      Write-Host "[!] Skipping: $file (Not found at $fullSourcePath)" -ForegroundColor Yellow
    }
  }
}

function Invoke-StashManager {
  param($Inputs)
  $root = Get-StashRoot
  $stashFolder = Get-StashDirectory -Root $root

  if ($Inputs.Count -eq 0) { Show-StashHelp; return }
  if ($Inputs[0] -eq "list") { List-Stashes -StashFolder $stashFolder; return }

  $label = $Inputs[0]
  if ($Inputs.Count -ge 2 -and $Inputs[1] -eq "pop") {
    Pop-Stash -Label $label -StashFolder $stashFolder -CurrentRoot $root
  } else {
    $files = $Inputs[1..($Inputs.Count - 1)]
    Create-Stash -Label $label -Files $files -StashFolder $stashFolder
  }
}

Invoke-StashManager -Inputs $args
