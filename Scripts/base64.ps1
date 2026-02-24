param([string]$InputString)

if (-not $InputString) {
  $InputString = $input | Out-String
}

if ([string]::IsNullOrWhiteSpace($InputString)) {
  Write-Host "Usage: base64 [string] or type [file] | base64" -ForegroundColor Yellow
  exit 1
}

$bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString.Trim())
[Convert]::ToBase64String($bytes)
