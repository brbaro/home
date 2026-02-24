$clientPath = "C:\Users\riot\Riot Games\Riot Client\RiotClientServices.exe"

if (!(Test-Path $clientPath)) {
  Write-Host "[!] Riot Client not found at: $clientPath" -ForegroundColor Red
  exit
}

switch ($args[0]) {
  "val" {
    Write-Host "[+] Launching Valorant..." -ForegroundColor Cyan
    Start-Process -FilePath $clientPath -ArgumentList "--launch-product=valorant", "--launch-patchline=live"
  }
  default {
    Write-Host "[+] Opening Riot Launcher..." -ForegroundColor Green
    Start-Process -FilePath $clientPath
  }
}

# TODO: VALORANT audio fix -> Set-Service -Name "BTAGService" -StartupType Disabled -Status Stopped
