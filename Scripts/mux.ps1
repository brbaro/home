#!/usr/bin/env pwsh

function Get-ActivePSMuxSessions { return psmux ls 2>$null | Select-String "created" }

function Connect-ExistingSession { psmux attach }

function Get-AccentColorFromEnvironment {
  $defaultColor = "white"
  $style = [Environment]::GetEnvironmentVariable("PROMPT_STYLE", "User")

  if (![string]::IsNullOrWhiteSpace($style)) {
    $styleParts = $style -split " "
    if ($styleParts.Count -ge 2) {
      return $styleParts[-1].ToLower()
    }
  }
  return $defaultColor
}

function Build-PSMuxConfigurationContent {
  param([string]$accentColor)

$window_switcher='if -F "#{>=:#{session_windows},2}" "next-window" "new-window"'
$pane_switcher='if -F "#{>=:#{window_panes},2}" "select-pane -t :.+" "split-window -h -c \"#{pane_current_path}\""'
$paste_command='run "powershell.exe -NoProfile -Command Get-Clipboard | psmux load-buffer - && psmux choose-buffer"'
$copy_command='run "tmux show-buffer | clip.exe"'
$template = @'
set -g default-command powsh
set -g prefix C-b
set -g history-limit 100000
set -g pane-border-style fg=ACCENT_COLOR
set -g pane-active-border-style fg=ACCENT_COLOR
set -g window-status-current-format "[#W]"
set -g window-status-format " #W "
set -g status-style bg=ACCENT_COLOR,fg=black
set -g status-interval 10
set -g status-left " "
set -g status-right " #(powershell -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%/Scripts/batt.ps1) %m/%d/%y %H:%M "
set -g status-right-length 40
set -g mouse on
set-hook -g client-resized "refresh-client -S"
setw -g mode-keys vi
setw -g clock-mode-colour ACCENT_COLOR
setw -g clock-mode-style 24
bind -n M-S-t clock-mode
bind -n M-m set -g mouse
bind -n M-w select-pane -U
bind -n M-a select-pane -L
bind -n M-s select-pane -D
bind -n M-d select-pane -R
bind -n M-S-w resize-pane -U 5
bind -n M-S-a resize-pane -L 5
bind -n M-S-s resize-pane -D 5
bind -n M-S-d resize-pane -R 5
bind -n M-z resize-pane -Z
bind -n M-Enter resize-pane -Z
bind -n M-\ split-window -h -c "#{pane_current_path}"
bind -n M-S-\ split-window -v -c "#{pane_current_path}"
bind -n M-q detach-client
bind -n M-S-k kill-pane
bind -n M-n new-window
bind -n M-e select-layout even-horizontal
bind -n M-S-e select-layout tiled
bind -n M-c COPY_COMMAND
bind -n M-v PASTE_COMMAND
bind -n M-p choose-buffer
bind -n M-S-p paste-buffer
bind -n M-x PANE_SWITCHER
bind -n M-S-x "select-pane -t :.+; resize-pane -Z"
bind -n M-g WINDOW_SWITCHER
bind -n M-` WINDOW_SWITCHER
bind -n M-1 select-window -t 0
bind -n M-2 select-window -t 1
bind -n M-3 select-window -t 2
bind -n M-4 select-window -t 3
bind -n MouseDown3Pane resize-pane -Z
bind -T copy-mode-vi MouseDown3Pane send-keys -X copy-pipe-and-cancel
unbind -T copy-mode-vi MouseDragEnd1Pane
bind-key -n DoubleClick1Pane "select-pane ; copy-mode -M ; send-keys -X select-word"
bind-key -n TripleClick1Pane "select-pane ; copy-mode -M ; send-keys -X select-line"
'@
  $template=$template.Replace("ACCENT_COLOR", $accentColor)
  $template=$template.Replace("WINDOW_SWITCHER", $window_switcher)
  $template=$template.Replace("PANE_SWITCHER", $pane_switcher)
  $template=$template.Replace("PASTE_COMMAND", $paste_command)
  $template=$template.Replace("COPY_COMMAND", $copy_command)
  return $template
}

function Get-CurrentConfigurationContent {
  param([string]$path)

  if (Test-Path $path) {
    return Get-Content $path -Raw
  }
  return ""
}

function Save-NewConfigurationIfChanged {
  param([string]$path, [string]$newContent)

  $currentContent = Get-CurrentConfigurationContent -path $path
  if ($currentContent.Trim() -ne $newContent.Trim()) {
    $newContent | Out-File -FilePath $path -Encoding ascii -Force
  }
}

function Initialize-MuxEnvironment {
  $targetPath = Join-Path $HOME ".psmux.conf"
  $accentColor = Get-AccentColorFromEnvironment
  $configContent = Build-PSMuxConfigurationContent -accentColor $accentColor

  Save-NewConfigurationIfChanged -path $targetPath -newContent $configContent
  psmux -f $targetPath new-session powsh
}

function Invoke-Mux {
  if (Get-ActivePSMuxSessions) {
    Connect-ExistingSession
    return
  }
  Initialize-MuxEnvironment
}

Invoke-Mux
