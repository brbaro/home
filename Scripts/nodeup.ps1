param(
  [Parameter(Mandatory=$true)]
  [string]$Version
)

if (!$Version.StartsWith("v")) { $Version = "v$Version" }

$arch = "x64"
$scriptsDir = "$HOME\Scripts"
$nodeDir = "$scriptsDir\node-$Version"
$zipFile = "$env:TEMP\node-$Version.zip"
$tempExtract = "$scriptsDir\temp-node"
$url = "https://nodejs.org/dist/$Version/node-$Version-win-$arch.zip"

Write-Host "[+] Fetching Node.js $Version from official mirrors..." -ForegroundColor Cyan

try {
  Invoke-WebRequest -Uri $url -OutFile $zipFile -ErrorAction Stop
} catch {
  Write-Host "[!] Failed to download Node.js. Is version '$Version' correct?" -ForegroundColor Red
  exit 1
}

if (!(Test-Path $nodeDir)) { New-Item -ItemType Directory -Path $nodeDir -Force | Out-Null }

Write-Host "[+] Extracting to $nodeDir..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $tempExtract -Force

# The zip contains a subfolder named 'node-vXX.XX.X-win-x64'
$innerFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
Move-Item -Path "$($innerFolder.FullName)\*" -Destination $nodeDir -Force

Write-Host "[+] Cleaning up..." -ForegroundColor Gray
Remove-Item $zipFile -Force
Remove-Item $tempExtract -Recurse -Force

Write-Host "`n[+] Node.js $Version is now available at: $nodeDir" -ForegroundColor Green
Write-Host "[!] To activate, add this to your PATH or use it directly:" -ForegroundColor White
Write-Host "    $nodeDir\node.exe -v" -ForegroundColor Gray

# Optional: Suggest the setenv command we made earlier!
Write-Host "`n[?] Use 'setenv PATH ""%PATH%;$nodeDir""' to persist." -ForegroundColor DarkGray
