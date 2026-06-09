#Requires -Version 7.0
# Update-LearningTracker.ps1 — Log a learning session
# Usage:  noeau add python 45
#         noeau add linux

param(
    [string]   $Topic   = "",
    [int]      $Minutes = 0,
    [string]   $Notes   = "",
    [string[]] $Tags    = @()
)

$here = $PSScriptRoot
Import-Module (Join-Path $here "modules\NoEau.psm1") -Force

$validTopics = Get-ValidTopics
$config      = Get-NoEauConfig

Write-Host ""
Write-Host "  ── Learning Tracker ─────────────────────────────────────" -ForegroundColor Cyan

# Topic
if (-not $Topic) {
    Write-Host "  Topics: $($validTopics -join '  ·  ')" -ForegroundColor DarkGray
    $Topic = (Read-Host "  Topic").Trim()
    if (-not $Topic) { $Topic = "research" }
}
$t = $Topic.ToLower()
if ($config.topic_aliases.PSObject.Properties.Name -contains $t) { $Topic = $config.topic_aliases.$t }
if ($Topic -notin $validTopics) { $Topic = "research" }

# Minutes
if ($Minutes -eq 0) {
    $mInput = (Read-Host "  Minutes spent").Trim()
    if ($mInput -match '^\d+$') { $Minutes = [int]$mInput }
}

# Notes
if (-not $Notes) {
    $Notes = (Read-Host "  Brief description (optional)").Trim()
}

# Tags
if ($Tags.Count -eq 0) {
    $tInput = (Read-Host "  Tags (optional, comma-separated)").Trim()
    if ($tInput) {
        $Tags = $tInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
}

Add-LearningSession -Topic $Topic -Notes $Notes -Minutes $Minutes -Tags $Tags

$streak   = Get-StreakInfo
$todayMin = Get-TodayMinutes
$goalMin  = $config.goals.daily_learning_minutes
$pct      = [Math]::Min(100, [int](($todayMin / [Math]::Max($goalMin, 1)) * 100))

Write-Host ""
Write-Host "  ✓ Session logged" -ForegroundColor Green
Write-Host "    Topic: $Topic  |  Minutes: $Minutes  |  Streak: $($streak.current) days" -ForegroundColor DarkGray
Write-Host "    Today total: $todayMin / $goalMin min  ($pct%)" -ForegroundColor DarkGray
Write-Host ""
