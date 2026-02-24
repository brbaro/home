#!/usr/bin/env pwsh

param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [object[]] $Command
)

if (-not $Command -or $Command.Count -eq 0) {
  Start-Process powershell -Verb RunAs
  exit
}

$cmd = ($Command | ForEach-Object { "$_" }) -join ' '
$first = [string]$Command[0]
$resolved = $null
if ($first.EndsWith('.ps1')) {
  $resolved = Get-Command $first -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}
if (-not $resolved) {
  $resolved = if (Test-Path $first -PathType Leaf) { (Resolve-Path $first).Path } else { $null }
}

if ($resolved) {
  $argList = @($Command | Select-Object -Skip 1)
  Start-Process powershell `
    -Verb RunAs `
    -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-File', $resolved) + $argList
} else {
  Start-Process powershell `
    -Verb RunAs `
    -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $cmd)
}
