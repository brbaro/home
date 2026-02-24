function Get-StashRoot {
  if ($env:STASH_ROOT -and (Test-Path $env:STASH_ROOT)) {
    return $env:STASH_ROOT
  }
  return $PWD
}

function Get-StashDirectory {
  param($Root)
  return Join-Path $Root ".stash"
}

function Show-StashHelp {
  Write-Host "Usage:   stash [label] [files...] or [label] pop" -ForegroundColor Yellow
  Write-Host "Example: stash work project.zip document.docx" -ForegroundColor Gray
  Write-Host "         stash work pop" -ForegroundColor Gray
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
  if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

  foreach ($file in $Files) {
    if (Test-Path $file) {
      Write-Host "[>] Stashing: $file" -ForegroundColor Green
      Move-Item -Path $file -Destination $targetDir -Force
    } else {
      Write-Host "[!] Skipping: $file (Not found)" -ForegroundColor Yellow
    }
  }
}

function Invoke-StashManager {
  param($Args)
  $root = Get-StashRoot
  $stashFolder = Get-StashDirectory -Root $root

  if ($Args.Count -eq 0) { Show-StashHelp; return }
  if ($Args[0] -eq "list") { List-Stashes -StashFolder $stashFolder; return }

  $label = $Args[0]
  if ($Args.Count -eq 2 -and $Args[1] -eq "pop") {
    Pop-Stash -Label $label -StashFolder $stashFolder -CurrentRoot $root
  } else {
    $files = $Args[1..($Args.Count - 1)]
    Create-Stash -Label $label -Files $files -StashFolder $stashFolder
  }
}

Invoke-StashManager -Args $args
