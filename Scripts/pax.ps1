param(
  [string]$Action,
  [string]$Target
)

function Get-PaxBaseUrl {
  $url = if ($env:PAX_URL) { $env:PAX_URL.TrimEnd('/') } else { "brbaro.web.app/pax" }

  if ($url -notmatch "^[a-z]+://") {
    $url = "https://$url"
  }
  return $url
}

function Get-CachePaths {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $Home "Scripts" }
  $cacheDir = Join-Path $scriptDir "Cache"
  return @{
    Root = $cacheDir
  }
}

function Verify-PackageHash {
  param($ZipPath, $PackageName)
  $baseUrl = Get-PaxBaseUrl
  $manifestUrl = "$baseUrl/.shas"

  try {
    Write-Host "[*] Verifying hash for $PackageName..." -ForegroundColor Gray
    $manifest = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing -ErrorAction Stop
    $lines = $manifest.Content -split "`n" | Where-Object { $_ -match $PackageName }

    if (!$lines) {
      Write-Host "[!] Warning: No hash found in manifest for $PackageName" -ForegroundColor Yellow
      return $true
    }

    $expectedHash = ($lines[0] -split "\s+")[0].Trim()
    $actualHash = sha256sum $ZipPath

    if ($actualHash -eq $expectedHash) {
      Write-Host "[+] Hash verified: Match!" -ForegroundColor Green
      return $true
    } else {
      Write-Host "[!] HASH MISMATCH!" -ForegroundColor Red
      return $false
    }
  } catch {
    Write-Host "[!] Could not fetch manifest for verification." -ForegroundColor Yellow
    return $true
  }
}

function Invoke-GenericInstaller {
  param($FilePath)
  $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
  Write-Host "[+] Processing: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green

  switch ($extension) {
    ".msi" {
      Start-Process msiexec.exe -ArgumentList "/i `"$FilePath`" /passive" -Wait
    }
    ".exe" {
      Start-Process $FilePath -Wait
    }
    ".zip" {
      $dest = Join-Path $env:LocalAppData "Programs\$(Split-Path $FilePath -LeafBase)"
      if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
      Expand-Archive -Path $FilePath -DestinationPath $dest -Force
    }
  }
}

function Install-Package {
  param($Name, $ForceUpdate)

  if ([string]::IsNullOrEmpty($Name)) {
    Write-Host "[!] Specify a package name." -ForegroundColor Red
    return
  }

  $paths = Get-CachePaths
  $packageDir = Join-Path $paths.Root $Name
  $zipPath = Join-Path $packageDir "$Name.zip"
  $baseUrl = Get-PaxBaseUrl
  $url = "$baseUrl/$Name"

  if (!(Test-Path $packageDir)) {
    New-Item -Path $packageDir -ItemType Directory -Force | Out-Null
  }

  if ($ForceUpdate -or !(Test-Path $zipPath)) {
    Write-Host "[+] Fetching $Name from $url..." -ForegroundColor Cyan
    try {
      Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    } catch {
      Write-Host "[!] Failed to fetch $Name from $url" -ForegroundColor Red
      return
    }

    if (!(Verify-PackageHash -ZipPath $zipPath -PackageName $Name)) {
      Remove-Item $zipPath -Force
      return
    }

    Write-Host "[+] Extracting $Name payload..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $packageDir -Force
  }

  $payload = Get-ChildItem -Path $packageDir -Include *.exe, *.msi, *.zip -Recurse |
    Where-Object { $_.Name -ne "$Name.zip" } |
    Select-Object -First 1

  if ($payload) {
    Invoke-GenericInstaller -FilePath $payload.FullName
  } else {
    Write-Host "[!] No installer found inside $Name" -ForegroundColor Red
  }
}

function Manage-Packages {
  $isUpdate = $Action -eq "update"
  $isInstall = $Action -match "^(i|install)$"

  if ($isUpdate -or $isInstall) {
    Install-Package -Name $Target -ForceUpdate $isUpdate
    Write-Host "`nBárbaro! 🚀" -ForegroundColor Green
    return
  }

  Write-Host "Usage: pax [install|i|update] [name]" -ForegroundColor Yellow
}

Manage-Packages
