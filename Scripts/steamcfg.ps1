#!/usr/bin/env pwsh

param(
  [Parameter(Mandatory = $false, Position = 0)]
  [ValidateSet('cs2', 'apex', 'cstrike', 'tf2', 'portal', 'portal2', 'insurgency2', 'l4d2')]
  [string]$Game
)

function Get-SteamHome {
  if ($env:STEAM_HOME) {
    return $env:STEAM_HOME
  }

  $customPath = "C:\Users\steam\steam"
  if (Test-Path $customPath) {
    return $customPath
  }

  $registryPath = "HKCU:\Software\Valve\Steam"
  $regPath = Get-ItemPropertyValue -Path $registryPath -Name "SteamPath" -ErrorAction SilentlyContinue
  if ($regPath) {
    return $regPath
  }

  return "$env:ProgramFiles\Steam"
}

function Download-Config {
  param($Url, $Destination)
  try {
    Write-Host "[+] Downloading $(Split-Path $Destination -Leaf)..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
  } catch {
    Write-Host "[!] Failed to download from $Url" -ForegroundColor Red
  }
}

function Get-GameConfigPathMap {
  return @{
    'cs2'         = 'steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg'
    'apex'        = 'steamapps\common\Apex Legends\cfg'
    'cstrike'     = 'steamapps\common\Counter-Strike Source\cstrike\cfg'
    'tf2'         = 'steamapps\common\Team Fortress 2\tf\cfg'
    'portal'      = 'steamapps\common\Portal\portal\cfg'
    'portal2'     = 'steamapps\common\Portal 2\portal2\cfg'
    'insurgency2' = 'steamapps\common\insurgency2\insurgency\cfg'
    'l4d2'        = 'steamapps\common\Left 4 Dead 2\left4dead2\cfg'
  }
}

function Get-GameUrlMap {
  $baseUrl = "https://raw.githubusercontent.com/trnqilo/home/refs/heads/lib/play"
  return @{
    'cs2'         = "$baseUrl/Source2/cs2.cfg"
    'apex'        = "$baseUrl/Source/apex.cfg"
    'cstrike'     = "$baseUrl/Source/cstrike.cfg"
    'tf2'         = "$baseUrl/Source/tf2.cfg"
    'portal'      = "$baseUrl/Source/portal.cfg"
    'portal2'     = "$baseUrl/Source/portal2.cfg"
    'insurgency2' = "$baseUrl/Source/insurgency2.cfg"
    'l4d2'        = "$baseUrl/Source/l4d2.cfg"
  }
}

function Get-GameDirectory {
  param($SteamHome, $GameKey)
  $pathMap = Get-GameConfigPathMap
  return Join-Path $SteamHome $pathMap[$GameKey]
}

function Get-ConfigDownloadUrl {
  param($GameKey)
  $urlMap = Get-GameUrlMap
  return $urlMap[$GameKey]
}

function Ensure-DirectoryExists {
  param($Path)
  if (!(Test-Path $Path)) {
    Write-Host "[+] Creating missing path: $Path" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Sync-SingleGameConfig {
  param($SteamHome, $GameKey)
  $cfgDir = Get-GameDirectory -SteamHome $SteamHome -GameKey $GameKey
  $downloadUrl = Get-ConfigDownloadUrl -GameKey $GameKey

  Write-Host "[+] Target Cfg [$GameKey]: $cfgDir" -ForegroundColor Cyan
  Ensure-DirectoryExists -Path $cfgDir

  Download-Config -Url $downloadUrl -Destination (Join-Path $cfgDir "autoexec.cfg")
}

function Sync-AllGameConfigs {
  param($TargetGame)
  $steamHome = Get-SteamHome
  Write-Host "[+] Steam Home detected at: $steamHome" -ForegroundColor Gray

  if ($TargetGame) {
    Sync-SingleGameConfig -SteamHome $steamHome -GameKey $TargetGame
  } else {
    $gameMap = Get-GameConfigPathMap
    foreach ($gameKey in $gameMap.Keys) {
      Sync-SingleGameConfig -SteamHome $steamHome -GameKey $gameKey
    }
  }

  Write-Host "[+] Bárbaro!" -ForegroundColor Green
}

Sync-AllGameConfigs -TargetGame $Game
