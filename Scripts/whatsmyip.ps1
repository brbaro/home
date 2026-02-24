try {
  $wan = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5).Trim()
  Write-Host "  WAN: " -NoNewline -ForegroundColor Cyan
  Write-Host $wan
} catch {
  Write-Host "  [!] WAN: Offline or Request Timed Out" -ForegroundColor Red
}

$lan = Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.InterfaceAlias -notmatch 'Loopback|Virtual' } |
       Select-Object -ExpandProperty IPAddress

foreach ($ip in $lan) {
  Write-Host "  LAN: " -NoNewline -ForegroundColor Gray
  Write-Host $ip
}
