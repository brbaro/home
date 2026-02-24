#!/usr/bin/env pwsh

function Invoke-Git {
  $ProgramPath = Join-Path -Path $Env:LOCALAPPDATA -ChildPath "Pax\git\cmd\git.exe"
  if (Test-Path -Path $ProgramPath -PathType Leaf) {
    & $ProgramPath @args
  } else {
    Write-Error "Git not found at '$ProgramPath'."
  }
}

function Configure-Git {
  $gitConfig = [ordered]@{
    "core.autocrlf"         = "input"
    "core.editor"           = "vim"
    "alias.aa"              = "add -A"
    "alias.bare"            = "init --bare"
    "alias.br"              = "branch"
    "alias.ci"              = "commit"
    "alias.co"              = "checkout"
    "alias.dif"             = "diff --color-words"
    "alias.graph"           = "log --all --graph --decorate --oneline"
    "alias.pff"             = "push --force-with-lease --force-if-includes -u"
    "alias.pffff"           = "push --force -u"
    "alias.reb"             = "rebase"
    "alias.remo"            = "remote -v"
    "alias.rev"             = "rev-parse --abbrev-ref HEAD"
    "alias.sha"             = "rev-parse HEAD"
    "alias.shas"            = "reflog"
    "alias.st"              = "status --ignored"
    "alias.up"              = "pull --rebase"
    "color.ui"              = "always"
    "pull.ff"               = "only"
    "init.defaultBranch"    = "main"
    "rerere.enabled"        = "true"
  }

  $env:GIT_CONFIG_COUNT = $gitConfig.Count
  $i = 0
  foreach ($key in $gitConfig.Keys) {
    Set-Item -Path "env:GIT_CONFIG_KEY_$i"   -Value $key
    Set-Item -Path "env:GIT_CONFIG_VALUE_$i" -Value $gitConfig[$key]
    ++$i
  }
}

function Remove-LocalBranches {
  $Current = git branch --show-current
  $Branches = git branch --format="%(refname:short)" | Where-Object { $_ -ne $Current }
  if ($Branches) {
    Write-Host ($Branches -join "`n")
    $Confirmation = Read-Host "Remove these branches? [Y/n]"
    if ($Confirmation -eq "" -or $Confirmation -match "^[Yy]") {
      foreach ($Branch in $Branches) {
        git branch -D $Branch
      }
    } else {
      Write-Host "Aborted."
    }
  } else {
    Write-Host "No branches to remove"
  }
}

Configure-Git
if ($args.Count -eq 0) {
  Invoke-Git fetch
  Invoke-Git status
} elseif ($args[0] -eq "rmlo") {
  Remove-LocalBranches
} else {
  Invoke-Git @args
}
