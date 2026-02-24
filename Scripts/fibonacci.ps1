param([string]$Range = "10")

if ($Range -match '(\d+)\.\.(\d+)') {
  $start = [int]$matches[1]
  $end = [int]$matches[2]
  $iterate = $true
} else {
  $start = [int]$Range
  $end = [int]$Range
  $iterate = $false
}

if ($start -gt $end) {
  Write-Host "Error: Start ($start) cannot be greater than end ($end)" -ForegroundColor Red
  exit 1
}

$a = [System.Numerics.BigInteger]::Zero
$b = [System.Numerics.BigInteger]::One

for ($i = 0; $i -le $end; $i++) {
  if ($i -ge $start -and ($iterate -or $i -eq $end)) {
    Write-Host ("Term {0}: {1}" -f $i, $a)
  }
  $temp = $a + $b
  $a = $b
  $b = $temp
}
