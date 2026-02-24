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

function Get-CS2CfgDirectory {
  param($SteamHome)
  $relativeCfgPath = "steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
  return Join-Path $SteamHome $relativeCfgPath
}

function Download-Config {
  param($Url, $Destination)
  try {
    Write-Host "[+] Downloading $(Split-Path $Destination -Leaf)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
  } catch {
    Write-Host "[!] Failed to download from $Url" -ForegroundColor Red
  }
}

function Sync-CS2Configs {
  $steamHome = Get-SteamHome
  $cs2CfgDir = Get-CS2CfgDirectory -SteamHome $steamHome

  Write-Host "[+] Steam Home detected at: $steamHome" -ForegroundColor Gray
  Write-Host "[+] Target Cfg: $cs2CfgDir" -ForegroundColor Cyan

  if (!(Test-Path $cs2CfgDir)) {
    Write-Host "[!] Error: CS2 Config directory not found. Is CS2 installed?" -ForegroundColor Red
    return
  }

  Download-Config `
    -Url "https://raw.githubusercontent.com/trnqilo/home/refs/heads/lib/play/Source2/cs2.cfg" `
    -Destination (Join-Path $cs2CfgDir "autoexec.cfg")

  Write-Host "[+] Bárbaro! 🚀" -ForegroundColor Green
}

Sync-CS2Configs
