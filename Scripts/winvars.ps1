param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RawArgs
)

function Show-NativeEnvironmentUI {
  Write-Host "[+] Launching Windows Environment Variables UI..." -ForegroundColor Cyan
  Start-Process "control.exe" -ArgumentList "sysdm.cpl,,3"
}

function Show-WinVarHelp {
  Write-Host "Usage: winvars [name] [value] | [name]=[value] | [name] = [value]" -ForegroundColor Yellow
  Write-Host "Flags:" -ForegroundColor Gray
  Write-Host "  (empty)  - Opens the native Windows Environment Variables UI" -ForegroundColor Gray
  Write-Host "  -? / help - Shows this help message" -ForegroundColor Gray
}

function Parse-EnvironmentInput {
  param([string[]]$InputArgs)

  if ($InputArgs.Count -eq 0) { return $null }

  $first = $InputArgs[0]

  if ($first -match "=") {
    $parts = $first -split "=", 2
    $name = $parts[0]
    $value = if ($parts[1]) { $parts[1] } else { ($InputArgs[1..($InputArgs.Count-1)] -join " ") }
    return @{ Name = $name; Value = $value.Trim() }
  }

  if ($InputArgs.Count -gt 2 -and $InputArgs[1] -eq "=") {
    return @{ Name = $first; Value = ($InputArgs[2..($InputArgs.Count-1)] -join " ").Trim() }
  }

  return @{
    Name = $first;
    Value = ($InputArgs[1..($InputArgs.Count-1)] -join " ").Trim()
  }
}

function Invoke-WinVar {
  if ($RawArgs.Count -eq 0) {
    Show-NativeEnvironmentUI
    return
  }

  if ($RawArgs[0] -eq "-?" -or $RawArgs[0] -eq "help") {
    Show-WinVarHelp
    return
  }

  $parsed = Parse-EnvironmentInput -InputArgs $RawArgs

  if ($null -eq $parsed -or [string]::IsNullOrEmpty($parsed.Value)) {
    Write-Host "[!] Error: No value provided for variable '$($RawArgs[0])'." -ForegroundColor Red
    Show-WinVarHelp
    return
  }

  $name = $parsed.Name
  $value = $parsed.Value
  $current = [Environment]::GetEnvironmentVariable($name, "User")

  if ($null -eq $current -or $current -eq "") {
    [Environment]::SetEnvironmentVariable($name, $value, "User")
    Write-Host "[+] Set ${name}=${value}" -ForegroundColor Green
  } else {
    Write-Host "[!] $name is already set to: $current" -ForegroundColor Cyan
    $choice = Read-Host "Overwrite with '${value}'? (y/N)"
    if ($choice -eq "y") {
      [Environment]::SetEnvironmentVariable($name, $value, "User")
      Write-Host "[*] Updated ${name}=${value}" -ForegroundColor Green
    } else {
      Write-Host "[.] Operation cancelled." -ForegroundColor Gray
    }
  }

  Write-Host "`n[!] Restart your shell to activate changes." -ForegroundColor Yellow
}

Invoke-WinVar
