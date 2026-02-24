#!/usr/bin/env pwsh

# ============================================================
#  Reaction Time Test  –  Human Benchmark style  (v2 – low latency)
#  Requires: Windows PowerShell 5.1+ (built into Windows 11)
#  No external dependencies – uses System.Windows.Forms only
#
#  LATENCY OPTIMISATIONS vs v1:
#   1. NtSetTimerResolution  – pushes Windows scheduler tick from the
#      default 15.625 ms down to ~0.5 ms for the life of this process.
#   2. WM_LBUTTONDOWN        – FastPanel captures mouse-PRESS instead of
#      mouse-RELEASE (Click), saving 50-100 ms per click.
#   3. panel.Refresh()       – synchronous WM_PAINT, no async queue.
#   4. DwmFlush()            – clock starts after DWM presents the frame
#      the user actually sees, not a buffered future frame.
#   5. Process priority High – reduces OS preemption of the message pump.
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Inline C#: P/Invoke + FastPanel subclass ─────────────────
# NOTE: Add-Type in PowerShell 5.1 uses the .NET 4.x compiler which
# defaults to C# 5 — the ?. null-conditional operator is C# 6+.
# Use an explicit null-check instead.
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class WinApi {
    [DllImport("ntdll.dll")]
    public static extern int NtSetTimerResolution(
        uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

    [DllImport("ntdll.dll")]
    public static extern int NtQueryTimerResolution(
        out uint Minimum, out uint Maximum, out uint Current);

    [DllImport("dwmapi.dll")]
    public static extern int DwmFlush();
}

public class FastPanel : Panel {
    private const int WM_LBUTTONDOWN = 0x0201;
    public event EventHandler MousePressed;
    public string MainText { get; set; }
    public string SubText { get; set; }
    public Color MainForeColor { get; set; }
    public Color SubForeColor { get; set; }
    public Font MainFont { get; set; }
    public Font SubFont { get; set; }

    public FastPanel() {
        this.DoubleBuffered = true;
        this.MainText = string.Empty;
        this.SubText = string.Empty;
        this.MainForeColor = Color.White;
        this.SubForeColor = Color.FromArgb(200, 200, 200);
    }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);

        Rectangle mainRect = new Rectangle(0, 40, this.ClientSize.Width, 170);
        Rectangle subRect  = new Rectangle(0, 215, this.ClientSize.Width, 40);

        using (StringFormat sf = new StringFormat()) {
            sf.Alignment = StringAlignment.Center;
            sf.LineAlignment = StringAlignment.Center;

            using (Brush mainBrush = new SolidBrush(this.MainForeColor))
            using (Brush subBrush = new SolidBrush(this.SubForeColor)) {
                if (!string.IsNullOrEmpty(this.MainText) && this.MainFont != null) {
                    e.Graphics.DrawString(this.MainText, this.MainFont, mainBrush, mainRect, sf);
                }
                if (!string.IsNullOrEmpty(this.SubText) && this.SubFont != null) {
                    e.Graphics.DrawString(this.SubText, this.SubFont, subBrush, subRect, sf);
                }
            }
        }
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_LBUTTONDOWN) {
            EventHandler handler = MousePressed;
            if (handler != null) handler(this, EventArgs.Empty);
        }
        base.WndProc(ref m);
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms", "System.Drawing"

# ── Raise process priority ────────────────────────────────────
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass =
    [System.Diagnostics.ProcessPriorityClass]::High

# ── Set Windows timer resolution to ~0.5 ms ──────────────────
$minRes = $maxRes = $curRes = [uint32]0
[WinApi]::NtQueryTimerResolution([ref]$minRes, [ref]$maxRes, [ref]$curRes) | Out-Null
$originalResolution = $curRes
$dummy = [uint32]0
[WinApi]::NtSetTimerResolution(5000, $true, [ref]$dummy) | Out-Null  # 5000 x 100ns = 0.5 ms

# ── State ────────────────────────────────────────────────────
$script:state      = 'waiting'
$script:startTime  = [long]0
$script:scores     = @()
$script:timer      = $null
$script:maxRounds  = 5

# ── Colours ──────────────────────────────────────────────────
$colBlue   = [System.Drawing.Color]::FromArgb(52,  152, 219)
$colRed    = [System.Drawing.Color]::FromArgb(192,  57,  43)
$colGreen  = [System.Drawing.Color]::FromArgb(39,  174,  96)
$colOrange = [System.Drawing.Color]::FromArgb(230, 126,  34)
$colDark   = [System.Drawing.Color]::FromArgb(30,   30,  30)
$colLight  = [System.Drawing.Color]::White

