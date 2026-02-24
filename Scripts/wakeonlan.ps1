param([string]$MacAddress)

if ($null -eq $MacAddress) { exit 1 }

$bytes = $MacAddress -split '[:-]' | ForEach-Object {
  try { [byte]('0x' + $_) } catch { $null }
}

if ($bytes.Count -ne 6) {
  Write-Host "Error: Invalid MAC address format ($MacAddress)" -ForegroundColor Red
  exit 1
}

$packet = [byte[]](,0xFF * 6) + ($bytes * 16)
$client = New-Object System.Net.Sockets.UdpClient

try {
  $client.Connect([System.Net.IPAddress]::Broadcast, 9)
  $client.Send($packet, $packet.Length) | Out-Null
  Write-Host "[+] Magic Packet transmitted to $MacAddress via Port 9" -ForegroundColor Green
} catch {
  Write-Host "[!] Transmission failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
  $client.Close()
}
