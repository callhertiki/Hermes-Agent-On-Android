#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Noʻeau Knowledge System — Main CLI

.DESCRIPTION
    Located at:  C:\No'eau\noeau.ps1

    APOSTROPHE FIX:
    All paths that contain "No'eau" MUST use double-quoted strings.
        BAD  : $Base = 'C:\No'eau'     <- PowerShell sees 'C:\No' then orphan token
        GOOD : $Base = "C:\No'eau"     <- apostrophe is just a character inside "..."

.EXAMPLE
    # Navigate to the folder first (apostrophe needs quotes here too):
    Set-Location "C:\No'eau"
    pwsh -NoProfile -ExecutionPolicy Bypass -File ".\noeau.ps1"

    # Or from anywhere:
    pwsh -NoProfile -ExecutionPolicy Bypass -File "C:\No'eau\noeau.ps1"

    # Available commands:
    pwsh -File "C:\No'eau\noeau.ps1" status
    pwsh -File "C:\No'eau\noeau.ps1" dashboard
    pwsh -File "C:\No'eau\noeau.ps1" report
    pwsh -File "C:\No'eau\noeau.ps1" search "keyword"
#>

param(
    [Parameter(Position = 0)][string]$Command  = "dashboard",
    [Parameter(Position = 1)][string]$Arg1     = "",
    [Parameter(Position = 2)][string]$Arg2     = "",
    [switch]$Help
)

# ══════════════════════════════════════════════════════════════════════════════
#  PATH CONSTANTS  —  ALL double-quoted because the folder name contains '
# ══════════════════════════════════════════════════════════════════════════════

$Base      = "C:\No'eau"
$Scripts   = Join-Path $Base "scripts"
$Knowledge = Join-Path $Base "knowledge"
$Reports   = Join-Path $Base "reports"
$Dashboard = Join-Path $Base "dashboard"
$Skills    = Join-Path $Base "skills"
$Logs      = Join-Path $Base "logs"
$Config    = Join-Path $Base "config"
$Inbox     = Join-Path $Base "inbox"
$Research  = Join-Path $Base "research"

# Ensure Logs folder exists before we try to write to it
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

# ══════════════════════════════════════════════════════════════════════════════
#  COLOUR HELPERS
# ══════════════════════════════════════════════════════════════════════════════

function Write-Colour {
    param([string]$Text, [string]$Colour = "White", [switch]$NoNewline)
    if ($NoNewline) { Write-Host $Text -ForegroundColor $Colour -NoNewline }
    else            { Write-Host $Text -ForegroundColor $Colour }
}

