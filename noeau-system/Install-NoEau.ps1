#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Noʻeau Knowledge System v1 — Installer

.DESCRIPTION
    Run this once from PowerShell 7 on your Surface Pro.
    It will:
      1. Create the full C:\Noeau folder structure
      2. Copy all scripts to C:\Noeau\scripts\
      3. Check for Python 3 and install pdfplumber
      4. Add C:\Noeau\scripts to your user PATH
      5. Register the  noeau  command (noeau.cmd wrapper)
      6. Create scheduled tasks for auto daily/weekly reports
      7. Write initial config and empty data files

.NOTES
    Run from the folder containing this installer:
      cd C:\path\to\noeau-system
      pwsh -ExecutionPolicy Bypass -File .\Install-NoEau.ps1
#>

Set-StrictMode -Version Latest

$NoEauRoot  = "C:\Noeau"
$ScriptsSrc = Join-Path $PSScriptRoot "scripts"
$ConfigSrc  = Join-Path $PSScriptRoot "config"

# ── Colours ────────────────────────────────────────────────────────────────────
function Write-Step  { param([string]$Msg) Write-Host "`n  ► $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "    ✓ $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "    ⚠ $Msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Msg) Write-Host "    ✗ $Msg" -ForegroundColor Red }

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║        NOʻEAU KNOWLEDGE SYSTEM v1  —  Installer         ║" -ForegroundColor Cyan
Write-Host "  ║             Surface Pro  ·  Windows + PowerShell 7      ║" -ForegroundColor DarkGray
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Verify source files ────────────────────────────────────────────────
Write-Step "Verifying source files..."
$requiredSrc = @(
    "scripts\modules\NoEau.psm1",
    "scripts\noeau.ps1",
    "scripts\noeau.cmd",
    "scripts\New-KnowledgeCapture.ps1",
    "scripts\Invoke-InboxWatch.ps1",
    "scripts\Update-LearningTracker.ps1",
    "scripts\Show-Dashboard.ps1",
    "scripts\New-DailyReport.ps1",
    "scripts\New-WeeklyReport.ps1",
    "scripts\New-MonthlyReport.ps1",
    "scripts\Build-Memory.ps1",
    "scripts\pdf_processor.py",
    "scripts\requirements.txt",
    "config\preferences.json"
)
$missing = $requiredSrc | Where-Object { -not (Test-Path (Join-Path $PSScriptRoot $_)) }
if ($missing) {
    Write-Fail "Missing files:"
    $missing | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
    Write-Host "`n  Make sure you are running this from the noeau-system folder.`n"
    exit 1
}
Write-Ok "All source files present."

# ── Step 2: Create folder structure ───────────────────────────────────────────
Write-Step "Creating folder structure at $NoEauRoot ..."
$folders = @(
    "inbox",
    "knowledge\python",
    "knowledge\linux",
    "knowledge\networking",
    "knowledge\cybersecurity",
    "knowledge\osint",
    "knowledge\research",
    "knowledge\personal-development",
    "knowledge\lds-studies",
    "research\PDFs",
    "research\summaries",
    "reports\daily",
    "reports\weekly",
    "reports\monthly",
    "dashboard",
    "config",
    "scripts\modules"
)
foreach ($f in $folders) {
    $p = Join-Path $NoEauRoot $f
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}
Write-Ok "Folder structure ready."

# ── Step 3: Copy scripts ───────────────────────────────────────────────────────
Write-Step "Copying scripts to $NoEauRoot\scripts\ ..."
Copy-Item -Path (Join-Path $ScriptsSrc "*") -Destination (Join-Path $NoEauRoot "scripts") -Recurse -Force
Write-Ok "Scripts copied."

# ── Step 4: Copy / initialise config ──────────────────────────────────────────
Write-Step "Setting up config..."
$destConfig = Join-Path $NoEauRoot "config\preferences.json"
if (-not (Test-Path $destConfig)) {
    Copy-Item (Join-Path $ConfigSrc "preferences.json") $destConfig
    Write-Ok "preferences.json installed."
} else {
    Write-Warn "preferences.json already exists — not overwriting. Edit manually if needed."
}

# Initialise empty learning tracker if absent
$trackerPath = Join-Path $NoEauRoot "config\learning_tracker.json"
if (-not (Test-Path $trackerPath)) {
    @{
        version  = "1.0"
        sessions = @()
        goals    = @{ daily_minutes = 60 }
        streaks  = @{ current = 0; longest = 0; last_active = "" }
    } | ConvertTo-Json -Depth 5 | Set-Content $trackerPath -Encoding UTF8
    Write-Ok "learning_tracker.json initialised."
}

# Initialise empty memory
$memPath = Join-Path $NoEauRoot "config\memory.json"
if (-not (Test-Path $memPath)) {
    @{
        version     = "1.0"
        last_built  = ""
        notes_scanned = 0
        concepts    = @{}
        connections = @()
    } | ConvertTo-Json -Depth 5 | Set-Content $memPath -Encoding UTF8
    Write-Ok "memory.json initialised."
}

# ── Step 5: Python & pdfplumber ────────────────────────────────────────────────
Write-Step "Checking Python..."
$pyCmd = $null
foreach ($candidate in @("python", "python3", "py")) {
    try {
        $ver = & $candidate --version 2>&1
        if ($ver -match "Python 3") { $pyCmd = $candidate; break }
    } catch {}
}

if ($pyCmd) {
    Write-Ok "Found: $(& $pyCmd --version 2>&1)"
    Write-Host "    Installing Python dependencies..." -ForegroundColor DarkGray
    $reqFile = Join-Path $NoEauRoot "scripts\requirements.txt"
    & $pyCmd -m pip install -r $reqFile --quiet 2>&1 | Out-Null
    Write-Ok "pdfplumber installed."
} else {
    Write-Warn "Python 3 not found. PDF processing will be skipped until Python is installed."
    Write-Host "    → Install from https://www.python.org/downloads/" -ForegroundColor DarkGray
    Write-Host "    → Then run:  pip install pdfplumber" -ForegroundColor DarkGray
}

# ── Step 6: PATH ──────────────────────────────────────────────────────────────
Write-Step "Adding C:\Noeau\scripts to user PATH..."
$scriptsDir = "$NoEauRoot\scripts"
$userPath   = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$scriptsDir*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$scriptsDir", "User")
    Write-Ok "PATH updated. Restart your terminal for it to take effect."
} else {
    Write-Ok "Already in PATH."
}

