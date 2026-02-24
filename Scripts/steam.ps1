$target = $args[0]

if ($target -match '^\d+$') {
  $appId = $target
} elseif ($target) {
  switch -Regex ($target) {
    "^(a?pex)$" { $appId = "1172470" }
    "^(assetto|acor)$" { $appId = "244210" }
    "^(blend(er)?)$" { $appId = "365670" }
    "^(cs2?|csgo)$" { $appId = "730" }
    "^(cstrike|css)$" { $appId = "240" }
    "^cyberpunk$" { $appId = "1091500" }
    "^gmod$" { $appId = "4000" }
    "^(ins|insurgency)$" { $appId = "222880" }
    "^l4d2$" { $appId = "550" }
    "^(overwatch2?|ow2?)$" { $appId = "2357570" }
    "^portal$" { $appId = "400" }
    "^portal2$" { $appId = "620" }
    "^(pubg?)$" { $appId = "578080" }
    "^(quake3|q3a)$" { $appId = "2200" }
    "^(rocketleague|rl)$" { $appId = "252950" }
    "^rust$" { $appId = "252490" }
    "^(tf2?)$" { $appId = "440" }
    Default { $appId = $null }
  }
}

if ($appId) {
  Write-Host "[+] Launching AppID $appId ($target)..." -ForegroundColor Cyan
  Start-Process "steam://rungameid/$appId"
} elseif ($target) {
  Write-Host "[+] Opening Steam Section: $target" -ForegroundColor Green
  Start-Process "steam://open/$target"
} else {
  Write-Host "[+] Opening Steam Library..." -ForegroundColor Gray
  Start-Process "steam://open/games"
}
