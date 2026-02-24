param(
    [Parameter(Position=0)]
    [string]$TargetFolder
)

if ([string]::IsNullOrWhiteSpace($TargetFolder)) {
    Write-Host "Usage: include [folder_path]" -ForegroundColor Yellow
    exit 1
}

# Resolve to absolute path to avoid ambiguity
$fullPath = Resolve-Path $TargetFolder -ErrorAction SilentlyContinue
if (!$fullPath) {
    Write-Host "[!] Error: Folder '$TargetFolder' does not exist." -ForegroundColor Red
    exit 1
}
$target = $fullPath.Path

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$combinedPath = ($userPath + ";" + $machinePath) -split ';' | Where-Object { $_ }

if ($combinedPath -contains $target) {
    Write-Host "[!] Information: '$target' is already in your PATH." -ForegroundColor Cyan
    exit 0
}

Write-Host "[?] Found new directory: $target" -ForegroundColor Gray
$confirm = Read-Host "Add this to your User PATH? (y/n)"

if ($confirm -ne "y") {
    Write-Host "[!] Action cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "[+] Updating User PATH..." -ForegroundColor Cyan
try {
    # Ensure we don't end up with double semi-colons
    $newPath = if ($userPath -match ';$| ^$') { $userPath + $target } else { $userPath + ";" + $target }

    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "[!] Success! Please restart your terminal to apply changes." -ForegroundColor Green
} catch {
    Write-Host "[!] Error: Failed to update environment variables." -ForegroundColor Red
    exit 1
}
