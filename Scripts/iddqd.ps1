function Get-UserContext {
  param($Username)
  if ($Username.Contains("\")) {
    return $Username
  }
  return "$env:COMPUTERNAME\$Username"
}

function ElevatedExec {
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    $Username,
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    $Command
  )

  $targetUser = Get-UserContext -Username $Username
  $profilePath = "C:\Users\$Username"

  if ($null -eq $Command) {
    Write-Host "[!] Dropping into shell as ${targetUser}..." -ForegroundColor Cyan
    $launchArgs = "/c cd /d $profilePath && powsh"

    try {
      Start-Process -FilePath "cmd.exe" -ArgumentList $launchArgs -Credential $targetUser -ErrorAction Stop
    } catch {
      Write-Host "[*] Elevation fallback: Using runas /savecred..." -ForegroundColor Yellow
      runas /savecred /user:$targetUser "cmd /c cd /d %USERPROFILE% && powsh"
    }
  } else {
    $fullCommand = $Command -join " "
    Write-Host "[!] Executing as ${targetUser}: $fullCommand" -ForegroundColor Green
    runas /savecred /user:$targetUser "cmd /c cd /d %USERPROFILE% && $fullCommand"
  }
}

ElevatedExec @args
