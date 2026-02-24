param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Word
)

function Get-WordDefinition {
  $url = "https://api.dictionaryapi.dev/api/v2/entries/en/{0}" -f [System.Uri]::EscapeDataString($Word)

  try {
    $rawResponse = irmcache for 7d $url
    $data = $rawResponse | ConvertFrom-Json
  } catch {
    Write-Error "Could not retrieve definition for '$Word'."
    return
  }

  foreach ($entry in $data) {
    Write-Host "=== $($entry.word.ToUpper()) ===" -ForegroundColor Cyan

    if ($entry.phonetic) {
      Write-Host "Pronunciation: $($entry.phonetic)" -ForegroundColor Gray
    }

    foreach ($meaning in $entry.meanings) {
      Write-Host "`n[$($meaning.partOfSpeech)]" -ForegroundColor Yellow

      $index = 1
      foreach ($def in $meaning.definitions) {
        Write-Host ("  {0}. {1}" -f $index, $def.definition)
        if ($def.example) {
          Write-Host ("     Example: `"{0}`"" -f $def.example) -ForegroundColor DarkGray
        }
        $index++
      }
    }
    Write-Host ""
  }
}

Get-WordDefinition
