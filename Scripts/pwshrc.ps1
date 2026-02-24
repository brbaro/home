if ($PWD.Path -like "$env:SystemRoot\*") { Set-Location -LiteralPath "$HOME" }

if ($host.Name -eq 'ConsoleHost' -and (Get-Module -ListAvailable PSReadLine)) {
  Import-Module PSReadLine
  Set-PSReadLineKeyHandler -Chord "Ctrl+d" -Function DeleteCharOrExit
  Set-PSReadLineKeyHandler -Chord "Ctrl+a" -Function BeginningOfLine
  Set-PSReadLineKeyHandler -Chord "Ctrl+e" -Function EndOfLine
  Set-PSReadLineKeyHandler -Chord "Ctrl+u" -Function BackwardKillLine
  Set-PSReadLineKeyHandler -Chord "Ctrl+k" -Function KillLine
  Set-PSReadLineKeyHandler -Chord "Ctrl+y" -Function Yank
}

function Import-LocalProfile {
  $localProfile = Join-Path $PSScriptRoot "Local"
  $localProfile = Join-Path $localProfile "pwshrc.ps1"
  if (Test-Path $localProfile) { . $localProfile }
}
Import-LocalProfile

function profo {
  $localProfile = Join-Path $PSScriptRoot "Local" "pwshrc.ps1"
  vim "$HOME/Scripts/Local/pwshrc.ps1"
  Import-LocalProfile
}

function prompt {
  if ($Shell) {
    $shellName = $Shell
  } elseif ($env:SHELL) {
    $shellName = Split-Path $env:SHELL -Leaf
  } else {
    $shellName = (Get-Process -Id $PID).ProcessName
  }

  $styleRaw = if ($env:PROMPT_STYLE) { $env:PROMPT_STYLE } else { "λ: Gray Gray" }
  $styleParts = $styleRaw -split '\s+', 3
  $pIcon = if ($styleParts.Count -ge 1 -and $styleParts[0]) { $styleParts[0] } else { "λ:" }
  $pColor = if ($styleParts.Count -ge 2 -and $styleParts[1]) { $styleParts[1] } else { "Gray" }
  $pAccent = if ($styleParts.Count -ge 3 -and $styleParts[2]) { $styleParts[2] } else { "Gray" }

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
    Write-Host "Example: shtyle 'λ:' Cyan Gray" -ForegroundColor Gray
    Write-Host "`nColors: Black, Blue, Cyan, Gray, Green, Magenta, Red, White, Yellow"
    return
  }
  $style = "$icon $color $accent"
  $env:PROMPT_STYLE = $style
  [Environment]::SetEnvironmentVariable("PROMPT_STYLE", $style, "User")
  Write-Host "[+] Shtyle updated! (Style: $style)" -ForegroundColor Green
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

function which { why path @args }

function ciao { Write-Host "Ciao!"; exit }

function rez { $rc = "$HOME/Scripts/pwshrc.ps1"; if (Test-Path -LiteralPath $rc) { . $rc } }

function x { pow bal }

function z { pow sav }

function zz {
  $signature = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
  $type = Add-Type -MemberDefinition $signature -Name "Win32Mon" -Namespace "Win32Utils" -PassThru -ErrorAction SilentlyContinue
  $type::SendMessage(-1, 0x0112, 0xF170, 2)
}

function zzz {
  sleepfor @args
  Add-Type -AssemblyName 'System.Windows.Forms'
  [System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $false)
}

function zzzz { z; zzz @args }

function rebo {  sleepfor @args; shutdown -r -t 0 }

function off { sleepfor @args; shutdown -s -t 0 }

function wu { wudo powsh }

function winvars { Start-Process "control.exe" -ArgumentList "sysdm.cpl,,3" }

function fw { Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table }

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

function l { Get-ChildItem -Force $args | Sort-Object LastWriteTime -Descending }

function ll { Get-ChildItem -Force $args | Sort-Object LastWriteTime -Descending }

