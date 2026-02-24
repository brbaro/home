#!/usr/bin/env pwsh

param(
  [Parameter(Position = 0)]
  [string]$Action,

  [Parameter(Position = 1)]
  [string]$PackageName
)

function Get-PaxConfiguration {
  $baseUrl = if ($env:PAX_URL) { $env:PAX_URL.TrimEnd('/') } else { 'https://brbaro.web.app/pax' }
  if ($baseUrl -notmatch '^[a-z]+://') { $baseUrl = "https://$baseUrl" }

  $root = Join-Path $env:LOCALAPPDATA 'Pax'

  return @{
    Url      = $baseUrl
    Root     = $root
    Cache    = Join-Path $root 'cache'
    Work     = Join-Path $root 'work'
    Portable = $root
  }
}

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
  }
}

function Normalize-PaxPathEntry {
  param([string]$PathValue)

  if ([string]::IsNullOrWhiteSpace($PathValue)) { return $null }

  $normalized = $PathValue.Trim().Trim('"')
  while ($normalized.Length -gt 3 -and ($normalized.EndsWith('\\') -or $normalized.EndsWith('/'))) {
    $normalized = $normalized.Substring(0, $normalized.Length - 1)
  }

  return $normalized
}

function Test-PaxPathEntryExists {
  param(
    [string]$PathValue,
    [string]$TargetDir
  )

  $normalizedTarget = Normalize-PaxPathEntry -PathValue $TargetDir
  if (-not $normalizedTarget) { return $false }

  foreach ($segment in ($PathValue -split ';')) {
    $normalizedSegment = Normalize-PaxPathEntry -PathValue $segment
    if ($normalizedSegment -and $normalizedSegment -eq $normalizedTarget) {
      return $true
    }
  }

  return $false
}

function Remove-PaxPathEntry {
  param([string]$TargetDir)

  $normalizedTarget = Normalize-PaxPathEntry -PathValue $TargetDir
  if (-not $normalizedTarget) { return }

  $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $filteredUserEntries = foreach ($segment in ($currentUserPath -split ';')) {
    $normalizedSegment = Normalize-PaxPathEntry -PathValue $segment
    if ($normalizedSegment -and $normalizedSegment -ne $normalizedTarget) {
      $normalizedSegment
    }
  }
  [Environment]::SetEnvironmentVariable('Path', (@($filteredUserEntries) -join ';'), 'User')

  $filteredSessionEntries = foreach ($segment in ($env:Path -split ';')) {
    $normalizedSegment = Normalize-PaxPathEntry -PathValue $segment
    if ($normalizedSegment -and $normalizedSegment -ne $normalizedTarget) {
      $normalizedSegment
    }
  }
  $env:Path = @($filteredSessionEntries) -join ';'
}

function Update-UserEnvironmentPath {
  param([string]$TargetDir)

  $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not (Test-PaxPathEntryExists -PathValue $currentPath -TargetDir $TargetDir)) {
    $newPath = if ([string]::IsNullOrWhiteSpace($currentPath)) {
      $TargetDir
    } else {
      "$($currentPath.TrimEnd(';'));$TargetDir"
    }

    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    if (-not (Test-PaxPathEntryExists -PathValue $env:Path -TargetDir $TargetDir)) {
      $env:Path = if ([string]::IsNullOrWhiteSpace($env:Path)) {
        $TargetDir
      } else {
        "$($env:Path.TrimEnd(';'));$TargetDir"
      }
    }

    Write-Host "[+] PATH Registered: $TargetDir" -ForegroundColor Cyan
  }
}

function Get-PaxPackageItems {
  param([string]$Path)

  return @(Get-ChildItem -Path $Path -Force | Where-Object {
    $_.Name -ne '__MACOSX' -and
    $_.Name -ne '.DS_Store' -and
    -not $_.Name.StartsWith('._')
  })
}

function Resolve-PaxPortablePathTarget {
  param([string]$Destination)

  $destinationItems = @(Get-PaxPackageItems -Path $Destination)
  $destinationDirectories = @($destinationItems | Where-Object { $_.PSIsContainer })
  $destinationFiles = @($destinationItems | Where-Object { -not $_.PSIsContainer })

  if ($destinationFiles.Count -eq 0 -and $destinationDirectories.Count -eq 1) {
    return $destinationDirectories[0].FullName
  }

  return $Destination
}