# ── Layout constants (single place to adjust) ────────────────
$formW      = 640
$panelH     = 260   # click panel height
$panelY     = 20
$panelX     = 30
$panelW     = $formW - ($panelX * 2)   # 580
$roundY     = $panelY + $panelH + 8    # 288
$infoY      = $roundY + 28             # 316
$listY      = $infoY  + 22             # 338
$listH      = 105
$btnY       = $listY  + $listH + 8     # 451
$formH      = $btnY   + 36 + 48        # 535  (btn height + chrome padding)

# ── Form ─────────────────────────────────────────────────────
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = 'Reaction Time Test  (v2 - low latency)'
$form.ClientSize      = New-Object System.Drawing.Size($formW, $formH)
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $colDark
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox     = $false
$form.Font            = New-Object System.Drawing.Font('Segoe UI', 11)
$form.KeyPreview      = $true

# ── FastPanel ────────────────────────────────────────────────
$panel           = New-Object FastPanel
$panel.Size      = New-Object System.Drawing.Size($panelW, $panelH)
$panel.Location  = New-Object System.Drawing.Point($panelX, $panelY)
$panel.BackColor = $colBlue
$panel.Cursor    = [System.Windows.Forms.Cursors]::Hand
$panel.MainFont  = New-Object System.Drawing.Font('Segoe UI', 28, [System.Drawing.FontStyle]::Bold)
$panel.SubFont   = New-Object System.Drawing.Font('Segoe UI', 12)
$panel.MainText  = 'Click to Start'
$panel.SubText   = 'Wait for green, then click as fast as you can'
$form.Controls.Add($panel)

# ── Round label ──────────────────────────────────────────────
$lblRound           = New-Object System.Windows.Forms.Label
$lblRound.AutoSize  = $false
$lblRound.Size      = New-Object System.Drawing.Size($panelW, 26)
$lblRound.Location  = New-Object System.Drawing.Point($panelX, $roundY)
$lblRound.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblRound.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
$lblRound.Text      = ''
$form.Controls.Add($lblRound)

# ── Latency info label ───────────────────────────────────────
$actualRes = [uint32]0
[WinApi]::NtQueryTimerResolution([ref]$minRes, [ref]$maxRes, [ref]$actualRes) | Out-Null
$resolvedMs = [math]::Round($actualRes / 10000.0, 2)

$lblInfo           = New-Object System.Windows.Forms.Label
$lblInfo.AutoSize  = $false
$lblInfo.Size      = New-Object System.Drawing.Size($panelW, 20)
$lblInfo.Location  = New-Object System.Drawing.Point($panelX, $infoY)
$lblInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblInfo.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$lblInfo.Font      = New-Object System.Drawing.Font('Segoe UI', 8)
$lblInfo.Text      = "Timer: ${resolvedMs} ms  |  Input: WM_LBUTTONDOWN  |  Priority: High  |  DwmFlush: on"
$form.Controls.Add($lblInfo)

# ── Score listbox ────────────────────────────────────────────
$lstScores             = New-Object System.Windows.Forms.ListBox
$lstScores.Size        = New-Object System.Drawing.Size($panelW, $listH)
$lstScores.Location    = New-Object System.Drawing.Point($panelX, $listY)
$lstScores.BackColor   = [System.Drawing.Color]::FromArgb(45, 45, 45)
$lstScores.ForeColor   = $colLight
$lstScores.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$lstScores.Font        = New-Object System.Drawing.Font('Consolas', 11)
$lstScores.Enabled     = $false
$form.Controls.Add($lstScores)

# ── Reset button ─────────────────────────────────────────────
$btnReset              = New-Object System.Windows.Forms.Button
$btnReset.Size         = New-Object System.Drawing.Size(110, 32)
$btnReset.Location     = New-Object System.Drawing.Point(($formW - $panelX - 110), $btnY)
$btnReset.Text         = 'Reset'
$btnReset.FlatStyle    = [System.Windows.Forms.FlatStyle]::Flat
$btnReset.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnReset.BackColor    = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnReset.ForeColor    = $colLight
$btnReset.Cursor       = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnReset)