function homelock {
  param([string]$Target = $HOME)
  $user = $env:USERNAME
  $shouldLockHome = Read-Host "Lock $Target for $user? [y/N]"
  if ($shouldLockHome -eq "y") {
    Write-Host "[*] Locking..." -ForegroundColor Cyan
    icacls $Target /inheritance:d | Out-Null
    icacls $Target /remove "Users" "Everyone" | Out-Null
    icacls $Target /grant "${user}:(OI)(CI)F" | Out-Null
    Write-Host "[+] Ignoto." -ForegroundColor Green
  }
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

function lan {
  Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.InterfaceAlias -notmatch 'Loopback|Virtual' } |
  Select-Object -ExpandProperty IPAddress
}

function whatsmyip { Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5 }

function ips { ipconfig.exe /all }

function rdp {
  param($server)
  if ($null -eq $server) { Start-Process mstsc }
  else { Start-Process mstsc -ArgumentList "/v:$server" }
}

function whereami {
  $output = if ($env:whereami) { $env:whereami } else { "windows" }
  Write-Host $output
}

function chat {
  $query = $args -join " "
  if ([string]::IsNullOrWhiteSpace($query)) {
    Start-Process "https://chat.openai.com"
  } else {
    $encodedQuery = [uri]::EscapeDataString($query)
    Start-Process "https://chat.openai.com?q=$encodedQuery"
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

function ff { start firefox @args }

function edge { start msedge @args }

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

function unzen { zen off }

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

function paths { [Environment]::GetEnvironmentVariable('Path', 'User') }

function pingonce {
  param($target = "github.com")
  if (Test-Connection -ComputerName $target -Count 1 -Quiet) {
    Write-Host "connected" -ForegroundColor Green
  } else {
    Write-Host "offline" -ForegroundColor Red
    return $false
  }
}

function bloats {
  Get-AppxProvisionedPackage -Online | Select DisplayName, PackageName
  Write-Host "Get-AppxPackage *NAME* | Remove-AppxPackage"
}

function updates {
  $session  = New-Object -ComObject Microsoft.Update.Session
  $searcher = $session.CreateUpdateSearcher()
  $searcher.Search("IsInstalled=0").Updates |
  ForEach-Object {
    [PSCustomObject]@{
      Title        = $_.Title
      KB           = ($_.KBArticleIDs -join ',')
      Severity     = $_.MsrcSeverity
      Downloaded   = $_.IsDownloaded
      Mandatory    = $_.IsMandatory
      RebootNeeded = $_.RebootRequired
    }
  }
}

function lmsup { irm https://lmstudio.ai/install.ps1 | iex }

function Invoke-ClacWrapper {
  param($Operator, $Numbers)
  clac $Operator @Numbers
}

function virt-manager { & "$Env:windir\System32\mmc.exe" "$Env:windir\System32\virtmgmt.msc" }

function add { Invoke-ClacWrapper -Operator "add" -Numbers $args }
function mul { Invoke-ClacWrapper -Operator "mul" -Numbers $args }
function div { Invoke-ClacWrapper -Operator "div" -Numbers $args }
function sub { Invoke-ClacWrapper -Operator "sub" -Numbers $args }
function avg { Invoke-ClacWrapper -Operator "avg" -Numbers $args }

Set-Alias -Name qq -Value ciao
Set-Alias -Name su -Value iddqd
Set-Alias -Name audio -Value mmsys.cpl
Set-Alias -Name apps -Value appwiz.cpl
Set-Alias -Name nets -Value ncpa.cpl
Set-Alias -Name ctrl -Value control.exe
Set-Alias -Name hwi -Value HWiNFO64.exe
Set-Alias -Name mon -Value Taskmgr.exe
Set-Alias -Name memtest -Value mdsched.exe
Set-Alias -Name jbt -Value "$Env:LOCALAPPDATA\JetBrains\Toolbox\jetbrains-toolbox.exe"
