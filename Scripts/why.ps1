param([string]$CmdName)

function Test-IsBinary {
  param($FilePath)
  $bytes = Get-Content -Path $FilePath -Encoding Byte -TotalCount 1024 -ErrorAction SilentlyContinue
  return $bytes -contains 0
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

function Invoke-Why {
  if ([string]::IsNullOrWhiteSpace($CmdName)) {
    Write-Host "Usage: why [command_name]" -ForegroundColor Yellow
    return
  }

  $cmd = Get-Command $CmdName -ErrorAction SilentlyContinue

  if (-not $cmd) {
    Write-Host "[!] Could not find definition for: $CmdName" -ForegroundColor Red
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

  $path = if ($cmd.Path) { $cmd.Path } else { $cmd.Definition }

  if ($path -and (Test-Path $path -PathType Leaf)) {
    Show-FileSource -FilePath $path
    return
  }

  Write-Host "[!] Found $CmdName but could not resolve a file path." -ForegroundColor Red
}

Invoke-Why
