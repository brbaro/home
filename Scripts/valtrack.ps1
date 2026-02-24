#!/usr/bin/env pwsh

if ($args.Length -lt 1) { Write-Error "Usage: valtrack name tag"; return }

$full = $args -join ' '

if ($full -match '#') {
  $player = $full -replace ' ', '%20' -replace '#', '%23'
} else {
  if ($args.Length -lt 2) { Write-Error "Usage: valtrack name tag"; return }
  $player = ($args[0..($args.Length - 2)] -join '%20') + '%23' + $args[-1]
}

start "https://tracker.gg/valorant/profile/riot/$player/overview?platform=pc&playlist=competitive"
