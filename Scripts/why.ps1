#!/usr/bin/env pwsh

param(
  [string]$ModeOrCommand,
  [string]$CmdName
)

function Test-IsBinary {
  param($FilePath)

  try {
    $stream = [System.IO.File]::OpenRead($FilePath)
    try {
      $buffer = New-Object byte[] 1024
      $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
    }
    finally {
      $stream.Dispose()
    }
  }
  catch {
    return $false
  }

  if ($bytesRead -le 0) {
    return $false
  }

  return ($buffer[0..($bytesRead - 1)] -contains 0)
}

function Show-FileSource {
  param($FilePath)
  Write-Host "[File]: $FilePath" -ForegroundColor Cyan
  Write-Host ("-" * 60) -ForegroundColor Gray

  if (Test-IsBinary -FilePath $FilePath) {
    Write-Host "[Binary File] - Cannot display source." -ForegroundColor Gray
    return
  }

  Get-Content -Path $FilePath | ForEach-Object {
    if ($_ -match '^(rem|::|#|//)') {
      Write-Host $_ -ForegroundColor Green
    } elseif ($_ -match '\b(set|if|else|goto|call|exit|function|return|param|foreach|while|param)\b') {
      Write-Host $_ -ForegroundColor Yellow
    } else {
      Write-Host $_
    }
  }
}

function Resolve-CommandTarget {
  param([string]$CommandName)

  $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
  if (-not $cmd) { return $null }

  if ($cmd.CommandType -eq 'Alias') {
    $resolved = Get-Command $cmd.Definition -ErrorAction SilentlyContinue
    if ($resolved) {
      return $resolved
    }
  }

  return $cmd
}

function Resolve-CommandPath {
  param($CommandInfo)

  if (-not $CommandInfo) { return $null }

  if ($CommandInfo.CommandType -eq 'Function' -and $CommandInfo.ScriptBlock.File) {
    return $CommandInfo.ScriptBlock.File
  }

  if ($CommandInfo.Path) {
    return $CommandInfo.Path
  }

  if ($CommandInfo.Definition -and (Test-Path $CommandInfo.Definition -PathType Leaf)) {
    return $CommandInfo.Definition
  }

  return $null
}

function Invoke-Why {
  $PathOnly = $ModeOrCommand -eq 'path'
  $TargetCommand = if ($PathOnly) { $CmdName } else { $ModeOrCommand }

  if ([string]::IsNullOrWhiteSpace($TargetCommand)) {
    Write-Host "Usage: why [path] [command_name]" -ForegroundColor Yellow
    return
  }

  $cmd = Get-Command $TargetCommand -ErrorAction SilentlyContinue

  if (-not $cmd) {
    Write-Host "[!] Could not find definition for: $TargetCommand" -ForegroundColor Red
    return
  }

  $resolvedCmd = Resolve-CommandTarget -CommandName $TargetCommand
  $path = Resolve-CommandPath -CommandInfo $resolvedCmd

  if ($PathOnly) {
    if ($path) {
      Write-Output $path
      return
    }

    Write-Host "[!] Found $TargetCommand but could not resolve a file path." -ForegroundColor Red
    return
  }

  if ($cmd.CommandType -eq 'Alias') {
    Write-Host "[Alias]: $($cmd.Definition)" -ForegroundColor Cyan
    return
  }

  if ($cmd.CommandType -eq 'Function') {
    Write-Host "[Function]:" -ForegroundColor Cyan
    Write-Host $cmd.ScriptBlock
    return
  }

  if ($path -and (Test-Path $path -PathType Leaf)) {
    Show-FileSource -FilePath $path
    return
  }

  Write-Host "[!] Found $TargetCommand but could not resolve a file path." -ForegroundColor Red
}

Invoke-Why