function Collapse-SingleDirectoryLayers {
  param(
    [string]$Destination,
    [string]$PackageName
  )

  while ($true) {
    $items = @(Get-PaxPackageItems -Path $Destination)
    $dirs = @($items | Where-Object { $_.PSIsContainer })
    $files = @($items | Where-Object { -not $_.PSIsContainer })

    Write-Host "[dbg] collapse scan: dest=$Destination dirs=$($dirs.Count) files=$($files.Count)" -ForegroundColor DarkGray

    if ($files.Count -gt 0 -or $dirs.Count -ne 1) {
      break
    }

    $onlyDir = $dirs[0]
    $nameMatchesPackage = $onlyDir.Name.Equals($PackageName, [System.StringComparison]::OrdinalIgnoreCase)
    $nameStartsWithPackage = $onlyDir.Name.StartsWith($PackageName, [System.StringComparison]::OrdinalIgnoreCase)

    if (-not ($nameMatchesPackage -or $nameStartsWithPackage)) {
      Write-Host "[dbg] collapse stop: wrapper '$($onlyDir.Name)' does not match package '$PackageName'" -ForegroundColor DarkGray
      break
    }

    Write-Host "[dbg] collapse enter: wrapper=$($onlyDir.FullName)" -ForegroundColor DarkGray
    $children = @(Get-PaxPackageItems -Path $onlyDir.FullName)
    foreach ($child in $children) {
      $targetPath = Join-Path $Destination $child.Name
      $childPath = $child.FullName

      if ($child.PSIsContainer -and (Test-Path -LiteralPath $targetPath -PathType Container)) {
        $normalizedChild = (Get-Item $childPath).FullName
        $normalizedTarget = (Get-Item $targetPath).FullName
        $normalizedWrapper = (Get-Item $onlyDir.FullName).FullName
        if ($normalizedChild -ieq $normalizedTarget -or $normalizedTarget -ieq $normalizedWrapper) {
          $nested = @(Get-PaxPackageItems -Path $childPath)
          foreach ($nestedItem in $nested) {
            Write-Host "[dbg] self-merge move: $($nestedItem.FullName) -> $Destination" -ForegroundColor DarkGray
            Move-Item -Path $nestedItem.FullName -Destination $Destination -Force -ErrorAction Stop
          }
        }
        else {
          $nested = @(Get-PaxPackageItems -Path $childPath)
          foreach ($nestedItem in $nested) {
            Write-Host "[dbg] merge move: $($nestedItem.FullName) -> $targetPath" -ForegroundColor DarkGray
            Move-Item -Path $nestedItem.FullName -Destination $targetPath -Force -ErrorAction Stop
          }
          Write-Host "[dbg] merge cleanup: $childPath" -ForegroundColor DarkGray
          Remove-Item -Path $childPath -Recurse -Force -ErrorAction SilentlyContinue
        }
      }
      else {
        Write-Host "[dbg] direct move: $childPath -> $Destination" -ForegroundColor DarkGray
        Move-Item -Path $childPath -Destination $Destination -Force -ErrorAction Stop
      }
    }
    Write-Host "[dbg] remove wrapper: $($onlyDir.FullName)" -ForegroundColor DarkGray
    Remove-Item -Path $onlyDir.FullName -Recurse -Force
  }
}

function Deploy-PortableItems {
  param(
    [object[]]$Items,
    [hashtable]$Config,
    [string]$Name
  )

  $destination = Join-Path $Config.Portable $Name
  if (Test-Path -LiteralPath $destination) {
    Remove-Item -Path $destination -Recurse -Force
  }
  New-Item -Path $destination -ItemType Directory -Force | Out-Null

  foreach ($item in @($Items)) {
    Move-Item -Path $item.FullName -Destination $destination -Force
  }

  Collapse-SingleDirectoryLayers -Destination $destination -PackageName $Name

  $pathTarget = Resolve-PaxPortablePathTarget -Destination $destination
  if ($pathTarget -ne $destination) {
    Remove-PaxPathEntry -TargetDir $destination
  }

  Update-UserEnvironmentPath -TargetDir $pathTarget
}

