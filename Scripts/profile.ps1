
function Import-LocalProfile {
  $localPath = Join-Path $PSScriptRoot "Local"
  $localProfile = Join-Path $localPath "profile.ps1"
  if (Test-Path $localProfile) {
    . $localProfile
  }
}
Import-LocalProfile

function prompt {
  if ($Shell) {
    $shellName = $Shell
  } elseif ($env:SHELL) {
    $shellName = Split-Path $env:SHELL -Leaf
  } else {
    $shellName = (Get-Process -Id $PID).ProcessName
  }
  $pColor = if ($env:PROMPT_COLOR) { $env:PROMPT_COLOR } else { "White" }
  $pAccent = if ($env:PROMPT_ACCENT) { $env:PROMPT_ACCENT } else { "White" }
  $pIcon = if ($env:PROMPT_ICON) { $env:PROMPT_ICON } else { ">:" }
  $time = Get-Date -Format "HH:mm:ss"
  $currentPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
  $displayPath = $currentPath -replace [regex]::Escape($HOME), "~"
  Write-Host "$env:USERNAME " -NoNewline -ForegroundColor $pColor
  Write-Host "$env:COMPUTERNAME " -NoNewline -ForegroundColor $pAccent
  Write-Host "$shellName " -NoNewline -ForegroundColor $pAccent
  Write-Host "$time " -NoNewline -ForegroundColor $pAccent
  Write-Host "$displayPath" -ForegroundColor $pColor
  Write-Host "$pIcon" -NoNewline -ForegroundColor $pColor
  return " "
}

function shtyle {
  param($icon, $color, $accent)
  if (!$icon -or !$color -or !$accent) {
    Write-Host "Usage:   shtyle [Icon] [Color] [Accent]" -ForegroundColor Yellow
    Write-Host "Example: shtyle '>:' Cyan Gray" -ForegroundColor Gray
    Write-Host "`nColors: Black, Blue, Cyan, Gray, Green, Magenta, Red, White, Yellow"
    return
  }
  $env:PROMPT_ICON = $icon
  $env:PROMPT_COLOR = $color
  $env:PROMPT_ACCENT = $accent
  [Environment]::SetEnvironmentVariable("PROMPT_ICON", $icon, "User")
  [Environment]::SetEnvironmentVariable("PROMPT_COLOR", $color, "User")
  [Environment]::SetEnvironmentVariable("PROMPT_ACCENT", $accent, "User")
  Write-Host "[+] Shtyle updated! (Icon: $icon, Color: $color, Accent: $accent)" -ForegroundColor Green
}

function gg {
  param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputObject,
    [Parameter(Position = 0)]
    [string]$Pattern,
    [switch]$v,
    [switch]$i
  )
  process {
    if ($InputObject) {
      $match = $InputObject | Select-String -Pattern $Pattern -NotMatch:$v -CaseSensitive:(!$i)
      if ($match) {
        $match.Line
      }
    }
  }
}

function open { Start-Process $args[0] }

function wudo {
  param([Parameter(ValueFromRemainingArguments=$true)]$Command)
  if ($null -eq $Command) {
    Start-Process powershell -Verb RunAs
  } else {
    $cmdString = "cmd /c $Command & pause"
    Start-Process cmd -ArgumentList "/c $cmdString" -Verb RunAs
  }
}

function ciao { Write-Host "Ciao!"; exit }

if ($host.Name -eq 'ConsoleHost' -and (Get-Module -ListAvailable PSReadLine)) {
  Import-Module PSReadLine
  Set-PSReadLineKeyHandler -Chord "Ctrl+d" -Function DeleteCharOrExit
}

function zz {
  $signature = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
  $type = Add-Type -MemberDefinition $signature -Name "Win32Mon" -Namespace "Win32Utils" -PassThru -ErrorAction SilentlyContinue
  $type::SendMessage(-1, 0x0112, 0xF170, 2)
}

function zzz {
  Add-Type -AssemblyName 'System.Windows.Forms'
  [System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $false)
}

function rebo { shutdown -r -t 0 }

function off { shutdown -p }

function pow {
  param($name)
  $schemes = powercfg -list | Out-String
  $active = powercfg -getactivescheme
  $prevMatch = [regex]::Match($active, '\((.*)\)')
  $previous = $prevMatch.Groups[1].Value

  if ($null -eq $name) {
    Write-Host $previous -ForegroundColor Cyan
    return
  }

  $targetLine = $schemes -split "`r`n" | Where-Object { $_ -like "*$name*" }
  if ($targetLine) {
    $guid = [regex]::Match($targetLine, '([a-z0-9-]{36})').Groups[1].Value
    powercfg -setactive $guid
    $newActive = powercfg -getactivescheme
    $currMatch = [regex]::Match($newActive, '\((.*)\)')
    $current = $currMatch.Groups[1].Value
    Write-Host "$previous -> $current" -ForegroundColor Green
  } else {
    Write-Host "Scheme '$name' not found." -ForegroundColor Red
  }
}
function z { pow sav }
function x { pow bal }