# ── Timer ────────────────────────────────────────────────────
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.add_Tick({
    $script:timer.Stop()
    $script:state    = 'green'
    $panel.BackColor = $colGreen
    $panel.MainText  = 'CLICK!'
    $panel.SubText   = ''

    # Synchronous repaint — flush paint queue immediately
    $panel.Refresh()

    # Block until DWM has presented this frame to the monitor,
    # then start the clock.
    [WinApi]::DwmFlush() | Out-Null
    $script:startTime = [System.Diagnostics.Stopwatch]::GetTimestamp()
})

# ── Helpers ──────────────────────────────────────────────────
function Set-StateWaiting {
    $script:state    = 'waiting'
    $panel.BackColor = $colBlue
    $panel.MainText  = 'Click to Start'
    $panel.SubText   = 'Wait for green, then click as fast as you can'
    $lblRound.Text   = ''
    $panel.Refresh()
}

function Set-StateReady {
    $script:state    = 'ready'
    $panel.BackColor = $colRed
    $panel.MainText  = 'Wait for it...'
    $panel.SubText   = "Round $($script:scores.Count + 1) of $script:maxRounds"
    $panel.Refresh()
    $delay = Get-Random -Minimum 1500 -Maximum 5000
    $script:timer.Interval = $delay
    $script:timer.Start()
}

function Register-Score([long]$elapsed) {
    $ms = [math]::Round($elapsed * 1000 / [System.Diagnostics.Stopwatch]::Frequency)
    $script:scores += $ms

    $round  = $script:scores.Count
    $rating = switch ($ms) {
        { $_ -lt 150 }  { 'Superhuman'; break }
        { $_ -lt 200 }  { 'Excellent';  break }
        { $_ -lt 250 }  { 'Great';      break }
        { $_ -lt 300 }  { 'Average';    break }
        { $_ -lt 400 }  { 'Slow';       break }
        default          { 'Very Slow'  }
    }

    $lstScores.Items.Add("  Round $round :  ${ms} ms   [$rating]") | Out-Null

    if ($script:scores.Count -ge $script:maxRounds) {
        Show-Results
    } else {
        $script:state    = 'result'
        $panel.BackColor = $colBlue
        $panel.MainText  = "${ms} ms"
        $panel.SubText   = "Click for next round  ($($script:scores.Count)/$script:maxRounds done)"
        $lblRound.Text   = "Last: ${ms} ms  |  $rating"
        $panel.Refresh()
    }
}

function Show-Results {
    $avg  = [math]::Round(($script:scores | Measure-Object -Average).Average)
    $best = ($script:scores | Measure-Object -Minimum).Minimum

    $script:state    = 'waiting'
    $panel.BackColor = [System.Drawing.Color]::FromArgb(52, 73, 94)
    $panel.MainText  = "Avg: ${avg} ms"
    $panel.SubText   = "Best: ${best} ms  |  Click to play again"
    $lblRound.Text   = "All $script:maxRounds rounds complete!"
    $panel.Refresh()

    $lstScores.Items.Add('') | Out-Null
    $lstScores.Items.Add("  -----------------------------------------") | Out-Null
    $lstScores.Items.Add("  Average : ${avg} ms   |   Best : ${best} ms") | Out-Null

    $script:scores = @()
}

function Invoke-Click {
    switch ($script:state) {
        'waiting' {
            $lstScores.Items.Clear()
            Set-StateReady
        }
        'ready' {
            $script:timer.Stop()
            $script:state    = 'toosoon'
            $panel.BackColor = $colOrange
            $panel.MainText  = 'Too soon!'
            $panel.SubText   = 'Click to try this round again'
            $panel.Refresh()
        }
        'green' {
            $t = [System.Diagnostics.Stopwatch]::GetTimestamp()
            Register-Score ($t - $script:startTime)
        }
        'toosoon' { Set-StateReady }
        'result'  { Set-StateReady }
    }
}

# ── Wire events ──────────────────────────────────────────────
$panel.add_MousePressed({ Invoke-Click })

$btnReset.add_Click({
    $script:timer.Stop()
    $script:scores = @()
    $lstScores.Items.Clear()
    Set-StateWaiting
})

$form.add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -in [System.Windows.Forms.Keys]::Space,
                        [System.Windows.Forms.Keys]::Return) {
        Invoke-Click
    }
})

$form.add_FormClosed({
    $d = [uint32]0
    [WinApi]::NtSetTimerResolution($originalResolution, $true, [ref]$d) | Out-Null
})

# ── Run ───────────────────────────────────────────────────────
[System.Windows.Forms.Application]::Run($form)
