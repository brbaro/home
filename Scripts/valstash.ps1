param (
  [string]$ActionOrPrefix,
  [string]$PopPrefix
)

function Get-LocalAppDataPath {
  return "$env:LOCALAPPDATA"
}

function Assert-ArgsProvided {
  param ($Argument, $ErrorMessage)

  if ([string]::IsNullOrWhiteSpace($Argument)) {
    Write-Error $ErrorMessage
    exit 1
  }
}

function Assert-SafePrefix {
  param ([string]$Prefix)

  if ([string]::IsNullOrWhiteSpace($Prefix) -or $Prefix -eq "pop") {
    Write-Error "Invalid prefix."
    exit 1
  }

  if ($Prefix -match '[\\/:*?"<>|]') {
    Write-Error "Prefix contains invalid path characters."
    exit 1
  }
}

function Stop-RiotProcesses {
  $Patterns = @("VALORANT*", "RiotClient*", "vgtray*")

  Get-Process -ErrorAction SilentlyContinue |
    Where-Object {
      $Name = $_.ProcessName
      $Patterns | Where-Object { $Name -like $_ }
    } |
    Stop-Process -Force -ErrorAction SilentlyContinue
}

function Stop-VgcService {
  $Service = Get-Service -Name "vgc" -ErrorAction SilentlyContinue

  if ($Service -and $Service.Status -ne "Stopped") {
    Stop-Service -Name "vgc" -Force -ErrorAction SilentlyContinue
  }
}

function Ensure-ProcessesAreDead {
  Stop-RiotProcesses
  Stop-VgcService
  Start-Sleep -Seconds 1
}

function Assert-DirectoryDoesNotExist {
  param ($Path)

  if (Test-Path -Path $Path) {
    Write-Error "Error: Destination directory '$Path' already exists. Operation aborted."
    exit 1
  }
}

function Confirm-UserDeletion {
  param ($Path)

  if (Test-Path -Path $Path) {
    Write-Warning "Target directory '$Path' already exists and will be deleted!"
    $Choice = Read-Host "Are you sure you want to continue? (yes/no)"

    if ($Choice -notmatch "^(yes|y)$") {
      Write-Output "Operation cancelled by user."
      exit 0
    }

    Remove-Item -Path $Path -Recurse -Force
  }
}

function Move-Directory {
  param ($Source, $Destination)

  if (Test-Path -Path $Source) {
    Move-Item -Path $Source -Destination $Destination -Force
    Write-Output "Successfully moved '$Source' to '$Destination'."
  } else {
    Write-Warning "Source directory '$Source' does not exist. Skipping."
  }
}

function Execute-BackupMode {
  param ($Prefix)

  Assert-SafePrefix -Prefix $Prefix
  Ensure-ProcessesAreDead

  $AppData = Get-LocalAppDataPath

  $SrcRiot = Join-Path $AppData "Riot Games"
  $SrcVal  = Join-Path $AppData "VALORANT"

  $DestRiot = Join-Path $AppData "${Prefix}_Riot Games"
  $DestVal  = Join-Path $AppData "${Prefix}_VALORANT"

  Assert-DirectoryDoesNotExist -Path $DestRiot
  Assert-DirectoryDoesNotExist -Path $DestVal

  Move-Directory -Source $SrcRiot -Destination $DestRiot
  Move-Directory -Source $SrcVal -Destination $DestVal
}

function Execute-PopMode {
  param ($Prefix)

  Assert-SafePrefix -Prefix $Prefix
  Ensure-ProcessesAreDead

  $AppData = Get-LocalAppDataPath

  $SrcRiot = Join-Path $AppData "${Prefix}_Riot Games"
  $SrcVal  = Join-Path $AppData "${Prefix}_VALORANT"

  $DestRiot = Join-Path $AppData "Riot Games"
  $DestVal  = Join-Path $AppData "VALORANT"

  Confirm-UserDeletion -Path $DestRiot
  Confirm-UserDeletion -Path $DestVal

  Move-Directory -Source $SrcRiot -Destination $DestRiot
  Move-Directory -Source $SrcVal -Destination $DestVal
}

function Main {
  Assert-ArgsProvided -Argument $ActionOrPrefix -ErrorMessage "usage: stashval prefix OR stashval pop prefix"

  if ($ActionOrPrefix -eq "pop") {
    Assert-ArgsProvided -Argument $PopPrefix -ErrorMessage "usage: stashval pop prefix"
    Execute-PopMode -Prefix $PopPrefix
  } else {
    Execute-BackupMode -Prefix $ActionOrPrefix
  }
}

Main
