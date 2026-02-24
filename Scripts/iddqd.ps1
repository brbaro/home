#!/usr/bin/env pwsh

function Get-UserContext {
  param($Username)
  if ($Username.Contains("\")) { return $Username }
  return "$env:COMPUTERNAME\$Username"
}

function Get-BaseUsername {
  param([string]$Username)
  if ([string]::IsNullOrWhiteSpace($Username)) { return "" }
  $parts = $Username -split "\\"
  return $parts[-1].ToLowerInvariant()
}

function Test-SaveCredAllowedUser {
  param([string]$Username)

  $target = Get-BaseUsername -Username $Username
  if ([string]::IsNullOrWhiteSpace($target)) { return $false }

  $allow = @("riot", "epic", "steam")

  if (-not [string]::IsNullOrWhiteSpace($env:IDDQD)) {
    $allow += ($env:IDDQD -split "\s+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Get-BaseUsername $_ })
  }

  return $allow -contains $target
}

function ElevatedExec {
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    $Username,
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    $Command
  )

  $targetUser = Get-UserContext -Username $Username
  $targetShell = "cmd /c cd /d %USERPROFILE% && powsh || powershell"
  $useSaveCred = Test-SaveCredAllowedUser -Username $targetUser
  $runAsArgs = @()
  if ($useSaveCred) {
    $runAsArgs += "/savecred"
    $mode = "enabled"
  } else {
    $mode = "disabled"
  }
  $runAsArgs += "/user:$targetUser"

  if ($null -eq $Command -or $Command.Count -eq 0) {
    Write-Host "[!] Dropping into shell as ${targetUser}..." -ForegroundColor Cyan
    Write-Host "[!] /savecred: $mode" -ForegroundColor DarkCyan
    runas @runAsArgs $targetShell
  } else {
    $fullCommand = $Command -join " "
    Write-Host "[!] Executing as ${targetUser}: $fullCommand" -ForegroundColor Green
    Write-Host "[!] /savecred: $mode" -ForegroundColor DarkGreen
    $execString = "cmd /c cd /d %USERPROFILE% && $fullCommand"
    runas @runAsArgs $execString
  }
}

if ($args[0] -eq '-') {
  $args = $args[1..($args.Length - 1)]
}

ElevatedExec @args
