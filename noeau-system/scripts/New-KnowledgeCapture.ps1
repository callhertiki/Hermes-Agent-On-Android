#Requires -Version 7.0
# New-KnowledgeCapture.ps1 — Daily knowledge capture
# Usage:  noeau capture
#         noeau capture python "Decorators deep dive"

param(
    [string]   $Topic   = "",
    [string]   $Title   = "",
    [string]   $Body    = "",
    [string[]] $Tags    = @(),
    [int]      $Minutes = 0
)

$here = $PSScriptRoot
Import-Module (Join-Path $here "modules\NoEau.psm1") -Force

$validTopics = Get-ValidTopics
$config      = Get-NoEauConfig

Write-Host ""
Write-Host "  ┌─ Noʻeau Knowledge Capture ────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │  Drop a note. Build the memory. Keep growing.         │" -ForegroundColor DarkGray
Write-Host "  └───────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# ── Topic ─────────────────────────────────────────────────────────────────────
if (-not $Topic) {
    Write-Host "  Topics: " -NoNewline -ForegroundColor DarkGray
    Write-Host ($validTopics -join "  ·  ") -ForegroundColor White
    $Topic = (Read-Host "  Topic").Trim()
    if (-not $Topic) { $Topic = "research" }
}

# Resolve alias
$t = $Topic.ToLower()
if ($config.topic_aliases.PSObject.Properties.Name -contains $t) { $Topic = $config.topic_aliases.$t }
if ($Topic -notin $validTopics) { $Topic = "research" }

# ── Title ─────────────────────────────────────────────────────────────────────
if (-not $Title) {
    $Title = (Read-Host "  Title").Trim()
    if (-not $Title) { $Title = "Quick Note $(Get-Date -Format 'HH:mm')" }
}

# ── Body ──────────────────────────────────────────────────────────────────────
if (-not $Body) {
    Write-Host "  Notes (blank line to finish):" -ForegroundColor DarkGray
    $lines = [System.Collections.Generic.List[string]]::new()
    while ($true) {
        $line = Read-Host "  "
        if ($line -eq "" -and $lines.Count -gt 0 -and $lines[-1] -eq "") { break }
        $lines.Add($line)
    }
    # Drop the trailing blank
    while ($lines.Count -gt 0 -and $lines[-1] -eq "") { $lines.RemoveAt($lines.Count - 1) }
    $Body = $lines -join "`n"
}

# ── Tags ──────────────────────────────────────────────────────────────────────
if ($Tags.Count -eq 0) {
    $tagInput = (Read-Host "  Tags (comma-separated, optional)").Trim()
    if ($tagInput) {
        $Tags = $tagInput -split ',' |
                ForEach-Object { $_.Trim().ToLower() -replace '\s+', '-' } |
                Where-Object { $_ }
    }
}

# ── Minutes ───────────────────────────────────────────────────────────────────
if ($Minutes -eq 0) {
    $mInput = (Read-Host "  Minutes spent (0 to skip)").Trim()
    if ($mInput -match '^\d+$') { $Minutes = [int]$mInput }
}

# ── Save ──────────────────────────────────────────────────────────────────────
$filepath = New-NoteFile -Topic $Topic -Title $Title -Body $Body -Tags $Tags -Minutes $Minutes

if ($Minutes -gt 0) {
    Add-LearningSession -Topic $Topic -Notes $Title -Minutes $Minutes -Tags $Tags -Source "capture"
}

$streak = Get-StreakInfo

Write-Host ""
Write-Host "  ✓ Saved!" -ForegroundColor Green
Write-Host "    $filepath" -ForegroundColor DarkGray
Write-Host "    Topic: $Topic  |  Tags: $(if($Tags){"$($Tags -join ', ')"}else{'none'})  |  $Minutes min  |  Streak: $($streak.current) days" -ForegroundColor DarkGray
Write-Host ""

# Auto-build memory if configured
if ($config.memory.auto_build_on_capture) {
    Write-Host "  Updating memory graph..." -ForegroundColor DarkGray
    & (Join-Path $here "Build-Memory.ps1") -Quiet
}
