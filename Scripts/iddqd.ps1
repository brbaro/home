function Get-UserContext {
  param($Username)
  if ($Username.Contains("\")) { return $Username }
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
  $targetShell = "cmd /c cd /d %USERPROFILE% && powsh"

  if ($null -eq $Command -or $Command.Count -eq 0) {
    Write-Host "[!] Dropping into shell as ${targetUser}..." -ForegroundColor Cyan
    runas /savecred /user:$targetUser $targetShell
  } else {
    $fullCommand = $Command -join " "
    Write-Host "[!] Executing as ${targetUser}: $fullCommand" -ForegroundColor Green
    $execString = "cmd /c cd /d %USERPROFILE% && $fullCommand"
    runas /savecred /user:$targetUser $execString
  }
}

ElevatedExec @args