function batt {
  $charge = (Get-CimInstance -ClassName Win32_Battery).EstimatedChargeRemaining
  if ($null -eq $charge) {
    Write-Host "No battery detected (Desktop?)" -ForegroundColor Gray
  } else {
    Write-Host "$($charge)%" -ForegroundColor Green
  }
}

function l { Get-ChildItem -Force $args | Sort-Object LastWriteTime -Descending }

function ll { Get-ChildItem -Force $args | Sort-Object LastWriteTime -Descending }

function rmrf {
  param([string]$Path)
  if (Test-Path $Path) {
    Remove-Item -Path $Path -Recurse -Force -Verbose
    Write-Host "[+] $Path purged." -ForegroundColor Green
  }
}

function chownr {
  param([string]$Path)
  $user = $env:USERNAME
  Write-Host "[*] Locking down $Path for $user..." -ForegroundColor Cyan
  icacls $Path /inheritance:d | Out-Null
  icacls $Path /remove "Users" "Everyone" | Out-Null
  icacls $Path /grant "${user}:(OI)(CI)F" | Out-Null
  Write-Host "[+] Ignoto." -ForegroundColor Green
}

function zip {
  param($source, $dest)
  Compress-Archive -Path $source -DestinationPath $dest -Force
}

function unzip {
  param($source, $dest)
  Expand-Archive -Path $source -DestinationPath $dest -Force
}

function sha256sum {
  param($path)
  Get-FileHash $path -Algorithm SHA256 | Format-List
}

function wan {
  try {
    $res = Invoke-RestMethod -Uri "https://brbaro.web.app/ping" -TimeoutSec 7
    if ($res.Trim() -eq "pong") { Write-Host "connected" -ForegroundColor Green }
    else { Write-Host "offline" -ForegroundColor Red }
  } catch {
    Write-Host "offline" -ForegroundColor Red
  }
}

function rdp {
  param($server)
  if ($null -eq $server) { Start-Process mstsc }
  else { Start-Process mstsc -ArgumentList "/v:$server" }
}

function whereami {
  $output = if ($env:whereami) { $env:whereami } else { "windows" }
  Write-Host $output
}

function bot {
  $query = $args -join " "
  if ([string]::IsNullOrWhiteSpace($query)) {
    Start-Process "https://chat.openai.com"
  } else {
    $encodedQuery = [uri]::EscapeDataString($query)
    Start-Process "https://chat.openai.com?q=$encodedQuery"
  }
}

function web ($target) {
  $links = @{
    "/."  = "https://slashdot.org"
    "yt"  = "https://youtube.com"
    "via"  = "https://usevia.app"
  }
  if (-not $target) {
    Start-Process "https://google.com"
  }
  elseif ($links.ContainsKey($target)) {
    Start-Process $links[$target]
  }
  elseif ($target -match '^[a-z]+://') {
    Start-Process $target
  }
  elseif ($target -notcontains ".") {
    Start-Process "https://$target.com"
  }
  else {
    Start-Process "https://$target"
  }
}

function goo {
  $query = $args -join "+"
  if (!$query) { Start-Process "https://google.com" }
  else { Start-Process "https://www.google.com/search?q=$query" }
}

function dis {
  $discord = "$env:LOCALAPPDATA\Discord\Update.exe"
  if (Test-Path $discord) {
    Start-Process $discord -ArgumentList "--processStart Discord.exe"
  } else {
    Write-Host "[!] Discord not found in LocalAppData." -ForegroundColor Red
  }
}

function fin {
  param($owner = $env:USERNAME)
  Write-Host "[*] Terminating all processes for user: $owner" -ForegroundColor Yellow
  taskkill /f /fi "USERNAME eq $owner"
}

function killall {
  foreach ($proc in $args) {
    $procName = $proc -replace '\.exe$', ''
    Write-Host "[-] Killing $procName..." -ForegroundColor Cyan
    taskkill /f /im "$procName.exe" 2>$null
  }
}

function uptime {
  $os = Get-CimInstance -ClassName Win32_OperatingSystem
  $uptime = New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date)
  $days    = $uptime.Days
  $hours   = $uptime.Hours
  $minutes = $uptime.Minutes
  $seconds = $uptime.Seconds
  $bootDate = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "System Uptime: " -NoNewline -ForegroundColor Cyan
  Write-Host "$days days, $hours hours, $minutes minutes, $seconds seconds" -ForegroundColor Green
  Write-Host "Last Boot:     " -NoNewline -ForegroundColor Gray
  Write-Host "$bootDate" -ForegroundColor DarkGray
}

