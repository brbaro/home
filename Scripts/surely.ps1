#!/usr/bin/env pwsh

param (
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$PassedArgs
)

function Get-ArgumentMessage {
  param (
    [string[]]$ScriptArgs
  )
  return @($ScriptArgs)
}

function Determine-SurelyMode {
  param (
    [string]$EnvSurely,
    [array]$MessageArray
  )
  if ($EnvSurely -eq 'skip') { return 'skip' }
  if ($MessageArray.Count -gt 0 -and $MessageArray[0] -eq 'sure') { return 'sure' }
  return $EnvSurely
}

function Slice-Message {
  param (
    [array]$MessageArray,
    [string]$SurelyMode
  )
  if ($SurelyMode -eq 'sure' -and $MessageArray.Count -gt 1) {
    return @($MessageArray[1..($MessageArray.Count - 1)])
  }
  if ($SurelyMode -eq 'sure') {
    return @()
  }
  return $MessageArray
}

function Get-PromptText {
  param (
    [array]$MessageArray
  )
  if ($MessageArray.Count -gt 0) {
    return [string]($MessageArray -join ' ')
  }
  return 'proceed'
}

function Get-ChoiceLabel {
  param (
    [string]$SurelyMode
  )
  if ($SurelyMode -eq 'sure') { return '[Y/n]' }
  return '[y/N]'
}

function Read-UserConfirmation {
  param (
    [string]$PromptText,
    [string]$Choices,
    [string]$SurelyMode
  )
  Write-Host "${PromptText}? ${Choices}: " -NoNewline
  $Selection = Read-Host
  if ($SurelyMode -eq 'sure' -and [string]::IsNullOrWhiteSpace($Selection)) {
    return 'y'
  }
  return $Selection
}

function Evaluate-Selection {
  param (
    [string]$Selection
  )
  return ($Selection.Trim().ToLowerInvariant() -match '^y(es)?$')
}

function Invoke-ConfirmationScript {
  param (
    [string[]]$ArgsToProcess
  )
  $RawMessage = Get-ArgumentMessage -ScriptArgs $ArgsToProcess
  $SurelyMode = Determine-SurelyMode -EnvSurely $env:surely -MessageArray $RawMessage

  if ($SurelyMode -eq 'skip') {
    return $true
  }

  $CleanedMessage = Slice-Message -MessageArray $RawMessage -SurelyMode $SurelyMode
  $PromptText = Get-PromptText -MessageArray $CleanedMessage
  $Choices = Get-ChoiceLabel -SurelyMode $SurelyMode

  $Selection = Read-UserConfirmation -PromptText $PromptText -Choices $Choices -SurelyMode $SurelyMode
  return (Evaluate-Selection -Selection $Selection)
}

Invoke-ConfirmationScript -ArgsToProcess $PassedArgs