# ── Step 7: PowerShell profile alias ─────────────────────────────────────────
Write-Step "Adding 'noeau' alias to PowerShell profile..."
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}
$aliasLine = "Set-Alias noeau `"$NoEauRoot\scripts\noeau.ps1`""
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*noeau*") {
    Add-Content $profilePath -Value "`n# Noʻeau Knowledge System`n$aliasLine"
    Write-Ok "Alias added to profile."
} else {
    Write-Ok "Alias already in profile."
}

# ── Step 8: Scheduled tasks ────────────────────────────────────────────────────
Write-Step "Registering scheduled tasks..."

function Register-NoEauTask {
    param([string]$Name, [string]$Script, [string]$TriggerDesc, $Trigger)
    $action  = New-ScheduledTaskAction `
                  -Execute "pwsh.exe" `
                  -Argument "-NonInteractive -NoProfile -File `"$Script`""
    $settings = New-ScheduledTaskSettingsSet `
                  -StartWhenAvailable `
                  -DontStopOnIdleEnd `
                  -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    try {
        Register-ScheduledTask -TaskName $Name -Action $action `
            -Trigger $Trigger -Settings $settings `
            -Description "Noʻeau Knowledge System: $TriggerDesc" `
            -Force -RunLevel Limited | Out-Null
        Write-Ok "$Name scheduled."
    } catch {
        Write-Warn "$Name — could not register: $($_.Exception.Message)"
        Write-Host "    (Try running the installer as Administrator if scheduling fails)" -ForegroundColor DarkGray
    }
}

$dailyScript   = Join-Path $NoEauRoot "scripts\New-DailyReport.ps1"
$weeklyScript  = Join-Path $NoEauRoot "scripts\New-WeeklyReport.ps1"
$monthlyScript = Join-Path $NoEauRoot "scripts\New-MonthlyReport.ps1"

Register-NoEauTask `
    -Name        "NoEau-DailyReport" `
    -Script      $dailyScript `
    -TriggerDesc "Daily report at 9 PM" `
    -Trigger     (New-ScheduledTaskTrigger -Daily -At "21:00")

Register-NoEauTask `
    -Name        "NoEau-WeeklyReport" `
    -Script      $weeklyScript `
    -TriggerDesc "Weekly report on Sunday at 8 PM" `
    -Trigger     (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "20:00")

Register-NoEauTask `
    -Name        "NoEau-MonthlyReport" `
    -Script      $monthlyScript `
    -TriggerDesc "Monthly report on the 1st at 7 PM" `
    -Trigger     (New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "19:00")

# ── Step 9: Done ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║       ✓  Noʻeau Knowledge System installed!              ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  FIRST STEPS" -ForegroundColor Cyan
Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  1. Open a new PowerShell 7 terminal (to load PATH + alias)"
Write-Host "  2. Edit your name in:  C:\Noeau\config\preferences.json"
Write-Host ""
Write-Host "  DAILY COMMANDS" -ForegroundColor Cyan
Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  noeau                        → Dashboard"
Write-Host "  noeau capture                → Write a note (prompts you)"
Write-Host "  noeau capture python         → Note for a specific topic"
Write-Host "  noeau add linux 30           → Log 30 min of Linux study"
Write-Host "  noeau process                → Move files from inbox\"
Write-Host "  noeau watch                  → Live-watch inbox (stays open)"
Write-Host "  noeau report daily           → Today's report"
Write-Host "  noeau report weekly          → This week's report"
Write-Host "  noeau report monthly         → This month's report"
Write-Host "  noeau memory build           → Rebuild knowledge graph"
Write-Host "  noeau open inbox             → Open inbox in Explorer"
Write-Host ""
Write-Host "  OBSIDIAN TIP" -ForegroundColor Cyan
Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Add C:\Noeau\knowledge as an Obsidian vault for graph view."
Write-Host ""
Write-Host "  DROP PDFs INTO:" -ForegroundColor Cyan
Write-Host "  C:\Noeau\inbox\  →  run 'noeau process'  →  auto-summarised" -ForegroundColor White
Write-Host ""
