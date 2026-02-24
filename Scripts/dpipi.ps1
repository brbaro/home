$game = $args[0]
if (!$game) {
  Write-Host "`nUsage: sens [game] [-i] [val] [dpi]" -ForegroundColor Yellow
  Write-Host "Games: source, apex, fortnite, mwf, overwatch, quake3, realm, siege, splitgate, valorant`n" -ForegroundColor Gray
  exit
}

switch -Regex ($game) {
  "^(source|apex|cs|cs2|gmod|hl2|l4d|l4d2|portal|portal2|tf2)$" { $engine_sens = 2 }
  "^(fortnite|fn|siege|rss)$" { $engine_sens = 8 }
  "^mwf$" { $engine_sens = 7 }
  "^(overwatch|ow)$" { $engine_sens = 6.77 }
  "^realm$" { $engine_sens = 5.4 }
  "^(quake3|q3a)$" { $engine_sens = 2.2 }
  "^(sg|splitgate)$" { $engine_sens = 4.7 }
  "^(val|valorant)$" { $engine_sens = 0.635 }
  Default { Write-Host "[!] Unknown game: $game" -ForegroundColor Red; exit }
}

$label = "Sensitivity: "
$invert = $false
$val_prompt = "Inches per pi [10]"
$val_default = 10
$target_val = $args[1]
$target_dpi = $args[2]

if ($args[1] -eq "-i") {
  $label = "Inches per pi: "
  $invert = $true
  $val_prompt = "Sensitivity [$engine_sens]"
  $val_default = $engine_sens
  $target_val = $args[2]
  $target_dpi = $args[3]
}

$user_val = if ($target_val) { $target_val } else { Read-Host "$val_prompt" }
if (!$user_val) { $user_val = $val_default }

$user_dpi = if ($target_dpi) { $target_dpi } else { Read-Host "Dots per inch [800]" }
if (!$user_dpi) { $user_dpi = 800 }

$dpiMult = 400 / [double]$user_dpi
$valMult = (10 * $engine_sens) / [double]$user_val
$result = [math]::Round($valMult * $dpiMult, 4)

Write-Host "$label$result" -ForegroundColor Green
