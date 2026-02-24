#!/usr/bin/env pwsh

param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ScriptArgs
)

function Get-CacheDirectoryPath {
  $homePath = [Environment]::GetFolderPath('UserProfile')
  $cacheDir = Join-Path $homePath ".irmcache"

  if (-not (Test-Path $cacheDir)) {
    $null = New-Item -ItemType Directory -Path $cacheDir -Force
    $dirInfo = Get-Item -Path $cacheDir -Force
    $dirInfo.Attributes = $dirInfo.Attributes -bor [System.IO.FileAttributes]::Hidden
  }

  return $cacheDir
}

function Get-UrlSha256Hash {
  param([string]$InputUrl)

  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputUrl)
  $hashBytes = $sha256.ComputeHash($bytes)

  return -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
}

function Convert-TimeToTimeSpan {
  param([string]$TimeSpanString)

  if ($TimeSpanString -match '^(\d+)([smhd])$') {
    $amount = [int]$Matches[1]
    $unit = $Matches[2]

    switch ($unit) {
      's' { return [TimeSpan]::FromSeconds($amount) }
      'm' { return [TimeSpan]::FromMinutes($amount) }
      'h' { return [TimeSpan]::FromHours($amount) }
      'd' { return [TimeSpan]::FromDays($amount) }
    }
  }

  throw "Invalid time format '$TimeSpanString'. Use units like 30s, 10m, 2h, or 1d."
}

function Get-CacheFilePath {
  param([string]$TargetUrl)

  $uri = [System.Uri]$TargetUrl
  $baseCacheDir = Get-CacheDirectoryPath
  $hostPath = $uri.Host
  $localPath = $uri.AbsolutePath.TrimStart('/')

  $urlHash = Get-UrlSha256Hash -InputUrl $TargetUrl
  $fileName = "_{0}_" -f $urlHash

  $targetDirectory = Join-Path $baseCacheDir (Join-Path $hostPath $localPath)
  if (-not (Test-Path $targetDirectory)) {
    $null = New-Item -ItemType Directory -Path $targetDirectory -Force
  }

  return Join-Path $targetDirectory $fileName
}

function Invoke-CachedRestMethod {
  $url = $null
  $ttl = [TimeSpan]::MaxValue

  if ($ScriptArgs.Count -eq 0) {
    throw "Please provide a target URL."
  }

  if ($ScriptArgs[0] -eq "for") {
    if ($ScriptArgs.Count -lt 3) {
      throw "Usage: irmcache for <time> <url>"
    }
    $ttl = Convert-TimeToTimeSpan -TimeSpanString $ScriptArgs[1]
    $url = $ScriptArgs[2]
  } else {
    $url = $ScriptArgs[0]
  }

  $cacheFilePath = Get-CacheFilePath -TargetUrl $url

  if (Test-Path $cacheFilePath) {
    $lastWriteTime = (Get-Item $cacheFilePath).LastWriteTime
    if ((Get-Date) - $lastWriteTime -lt $ttl) {
      return Get-Content -Path $cacheFilePath -Raw
    }
  }

  $response = Invoke-RestMethod -Uri $url -UseBasicParsing
  $responseText = if ($response -is [string]) { $response } else { $response | ConvertTo-Json -Depth 10 }

  Set-Content -Path $cacheFilePath -Value $responseText -Encoding UTF8
  return $responseText
}

Invoke-CachedRestMethod
