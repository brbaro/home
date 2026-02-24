$subPath = "Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
$roots = @(
  "C:\Users\epic",
  $env:ProgramFiles,
  ${env:ProgramFiles(x86)}
)

$clientPath = $null
foreach ($root in $roots) {
  $fullPath = Join-Path $root $subPath
  if (Test-Path $fullPath) {
    $clientPath = $fullPath
    break
  }
}

if (!$clientPath) {
  Write-Host "[!] Epic Games Launcher not found in any known root." -ForegroundColor Red
  exit
}

switch ($args[0]) {
  "fn" {
    Write-Host "[+] Launching Fortnite..." -ForegroundColor Cyan
    Start-Process $clientPath "-com.epicgames.launcher://apps/Fortnite?action=launch&silent=true"
  }
  default {
    Write-Host "[+] Opening Epic Games Launcher..." -ForegroundColor Green
    Start-Process $clientPath
  }
}