function Receive-PaxPackage {
  param(
    [hashtable]$Config,
    [string]$Name,
    [string]$PaxPath,
    [string]$ZipPath
  )

  Write-Host "[+] Fetching $Name.pax" -ForegroundColor Gray
  $payload = Invoke-RestMethod -Uri "$($Config.Url)/$Name.pax" -UseBasicParsing
  if ([string]::IsNullOrWhiteSpace($payload)) {
    throw "Package '$Name' returned an empty payload."
  }

  Set-Content -Path $PaxPath -Value $payload -NoNewline

  try {
    $bytes = [Convert]::FromBase64String(($payload -replace '\s+', ''))
  }
  catch {
    throw "Package '$Name' is not valid base64."
  }

  [IO.File]::WriteAllBytes($ZipPath, $bytes)
}

function Get-PaxListMap {
  param([hashtable]$Config)

  Write-Host '[+] Fetching pax.list' -ForegroundColor Gray
  $listContent = Invoke-RestMethod -Uri "$($Config.Url)/pax.list" -UseBasicParsing
  if ([string]::IsNullOrWhiteSpace($listContent)) {
    throw 'pax.list is empty or unreadable.'
  }

  $map = @{}
  $lines = $listContent -split "`r?`n"

  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if (-not $trimmed) { continue }
    if ($trimmed.StartsWith('#')) { continue }

    if ($trimmed -notmatch '^(?<sha>[A-Fa-f0-9]{64})\s+(?<name>\S+)$') {
      continue
    }

    $filename = $matches['name']
    $sha = $matches['sha'].ToLowerInvariant()
    $map[$filename] = $sha
  }

  return $map
}

function Get-FileSha256 {
  param([string]$Path)

  $hash = Get-FileHash -Path $Path -Algorithm SHA256
  return $hash.Hash.ToLowerInvariant()
}

function Assert-PaxPackageIntegrity {
  param(
    [hashtable]$Config,
    [string]$Name,
    [string]$ZipPath
  )

  $listMap = Get-PaxListMap -Config $Config
  $packageFile = "$Name.pax"

  if (-not $listMap.ContainsKey($packageFile)) {
    throw "No SHA entry found in pax.list for '$packageFile'."
  }

  $expected = $listMap[$packageFile]
  $actual = Get-FileSha256 -Path $ZipPath

  if ($expected -ne $actual) {
    throw "SHA mismatch for '$packageFile'. Expected '$expected', got '$actual'."
  }

  Write-Host "[+] Integrity OK: $packageFile" -ForegroundColor Cyan
}

function Invoke-PaxInstallScript {
  param(
    [string]$ScriptPath,
    [string]$Name,
    [hashtable]$Config,
    [string]$WorkPath,
    [string]$CachePath
  )

  Write-Host "[+] Running install script: $ScriptPath" -ForegroundColor Cyan

  $env:PAX_PACKAGE_NAME = $Name
  $env:PAX_ROOT = $Config.Root
  $env:PAX_WORK = $WorkPath
  $env:PAX_CACHE = $CachePath

  try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
    if ($LASTEXITCODE -ne 0) {
      throw "install.ps1 exited with code $LASTEXITCODE."
    }
  }
  finally {
    Remove-Item Env:PAX_PACKAGE_NAME -ErrorAction SilentlyContinue
    Remove-Item Env:PAX_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:PAX_WORK -ErrorAction SilentlyContinue
    Remove-Item Env:PAX_CACHE -ErrorAction SilentlyContinue
  }
}

function Start-PaxInstaller {
  param(
    [IO.FileInfo]$Installer,
    [string]$Name
  )

  Write-Host "[+] Launching installer for ${Name}: $($Installer.Name)" -ForegroundColor Cyan
  $ext = $Installer.Extension.ToLowerInvariant()

  if ($ext -eq '.msi') {
    Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', "`"$($Installer.FullName)`"") # -Wait
  }
  elseif ($ext -eq '.exe') {
    Start-Process -FilePath $Installer.FullName # -Wait
  }
  else {
    throw "Unsupported installer type '$ext'."
  }
}