function Write-Banner {
    $w = 64
    $top    = "╔" + ("═" * $w) + "╗"
    $bot    = "╚" + ("═" * $w) + "╝"
    $div    = "╠" + ("═" * $w) + "╣"
    $blank  = "║" + (" " * $w) + "║"

    function Pad([string]$s, [int]$width) {
        $pad = [Math]::Max(0, $width - $s.Length)
        $l   = [int]($pad / 2)
        $r   = $pad - $l
        return (" " * $l) + $s + (" " * $r)
    }

    function Row([string]$s, [string]$c = "White") {
        Write-Colour "║" "DarkGray" -NoNewline
        Write-Colour (Pad $s $w) $c -NoNewline
        Write-Colour "║" "DarkGray"
    }

    Write-Colour $top  "DarkGray"
    Row "NOʻEAU KNOWLEDGE SYSTEM" "Cyan"
    Row "Personal Knowledge & Learning Dashboard" "DarkGray"
    Write-Colour $div  "DarkGray"
    Row "PowerShell $($PSVersionTable.PSVersion)  ·  $([System.Environment]::OSVersion.Platform)" "DarkGray"
    Row (Get-Date -Format "dddd, MMMM d, yyyy  HH:mm") "White"
    Write-Colour $div  "DarkGray"

    # Path status rows
    $paths = [ordered]@{
        "Base"      = $Base
        "Dashboard" = $Dashboard
        "Reports"   = $Reports
        "Skills"    = $Skills
        "Logs"      = $Logs
        "Scripts"   = $Scripts
        "Config"    = $Config
        "Inbox"     = $Inbox
    }

    foreach ($key in $paths.Keys) {
        $val    = $paths[$key]
        $exists = Test-Path $val
        $status = if ($exists) { "✓" } else { "✗ MISSING" }
        $colour = if ($exists) { "Green" } else { "Red" }
        $line   = ("  " + $key.PadRight(12) + $val).PadRight($w - 4)
        Write-Colour "║  " "DarkGray" -NoNewline
        Write-Colour $status $colour -NoNewline
        Write-Colour "  $($key.PadRight(12))" "DarkGray" -NoNewline
        $short = if ($val.Length -gt $w - 20) { "..." + $val.Substring($val.Length - ($w - 20)) } else { $val }
        Write-Colour $short "White" -NoNewline
        Write-Colour (" " * [Math]::Max(0, $w - 18 - $short.Length)) "White" -NoNewline
        Write-Colour "║" "DarkGray"
    }

    Write-Colour $div  "DarkGray"
    Row "  noeau status · report · search · skills · help" "DarkGray"
    Write-Colour $bot  "DarkGray"
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

function Write-Log {
    param([string]$Msg, [string]$Level = "INFO")
    $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [$Level] $Msg"
    $logFile = Join-Path $Logs "noeau.log"
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

# ══════════════════════════════════════════════════════════════════════════════
#  VERIFICATION
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-VerifyInstall {
    Write-Host ""
    Write-Colour "  Noʻeau — Installation Check" "Cyan"
    Write-Colour "  " + ("─" * 50) "DarkGray"
    Write-Host ""

    $checks = [ordered]@{
        "Base folder"        = $Base
        "scripts\"           = $Scripts
        "knowledge\"         = $Knowledge
        "reports\"           = $Reports
        "dashboard\"         = $Dashboard
        "skills\"            = $Skills
        "logs\"              = $Logs
        "config\"            = $Config
        "inbox\"             = $Inbox
        "research\"          = $Research
        "noeau.ps1"          = Join-Path $Base "noeau.ps1"
        "RUN_NOEAU.md"       = Join-Path $Base "RUN_NOEAU.md"
    }

    $ok      = 0
    $missing = 0

    foreach ($label in $checks.Keys) {
        $path   = $checks[$label]
        $exists = Test-Path $path
        if ($exists) {
            Write-Colour "    ✓  $label" "Green"
            $ok++
        } else {
            Write-Colour "    ✗  $label  (not found: $path)" "Red"
            $missing++
        }
    }

    Write-Host ""
    if ($missing -eq 0) {
        Write-Colour "  All $ok paths verified. ✓" "Green"
    } else {
        Write-Colour "  $ok found, $missing missing." "Yellow"
        Write-Colour "  Run Install-NoEau.ps1 or create the missing folders." "Yellow"
    }
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  QUICK STATUS
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-Status {
    $trackerPath = Join-Path $Config "learning_tracker.json"
    $memoryPath  = Join-Path $Config "memory.json"

    Write-Host ""
    Write-Colour "  Noʻeau — System Status" "Cyan"
    Write-Host ""

    # Count notes per topic
    if (Test-Path $Knowledge) {
        $topics = Get-ChildItem $Knowledge -Directory
        foreach ($t in $topics) {
            $count = @(Get-ChildItem $t.FullName -Filter "*.md" -Recurse).Count
            $line  = ("    " + $t.Name).PadRight(28) + "$count notes"
            Write-Colour $line "White"
        }
    }

    # Sessions from tracker
    if (Test-Path $trackerPath) {
        try {
            $tracker  = Get-Content $trackerPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $sessions = @($tracker.sessions)
            $today    = (Get-Date).ToString("yyyy-MM-dd")
            $todayMin = ($sessions | Where-Object { $_.date -eq $today } |
                         Measure-Object -Property duration_minutes -Sum).Sum
            Write-Host ""
            Write-Colour "    Total sessions : $($sessions.Count)" "DarkGray"
            Write-Colour "    Today (min)    : $todayMin" "DarkGray"
        } catch { }
    }

    # Inbox count
    if (Test-Path $Inbox) {
        $inboxItems = @(Get-ChildItem $Inbox -File).Count
        Write-Colour "    Inbox items    : $inboxItems" $(if ($inboxItems -gt 0) { "Yellow" } else { "DarkGray" })
    }

    # PDF count
    $pdfsDir = Join-Path $Research "PDFs"
    if (Test-Path $pdfsDir) {
        $pdfCount = @(Get-ChildItem $pdfsDir -Filter "*.pdf").Count
        Write-Colour "    PDFs archived  : $pdfCount" "DarkGray"
    }

    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  REPORT
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-Report {
    param([string]$Type = "daily")
    $today = (Get-Date).ToString("yyyy-MM-dd")

    switch ($Type.ToLower()) {
        "daily" {
            $outDir = Join-Path $Reports "daily"
            if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
            $outFile = Join-Path $outDir "$today.md"

            # Gather notes modified today
            $todayNotes = @()
            if (Test-Path $Knowledge) {
                $todayNotes = Get-ChildItem $Knowledge -Filter "*.md" -Recurse |
                    Where-Object { $_.LastWriteTime.ToString("yyyy-MM-dd") -eq $today }
            }

            $content = @"
# Daily Report — $today

> *$(Get-Date -Format "dddd, MMMM d, yyyy")*

## Notes Modified Today

$(if ($todayNotes.Count -gt 0) {
    ($todayNotes | ForEach-Object {
        "- **[$($_.Directory.Name)]** $($_.BaseName)  ``$($_.FullName)``"
    }) -join "`n"
} else { "_No notes modified today._" })

## Inbox

$(
    if (Test-Path $Inbox) {
        $items = @(Get-ChildItem $Inbox -File)
        if ($items.Count -gt 0) { ($items | ForEach-Object { "- ``$($_.Name)``" }) -join "`n" }
        else { "_Inbox is empty._" }
    } else { "_Inbox folder not found._" }
)

---
*Generated by Noʻeau Knowledge System — $(Get-Date -Format "yyyy-MM-dd HH:mm")*
"@
            Set-Content $outFile -Value $content -Encoding UTF8
            Write-Colour "  ✓ Report saved: $outFile" "Green"
            Write-Log "Daily report generated: $outFile"
        }
        default {
            Write-Colour "  Unknown report type: $Type  (use: daily)" "Yellow"
        }
    }
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  SEARCH
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-Search {
    param([string]$Keyword, [string]$Topic = "")

    if (-not $Keyword) {
        Write-Colour "  Usage: noeau search `"keyword`"" "Yellow"
        return
    }

    $searchRoot = if ($Topic) { Join-Path $Knowledge $Topic } else { $Base }

    if (-not (Test-Path $searchRoot)) {
        Write-Colour "  Search root not found: $searchRoot" "Red"
        return
    }

    $pattern = [regex]::new([regex]::Escape($Keyword), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $hits    = 0

    Write-Host ""
    Write-Colour "  Searching for: '$Keyword'" "Cyan"
    Write-Colour "  In: $searchRoot" "DarkGray"
    Write-Host ""

    Get-ChildItem $searchRoot -Include "*.md","*.txt" -Recurse | ForEach-Object {
        $file    = $_
        $lines   = Get-Content $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++
            if ($pattern.IsMatch($line)) {
                if ($hits -eq 0 -or $lastFile -ne $file.FullName) {
                    Write-Colour "  $($file.FullName)" "Yellow"
                    $script:lastFile = $file.FullName
                }
                Write-Colour "    $($lineNum.ToString().PadLeft(5))  $($line.Trim())" "White"
                $hits++
            }
        }
    }

    Write-Host ""
    Write-Colour "  $hits match(es) found." $(if ($hits -gt 0) { "Green" } else { "DarkGray" })
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  HELP
# ══════════════════════════════════════════════════════════════════════════════

function Show-Help {
    Write-Host ""
    Write-Colour "  Noʻeau Knowledge System — Commands" "Cyan"
    Write-Colour "  ──────────────────────────────────────────────────────────" "DarkGray"
    Write-Colour "  (no args)           Show dashboard + banner"         "White"
    Write-Colour "  dashboard           Same as above"                   "White"
    Write-Colour "  status              Note counts, inbox, session info" "White"
    Write-Colour "  verify              Check all paths exist"            "White"
    Write-Colour "  report              Generate today's daily report"    "White"
    Write-Colour "  search <keyword>    Full-text search inside Noeau"    "White"
    Write-Colour "  open <location>     Open a folder in Explorer"        "White"
    Write-Colour "    locations: base dashboard reports knowledge skills logs inbox" "DarkGray"
    Write-Colour "  help                Show this message"                "White"
    Write-Host ""
    Write-Colour "  LAUNCH COMMAND (from any PowerShell):" "Yellow"
    Write-Colour "  pwsh -NoProfile -ExecutionPolicy Bypass -File `"C:\No'eau\noeau.ps1`"" "White"
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  OPEN IN EXPLORER
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-Open {
    param([string]$Location)
    $target = switch ($Location.ToLower()) {
        "base"       { $Base      }
        "dashboard"  { $Dashboard }
        "reports"    { $Reports   }
        "knowledge"  { $Knowledge }
        "skills"     { $Skills    }
        "logs"       { $Logs      }
        "inbox"      { $Inbox     }
        "config"     { $Config    }
        "research"   { $Research  }
        default      { $Base      }
    }
    if (Test-Path $target) {
        Start-Process "explorer.exe" "`"$target`""
    } else {
        Write-Colour "  Folder not found: $target" "Red"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

Write-Log "noeau.ps1 started — command: $Command"

if ($Help) { Show-Help; exit 0 }

switch ($Command.ToLower()) {

    { $_ -in @("dashboard", "") } {
        Write-Banner
        Invoke-Status
    }

    "status" {
        Write-Colour ""
        Invoke-Status
    }

    "verify" {
        Invoke-VerifyInstall
    }

    "report" {
        $type = if ($Arg1) { $Arg1 } else { "daily" }
        Invoke-Report -Type $type
    }

    "search" {
        Invoke-Search -Keyword $Arg1 -Topic $Arg2
    }

    "open" {
        Invoke-Open -Location $Arg1
    }

    "help" {
        Show-Help
    }

    default {
        Write-Colour "  Unknown command: '$Command'  — run  noeau help  for usage." "Yellow"
        exit 1
    }
}

Write-Log "noeau.ps1 completed — command: $Command"