function mobo {
  $board = Get-CimInstance Win32_BaseBoard
  Write-Host "`nChecking Motherboard..." -ForegroundColor Gray
  Write-Host "Manufacturer : $($board.Manufacturer) $($board.Product)" -ForegroundColor Green
}

function paths { [Environment]::GetEnvironmentVariable('Path', 'User') }

function ips { ipconfig.exe /all }

function pingonce {
  param($target = "github.com")
  if (Test-Connection -ComputerName $target -Count 1 -Quiet) {
    Write-Host "connected" -ForegroundColor Green
  } else {
    Write-Host "offline" -ForegroundColor Red
    return $false
  }
}

function nics {
  param($action, $name)
  if (!$action) {
    Write-Host "--- Network Interfaces ---" -ForegroundColor Cyan
    Get-NetAdapter | Select-Object Name, Status, InterfaceDescription | Format-Table
    Write-Host "Usage: nics [up/down] 'Interface Name'" -ForegroundColor Gray
    return
  }
  if (!$name) {
    Write-Host "[!] Error: Specify interface name (e.g., nics up 'Ethernet')" -ForegroundColor Red
    return
  }
  if ($action -eq "up") {
    Enable-NetAdapter -Name $name -Confirm:$false
    Write-Host "[+] Enabling $name..." -ForegroundColor Green
  } elseif ($action -eq "down") {
    Disable-NetAdapter -Name $name -Confirm:$false
    Write-Host "[-] Disabling $name..." -ForegroundColor Yellow
  }
  Get-NetAdapter -Name $name | Select-Object Name, Status
}

function Invoke-ClacWrapper {
  param($Operator, $Numbers)
  clac $Operator @Numbers
}

function add { Invoke-ClacWrapper -Operator "add" -Numbers $args }
function mul { Invoke-ClacWrapper -Operator "mul" -Numbers $args }
function div { Invoke-ClacWrapper -Operator "div" -Numbers $args }
function sub { Invoke-ClacWrapper -Operator "sub" -Numbers $args }
function avg { Invoke-ClacWrapper -Operator "avg" -Numbers $args }

function pkgscrub {
  Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay | Remove-AppxPackage -AllUsers
  Get-AppxPackage -AllUsers *WindowsTerminal* | Remove-AppxPackage -AllUsers
}

function pkg {
  Write-Host "todo"
  return
  $action = $args[0]
  $query = $args[1]
  $remainingArgs = $args | Select-Object -Skip 2
  $packages = @{
    "7z"  = "7zip.7zip"
    "blender"  = "BlenderFoundation.Blender"
    "discord" = "Discord.Discord"
    "code"  = "Microsoft.VisualStudioCode"
    "docker" = "Docker.DockerDesktop"
    "dotnet8" = "Microsoft.DotNetDesktopRuntime.8"
    "epic" = "EpicGames.EpicGamesLauncher"
    "firefox" = "Mozilla.Firefox"
    "gimp" = "GIMP.GIMP.3"
    "git" = "Git.Git"
    "itunes" = "Apple.iTunes"
    "jbt" = "JetBrains.Toolbox"
    "minecraft" = "Mojang.MinecraftLauncher"
    "mixxx" = "MiXXX.MiXXX"
    "node" = "OpenJS.NodeJS.LTS"
    "obs" = "OBSProject.OBSStudio"
    "python" = "Python.Python.3.12"
    "riot" = "RiotGames.Valorant.NA"
    "reaper" = "Cockos.REAPER"
    "steam" = "Valve.Steam"
    "sudo" = "Microsoft.Sudo"
    "terminal" = "Microsoft.WindowsTerminal"
    "vbox" = "Oracle.VirtualBox"
    "vdj" = "AtomixProductions.VirtualDJ"
    "vim" = "vim.vim"
    "vs" = "Microsoft.VisualStudio.Community"
    "wsl" = "Microsoft.WSL"
  }
  $wingetAction = switch ($action) {
    "i" { "install" }
    "s" { "search" }
    default { $action }
  }
  if ($packages.ContainsKey($query)) {
    $targetId = $packages[$query]
  } else {
    $targetId = $query
  }
  if ($wingetAction -eq "install") {
    winget install -e --id $targetId --source winget $remainingArgs
  } else {
    winget $wingetAction $targetId $remainingArgs
  }
}

Set-Alias -Name qq -Value ciao