function Find-InstallScript {
  param([string]$ExtractPath)

  $rootScript = Join-Path $ExtractPath 'install.ps1'
  if (Test-Path -LiteralPath $rootScript -PathType Leaf) {
    return $rootScript
  }

  $nested = @(Get-ChildItem -Path $ExtractPath -Filter 'install.ps1' -Recurse -File)
  if ($nested.Count -eq 0) { return $null }
  if ($nested.Count -eq 1) { return $nested[0].FullName }

  $paths = ($nested | ForEach-Object { $_.FullName }) -join ', '
  throw "Multiple install.ps1 files found: $paths"
}

function Invoke-PaxInstall {
  param([string]$Name)

  $config = Get-PaxConfiguration
  Ensure-Directory -Path $config.Root
  Ensure-Directory -Path $config.Cache
  Ensure-Directory -Path $config.Work

  $cacheDir = Join-Path $config.Cache $Name
  $workDir = Join-Path $config.Work $Name
  Ensure-Directory -Path $cacheDir

  $paxPath = Join-Path $cacheDir "$Name.pax"
  $zipPath = Join-Path $cacheDir "$Name.zip"

  if (Test-Path -LiteralPath $workDir) {
    Remove-Item -Path $workDir -Recurse -Force
  }

  try {
    Receive-PaxPackage -Config $config -Name $Name -PaxPath $paxPath -ZipPath $zipPath
    Assert-PaxPackageIntegrity -Config $config -Name $Name -ZipPath $zipPath

    Expand-Archive -Path $zipPath -DestinationPath $workDir -Force

    $rootItems = @(Get-PaxPackageItems -Path $workDir)
    if ($rootItems.Count -eq 0) {
      throw "Package '$Name' is empty after extraction."
    }

    $installScript = Find-InstallScript -ExtractPath $workDir
    if ($installScript) {
      Invoke-PaxInstallScript -ScriptPath $installScript -Name $Name -Config $config -WorkPath $workDir -CachePath $cacheDir
      Write-Host "`nDone." -ForegroundColor Green
      return
    }

    $allFiles = @(Get-ChildItem -Path $workDir -Recurse -File | Where-Object {
      $_.Name -ne '.DS_Store' -and -not $_.Name.StartsWith('._')
    })

    if ($allFiles.Count -eq 1 -and $allFiles[0].Extension.ToLowerInvariant() -in @('.exe', '.msi')) {
      Start-PaxInstaller -Installer $allFiles[0] -Name $Name
      Write-Host "`nDone." -ForegroundColor Green
      return
    }

    Write-Host "[+] No install.ps1 or single installer found; using legacy portable deploy for $Name..." -ForegroundColor Gray
    Deploy-PortableItems -Items $rootItems -Config $config -Name $Name
    Write-Host "`nDone." -ForegroundColor Green
  }
  finally {
    $confirm = Read-Host "Remove installer file? (y/n)"
    if ($confirm -ne "y") {
      if (Test-Path -LiteralPath $workDir) {
        Remove-Item -Path $workDir -Recurse -Force
      }
    }
  }
}

$resolvedAction = if ($Action) { $Action } elseif ($args.Count -gt 0) { $args[0] } else { $null }
$resolvedPackageName = if ($PackageName) { $PackageName } elseif ($args.Count -gt 1) { $args[1] } else { $null }

if ([string]::IsNullOrWhiteSpace($resolvedAction) -or [string]::IsNullOrWhiteSpace($resolvedPackageName)) {
  Write-Host 'Usage: pax i <package>' -ForegroundColor Yellow
  exit 1
}

if ($resolvedAction -in @('i', 'install')) {
  try {
    Invoke-PaxInstall -Name $resolvedPackageName
    exit 0
  }
  catch {
    Write-Host "[!] Install failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
  }
}

Write-Host "Unknown action '$resolvedAction'. Use: pax i <package>" -ForegroundColor Yellow
exit 1
