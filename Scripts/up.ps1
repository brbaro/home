function Sync-HomeScripts {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

  $baseRawUrl = "https://raw.githubusercontent.com/brbaro/home/refs/heads/main/Scripts"
  Write-Host "Mi cueva su cueva... 🛠️`n" -ForegroundColor Yellow

  function Update-UserPath {
    param($Paths)
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathArray = @($currentPath -split ';' | Where-Object { $_ -match '\S' })
    $updateRequired = $false

    foreach ($p in $Paths) {
      $cleanP = $p.TrimEnd('\')
      if ($pathArray -replace '\\$', '' -notcontains $cleanP) {
        $pathArray += $cleanP
        $updateRequired = $true
        Write-Host "[+] Adding $cleanP to User PATH" -ForegroundColor Cyan
      }
    }

    if ($updateRequired) {
      $cleanPathString = ($pathArray | Where-Object { $_ -match '\S' }) -join ';'
      [Environment]::SetEnvironmentVariable("Path", $cleanPathString, "User")
      $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + $cleanPathString
    }
  }

  $files = try {
    $rawList = Invoke-WebRequest -Uri "$baseRawUrl/.brbaro.list" -UseBasicParsing -ErrorAction Stop
    $rawList.Content -split "[\r\n]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
  } catch {
    Write-Host "[!] Error: Could not fetch script list" -ForegroundColor Red
    return
  }

  $destDir = "$HOME\Scripts"
  $batsDir = Join-Path $destDir "Bats"
  $localDir = Join-Path $destDir "Local"
  $ignoreList = @(".brbaro.list", "Local", "Cache", "Bats")

  foreach ($dir in @($destDir, $batsDir, $localDir)) {
    if (!(Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
  }

  Write-Host "Cleaning up orphaned scripts in $destDir..." -ForegroundColor Yellow
  @($destDir, $batsDir) | ForEach-Object {
    $currentSearchPath = $_
    if (Test-Path $currentSearchPath) {
      Get-ChildItem -Path $currentSearchPath -File | ForEach-Object {
        if ($files -notcontains $_.Name -and $ignoreList -notcontains $_.Name) {
          Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
          Write-Host "  [-] Removed: $($_.Name)" -ForegroundColor DarkRed
        }
      }
    }
  }

  Write-Host "Fetching $($files.Count) scripts from GitHub..." -ForegroundColor Cyan
  foreach ($fileName in $files) {
    $targetDir = $destDir
    if ($fileName.EndsWith(".bat") -and $fileName -notmatch "^(powsh|batsh)\.bat$") {
      $targetDir = $batsDir
    }

    $targetPath = Join-Path $targetDir $fileName
    $url = "$baseRawUrl/$fileName"

    try {
      $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
      $finalContent = $response.Content -replace "\r\n", "`n" -replace "\r", "`n"
      if ($fileName.EndsWith(".bat")) { $finalContent = $finalContent -replace "\n", "`r`n" }

      $shouldWrite = $true
      if (Test-Path $targetPath) {
        $localContent = [System.IO.File]::ReadAllText($targetPath)
        if ($finalContent.Trim() -eq $localContent.Trim()) { $shouldWrite = $false }
      }

      if ($shouldWrite) {
        [System.IO.File]::WriteAllText($targetPath, $finalContent)
        Write-Host "  [+] Synced: $fileName to $(Split-Path $targetDir -Leaf)" -ForegroundColor Gray
      } else {
        Write-Host "  [-] Skipped: $fileName" -ForegroundColor DarkGray
      }
    } catch {
      Write-Host "  [!] Failed: $fileName" -ForegroundColor Red
    }
  }

  Update-UserPath -Paths @($destDir, $batsDir, $localDir)
  Write-Host "`nBárbaro! 🚀" -ForegroundColor Green
}

if ($args -contains "-x") {
  Write-Host "[!] Bootstrapping..." -ForegroundColor Magenta
  Invoke-RestMethod -Uri "https://raw.githubusercontent.com/brbaro/home/refs/heads/main/Scripts/up.ps1" -UseBasicParsing | Invoke-Expression
} else {
  Sync-HomeScripts
}
