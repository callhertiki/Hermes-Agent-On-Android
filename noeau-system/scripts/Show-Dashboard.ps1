#Requires -Version 7.0
# Show-Dashboard.ps1 — Terminal dashboard
# Usage:  noeau dashboard   (or just:  noeau)

$here = $PSScriptRoot
Import-Module (Join-Path $here "modules\NoEau.psm1") -Force

# ── Drawing helpers ───────────────────────────────────────────────────────────

$W = 66   # inner width (between ║ borders)

function Write-Border { param([string]$L = "╠", [string]$R = "╣", [string]$F = "═")
    Write-Host "$L$($F * $W)$R" -ForegroundColor DarkGray }

function Write-Row {
    param([string]$Text = "", [string]$Color = "White", [bool]$Center = $false)
    $text = if ($Center) {
        $pad = [Math]::Max(0, ($W - 2 - $Text.Length) / 2)
        " " * [int]$pad + $Text + " " * [int][Math]::Ceiling($pad)
    } else {
        " $Text" + (" " * [Math]::Max(0, $W - 1 - $Text.Length))
    }
    Write-Host "║" -NoNewline -ForegroundColor DarkGray
    Write-Host $text -NoNewline -ForegroundColor $Color
    Write-Host "║" -ForegroundColor DarkGray
}

function Get-Bar {
    param([int]$Value, [int]$Max, [int]$Width = 18)
    if ($Max -le 0) { $Max = 1 }
    $filled = [Math]::Round([Math]::Min($Value, $Max) / $Max * $Width)
    return ("█" * $filled) + ("░" * ($Width - $filled))
}

# ── Data ─────────────────────────────────────────────────────────────────────

$config      = Get-NoEauConfig
$today       = Get-Date
$todayStr    = $today.ToString("yyyy-MM-dd")
$dateDisplay = $today.ToString("dddd, MMMM d, yyyy")

$streak      = Get-StreakInfo
$todayMin    = Get-TodayMinutes
$goalMin     = [int]$config.goals.daily_learning_minutes
$captures    = @(Get-TodaysCaptures)
$topicStats  = Get-TopicStats -Days 7
$weekFrom    = Get-WeekStart
$weekCaptures= @(Get-CapturesByDateRange -From $weekFrom -To $todayStr)
$weekTarget  = [int]$config.goals.weekly_notes_target
$mem         = Get-NoEauMemory
$memCount    = ($mem.concepts.PSObject.Properties | Measure-Object).Count

Clear-Host

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host "╔$("═" * $W)╗" -ForegroundColor DarkGray
Write-Row "NOʻEAU KNOWLEDGE SYSTEM  ·  Daily Dashboard" "Cyan" $true
Write-Row $dateDisplay "White" $true
Write-Border

# ── Stats bar ─────────────────────────────────────────────────────────────────
$streakEmoji = if ($streak.current -ge 14) { "🔥🔥" } elseif ($streak.current -ge 7) { "🔥" } elseif ($streak.current -ge 3) { "⚡" } else { "📅" }
Write-Row "$streakEmoji  Streak: $($streak.current) days   |   📝 Notes today: $($captures.Count)   |   ⏱ $todayMin / $goalMin min" "Yellow"
Write-Row "   Memory: $memCount concepts   |   Week notes: $($weekCaptures.Count) / $weekTarget" "DarkGray"
Write-Border

# ── Topic distribution ─────────────────────────────────────────────────────────
Write-Row " TOPIC ACTIVITY  (last 7 days)" "Cyan"
Write-Row ""
if ($topicStats.Count -gt 0) {
    $maxCount = ($topicStats.Values | ForEach-Object { $_.count } | Measure-Object -Maximum).Maximum
    foreach ($entry in ($topicStats.GetEnumerator() | Sort-Object { $_.Value.count } -Descending)) {
        $label = $entry.Key.PadRight(22)
        $bar   = Get-Bar -Value $entry.Value.count -Max $maxCount -Width 18
        $info  = "$($entry.Value.count) sessions · $($entry.Value.minutes) min"
        Write-Row " $label  $bar  $info" "White"
    }
} else {
    Write-Row "  No activity yet — run:  noeau capture" "DarkGray"
}
Write-Border

# ── Recent captures ────────────────────────────────────────────────────────────
Write-Row " RECENT CAPTURES" "Cyan"
Write-Row ""
$recent = @(Get-CapturesByDateRange -From ((Get-Date).AddDays(-3).ToString("yyyy-MM-dd")) -To $todayStr)
$shown  = $recent | Sort-Object LastWriteTime -Descending | Select-Object -First 5
if ($shown) {
    foreach ($f in $shown) {
        $topicTag = Split-Path (Split-Path $f.FullName) -Leaf
        $name     = $f.BaseName -replace "^\d{4}-\d{2}-\d{2}-", "" -replace "-", " "
        $when     = if ($f.LastWriteTime.Date -eq $today.Date) {
                        "today $($f.LastWriteTime.ToString('HH:mm'))"
                    } else { $f.LastWriteTime.ToString("MM/dd") }
        $line = " [$topicTag]  $name  —  $when"
        if ($line.Length -gt $W - 1) { $line = $line.Substring(0, $W - 4) + "..." }
        Write-Row $line "White"
    }
} else {
    Write-Row "  No captures yet today. Run:  noeau capture" "DarkGray"
}
Write-Border

# ── Goals ─────────────────────────────────────────────────────────────────────
Write-Row " GOALS" "Cyan"
Write-Row ""

$pct     = [Math]::Min(100, [int](($todayMin / [Math]::Max($goalMin, 1)) * 100))
$bar     = Get-Bar -Value $todayMin -Max $goalMin -Width 22
$goalCol = if ($pct -ge 100) { "Green" } else { "White" }
Write-Row " Daily learning  $bar  $todayMin/$goalMin min  ($pct%)" $goalCol

$wBar    = Get-Bar -Value $weekCaptures.Count -Max $weekTarget -Width 22
$wCol    = if ($weekCaptures.Count -ge $weekTarget) { "Green" } else { "White" }
Write-Row " Weekly notes    $wBar  $($weekCaptures.Count)/$weekTarget" $wCol

Write-Border

# ── Footer ─────────────────────────────────────────────────────────────────────
Write-Row "  capture  ·  add  ·  process  ·  watch  ·  report daily  ·  memory build" "DarkGray"
Write-Host "╚$("═" * $W)╝" -ForegroundColor DarkGray
Write-Host ""
