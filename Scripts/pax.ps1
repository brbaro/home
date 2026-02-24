param(
  [string]$Action,
  [string]$Target
)

function Get-PaxBaseUrl {
  $url = if ($env:PAX_URL) { $env:PAX_URL.TrimEnd('/') } else { "brbaro.web.app/pax" }
  if ($url -notmatch "^[a-z]+://") { $url = "https://$url" }
  return $url
}

function Get-CachePaths {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $Home "Scripts" }
  return @{
    Root  = Join-Path $scriptDir "Cache"
    Local = Join-Path $scriptDir "Local"
  }
}

function Update-UserEnvironmentPath {
  param($FolderToAdd)
  $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($currentPath -notmatch [regex]::Escape($FolderToAdd)) {
    $updatedPath = "$currentPath;$FolderToAdd"
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
    $env:Path = "$env:Path;$FolderToAdd"
    Write-Host "[+] PATH Updated: $FolderToAdd" -ForegroundColor Cyan
  }
}

function Assert-PackageHash {
  param($ZipPath, $PackageName)
  $buster = Get-Random
  $baseUrl = Get-PaxBaseUrl
  $manifestUrl = "$baseUrl/.shas?cb=$buster"
  try {
    $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing -ErrorAction Stop
    $lines = $manifest -split "`n" | Where-Object { $_ -match $PackageName }
    if (!$lines) { return $true }
    $expectedHash = ($lines[0] -split "\s+")[0].Trim()
    $actualHash = sha256sum $ZipPath
    return $actualHash -eq $expectedHash
  } catch { return $true }
}

function Run-StandaloneInstaller {
  param($FilePath)
  $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
  Write-Host "[+] Launching Installer: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
  switch ($extension) {
    ".msi" { Start-Process msiexec.exe -ArgumentList "/i `"$FilePath`" /passive" -Wait }
    ".exe" { Start-Process $FilePath -Wait }
  }
}

function Deploy-PortableFolder {
  param($SourceFolder, $DestinationBase, $PackageName)
  $finalTarget = Join-Path $DestinationBase $PackageName

  if (Test-Path $finalTarget) {
    Remove-Item $finalTarget -Recurse -Force
  }

  if (!(Test-Path $DestinationBase)) {
    New-Item $DestinationBase -ItemType Directory -Force | Out-Null
  }

  Move-Item -Path $SourceFolder -Destination $finalTarget -Force
  Update-UserEnvironmentPath -FolderToAdd $finalTarget
}

function Process-ExtractedPayload {
  param($ExtractionDir, $LocalBase, $PackageName)

  $actualItems = Get-ChildItem -Path $ExtractionDir | Where-Object { $_.Name -notmatch "\.zip$" }

  if ($actualItems.Count -ne 1) {
    Write-Host "[!] ZIP structure invalid. Expected 1 item, found $($actualItems.Count)." -ForegroundColor Red
    return
  }

  $item = $actualItems[0]

  if ($item.PSIsContainer) {
    Deploy-PortableFolder -SourceFolder $item.FullName -DestinationBase $LocalBase -PackageName $PackageName
  } else {
    Run-StandaloneInstaller -FilePath $item.FullName
  }
}

function Fetch-PackageZip {
  param($Url, $OutPath, $PackageDir)
  if (!(Test-Path $PackageDir)) {
    New-Item $PackageDir -ItemType Directory -Force | Out-Null
  }

  Write-Host "[+] Fetching: $Url" -ForegroundColor Cyan
  Invoke-RestMethod -Uri $Url -OutFile $OutPath -UseBasicParsing -ErrorAction Stop
}

function Install-Package {
  param($Name, $ForceUpdate)

  if ([string]::IsNullOrEmpty($Name)) {
    Write-Host "[!] Package name required." -ForegroundColor Red
    return
  }

  $paths = Get-CachePaths
  $packageDir = Join-Path $paths.Root $Name
  $zipPath = Join-Path $packageDir "$Name.zip"
  $downloadUrl = "$(Get-PaxBaseUrl)/$Name?cb=$(Get-Random)"

  if ($ForceUpdate -or !(Test-Path $zipPath)) {
    try {
      Fetch-PackageZip -Url $downloadUrl -OutPath $zipPath -PackageDir $packageDir
      if (!(Assert-PackageHash -ZipPath $zipPath -PackageName $Name)) {
        Write-Host "[!] Hash Mismatch. Aborting." -ForegroundColor Red
        Remove-Item $packageDir -Recurse -Force
        return
      }
    } catch {
      Write-Host "[!] Network Error." -ForegroundColor Red
      if (Test-Path $packageDir) { Remove-Item $packageDir -Recurse -Force }
      return
    }
  }

  Write-Host "[+] Extracting Payload..." -ForegroundColor Yellow
  $tempExtractPath = Join-Path $packageDir "extract_temp"
  if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
  New-Item $tempExtractPath -ItemType Directory -Force | Out-Null

  Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force

  Process-ExtractedPayload -ExtractionDir $tempExtractPath -LocalBase $paths.Local -PackageName $Name

  Remove-Item $tempExtractPath -Recurse -Force
}

function Manage-Packages {
  $isUpdate = $Action -eq "update"
  $isInstall = $Action -match "^(i|install)$"
  if ($isUpdate -or $isInstall) {
    Install-Package -Name $Target -ForceUpdate $isUpdate
    Write-Host "`nBárbaro! 🚀" -ForegroundColor Green
  } else {
    Write-Host "Usage: pax [i|install|update] [name]" -ForegroundColor Yellow
  }
}

Manage-Packages
