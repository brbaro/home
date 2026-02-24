param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Mappings
)

function Show-Help {
  Write-Host "Usage:   remapkeys [orig:new] [orig2:new2] ..." -ForegroundColor Yellow
  Write-Host "Example: remapkeys 3a:1d (Caps to L-Ctrl) | remapkeys 5b:00 (Disable Win)" -ForegroundColor Gray
  Write-Host "`n--- MODIFIERS & SYSTEM ---          --- NAVIGATION ---"
  Write-Host "01: Esc          1c: Enter           48: Up          47: Home"
  Write-Host "3a: CapsLock     0e: Backspace       50: Down        4f: End"
  Write-Host "0f: Tab          39: Space           4b: Left        49: PgUp"
  Write-Host "2a: L-Shift      36: R-Shift         4d: Right       51: PgDn"
  Write-Host "1d: L-Ctrl       e01d: R-Ctrl        52: Insert      53: Delete"
  Write-Host "38: L-Alt        e038: R-Alt         5b: L-Win       5c: R-Win"
  Write-Host "`n--- ALPHA-NUMERIC ---"
  Write-Host "1e:A  1f:S  20:D  21:F  22:G  23:H  24:J  25:K  26:L"
  Write-Host "10:Q  11:W  12:E  13:R  14:T  15:Y  16:U  17:I  18:O  19:P"
  Write-Host "2c:Z  2d:X  2e:C  2f:V  30:B  31:N  32:M  33:,  34:.  35:/"
}

function Reset-KeyMap {
  Write-Host "[!] Resetting ScanCode Map..." -ForegroundColor Yellow
  wudo reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /f
}

function Format-ScanCode {
  param([string]$Hex)
  if ($Hex.StartsWith("e0")) {
    return [byte[]]([convert]::ToByte($Hex.Substring(2, 2), 16), 0xe0)
  }
  return [byte[]]([convert]::ToByte($Hex, 16), 0x00)
}

function Build-BinaryMap {
  param([string[]]$Pairs)

  $header = [byte[]](0,0,0,0, 0,0,0,0)
  $entryCount = [byte[]]($Pairs.Count + 1, 0, 0, 0)
  $nullTerminator = [byte[]](0,0,0,0)

  $body = New-Object System.Collections.Generic.List[byte]
  foreach ($pair in $Pairs) {
    $parts = $pair -split ':'
    $body.AddRange((Format-ScanCode $parts[1])) # New key
    $body.AddRange((Format-ScanCode $parts[0])) # Original key
  }

  return $header + $entryCount + $body.ToArray() + $nullTerminator
}

function Apply-KeyMap {
  if ($Mappings.Count -eq 0) {
    Show-Help
    return
  }

  if ($Mappings[0] -eq "reset") {
    Reset-KeyMap
    return
  }

  $binaryData = Build-BinaryMap -Pairs $Mappings
  $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"

  Write-Host "[!] Applying new Scancode Map..." -ForegroundColor Cyan
  wudo powershell -Command "Set-ItemProperty -Path '$registryPath' -Name 'Scancode Map' -Value ([byte[]]($($binaryData -join ','))) -Type Binary"

  Write-Host "[!] Applied. Restart required to feel the change." -ForegroundColor Green
}

Apply-KeyMap
