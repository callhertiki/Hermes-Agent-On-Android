# ============================================================
# run-noeau-agent.ps1
# Noʻeau OS — Manual Agent Runner (Version 2)
# Supports all 8 automation agents
# For Windows 10/11 (Lenovo Yoga 7 or any Windows machine)
#
# PREVIOUS VERSION backed up to:
#   07-Automations/Archive/run-noeau-agent-v1-backup-2025-06-09.ps1
#
# HOW TO RUN THIS SCRIPT:
#   Step 1 — Open PowerShell
#             Press Win + X → click "Windows PowerShell"
#             OR search "PowerShell" in the Start menu
#
#   Step 2 — Allow scripts to run (ONE TIME ONLY — run as Administrator):
#             Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
#   Step 3 — Navigate to your vault folder:
#             cd "C:\Users\YourName\Documents\YourVaultFolderName"
#             (Replace with your actual vault path)
#
#   Step 4 — Run the script:
#             .\07-Automations\Scripts\run-noeau-agent.ps1
#
# WHAT THIS SCRIPT DOES:
#   - Shows a menu of 8 available agents
#   - Lets you pick one
#   - Opens the matching prompt file in Notepad
#   - Adds a timestamped entry to the matching log file
#   - Creates the output file if it doesn't exist yet
#   - Opens the output file ready for you to paste the AI response
#   - NEVER deletes or overwrites any file
#   - Keeps everything in the vault — nothing is sent externally
# ============================================================


# ── CONFIGURATION ───────────────────────────────────────────
# The script figures out the vault root automatically from where it lives.
# If something goes wrong, you can set the path manually here.
#
# Automatic detection (recommended — works if script is inside the vault):
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$AutomationsFolder = Split-Path -Parent $ScriptDir
$VaultRoot   = Split-Path -Parent $AutomationsFolder

# Manual override (uncomment and edit this line if auto-detection fails):
# $VaultRoot = "C:\Users\YourName\Documents\YourVaultName"

# Build paths to each subfolder
$PromptsFolder = Join-Path $AutomationsFolder "Prompts"
$LogsFolder    = Join-Path $AutomationsFolder "Logs"
$OutputsFolder = Join-Path $AutomationsFolder "Outputs"
$ArchiveFolder = Join-Path $AutomationsFolder "Archive"


# ── AGENT DEFINITIONS ───────────────────────────────────────
# Each agent has a number, name, label, description, and timing guidance.
# To add a new agent later, add a new entry to this list.
# The Name field must match the prefix of the prompt/log/output filenames.
$Agents = @(
    [PSCustomObject]@{
        Number      = "1"
        Name        = "accountability-check"
        Label       = "Accountability Check"
        Description = "Compares your plan to what you're actually doing. Gives one verdict."
        When        = "Every 30 minutes during work sessions"
        OutputName  = "accountability-check-output"
        LogName     = "accountability-check-log"
        PromptName  = "accountability-check-prompt"
    },
    [PSCustomObject]@{
        Number      = "2"
        Name        = "executive-coach"
        Label       = "Executive Coach"
        Description = "Reviews your goals, picks top priority, gives 3 specific next actions."
        When        = "Every 3 hours during work sessions"
        OutputName  = "executive-coach-output"
        LogName     = "executive-coach-log"
        PromptName  = "executive-coach-prompt"
    },
    [PSCustomObject]@{
        Number      = "3"
        Name        = "learning-coach"
        Label       = "Learning Coach"
        Description = "Quizzes you on what you just studied. Tests real understanding."
        When        = "After every study session"
        OutputName  = "learning-coach-output"
        LogName     = "learning-coach-log"
        PromptName  = "learning-coach-prompt"
    },
    [PSCustomObject]@{
        Number      = "4"
        Name        = "reflection-agent"
        Label       = "Reflection Agent"
        Description = "End-of-day review: what you learned, avoided, and tomorrow's first move."
        When        = "Evening — end of each day"
        OutputName  = "reflection-agent-output"
        LogName     = "reflection-agent-log"
        PromptName  = "reflection-agent-prompt"
    },
    [PSCustomObject]@{
        Number      = "5"
        Name        = "source-monitor"
        Label       = "Source Monitor"
        Description = "Reviews research queue, summarizes sources, creates Discord-ready notes."
        When        = "Every 8 hours — or once per work day"
        OutputName  = "source-monitor-output"
        LogName     = "source-monitor-log"
        PromptName  = "source-monitor-prompt"
    },
    [PSCustomObject]@{
        Number      = "6"
        Name        = "task-renewer"
        Label       = "Task Renewer"
        Description = "Reviews stale tasks from daily notes. Carry forward or archive."
        When        = "Every 2 days"
        OutputName  = "task-renewer-output"
        LogName     = "task-renewer-log"
        PromptName  = "task-renewer-prompt"
    },
    [PSCustomObject]@{
        Number      = "7"
        Name        = "guardian-check"
        Label       = "Guardian Check"
        Description = "Audits backup status, security habits, and vault health."
        When        = "Once daily — recommended at morning start"
        OutputName  = "guardian-check-output"
        LogName     = "guardian-check-log"
        PromptName  = "guardian-check-prompt"
    },
    [PSCustomObject]@{
        Number      = "8"
        Name        = "scribe-cleanup"
        Label       = "Scribe Cleanup"
        Description = "Formats rough notes into clean Obsidian notes and Discord summaries."
        When        = "Daily — when inbox has raw notes to process"
        OutputName  = "scribe-cleanup-output"
        LogName     = "scribe-cleanup-log"
        PromptName  = "scribe-cleanup-prompt"
    }
)


# ── HELPER: Print a colored section header ──────────────────
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "  $("─" * $Text.Length)" -ForegroundColor DarkGray
}

# ── HELPER: Print a key-value info line ─────────────────────
function Write-Info {
    param([string]$Label, [string]$Value, [string]$Color = "White")
    Write-Host "  " -NoNewline
    Write-Host "${Label}" -ForegroundColor DarkYellow -NoNewline
    Write-Host " $Value" -ForegroundColor $Color
}

# ── HELPER: Pause and wait for a keypress ───────────────────
function Pause-AndWait {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Host "  $Message" -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ── HELPER: Check a folder exists, stop if it doesn't ───────
function Assert-FolderExists {
    param([string]$FolderPath, [string]$FolderName)
    if (-not (Test-Path $FolderPath)) {
        Write-Host ""
        Write-Host "  [ERROR] $FolderName folder not found:" -ForegroundColor Red
        Write-Host "  $FolderPath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Make sure you ran this script from inside your vault folder." -ForegroundColor DarkGray
        Write-Host "  Expected vault root: $VaultRoot" -ForegroundColor DarkGray
        return $false
    }
    return $true
}


# ── WELCOME SCREEN ──────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor DarkCyan
Write-Host "  ║     Noʻeau OS — Automation Agent Runner      ║" -ForegroundColor Cyan
Write-Host "  ║         8 Agents · Phase 1 · Manual          ║" -ForegroundColor DarkGray
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Vault:  $VaultRoot" -ForegroundColor DarkGray
Write-Host "  Time:   $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
Write-Host ""


# ── FOLDER SAFETY CHECK ─────────────────────────────────────
# Verify all required folders exist before doing anything.
# The script stops here if the vault structure isn't set up correctly.
$FoldersOK = (Assert-FolderExists $PromptsFolder "Prompts") -and
             (Assert-FolderExists $LogsFolder    "Logs") -and
             (Assert-FolderExists $OutputsFolder "Outputs")

if (-not $FoldersOK) {
    Pause-AndWait "Press any key to exit."
    exit 1
}


# ── DISPLAY AGENT MENU ──────────────────────────────────────
Write-Header "Choose an Agent"
Write-Host ""

foreach ($Agent in $Agents) {
    # Agent number and name in white
    Write-Host "  [$($Agent.Number)]" -ForegroundColor Cyan -NoNewline
    Write-Host "  $($Agent.Label)" -ForegroundColor White

    # Description and timing in gray
    Write-Host "       $($Agent.Description)" -ForegroundColor DarkGray
    Write-Host "       When: $($Agent.When)" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "  [Q]  Quit" -ForegroundColor DarkGray
Write-Host ""


# ── GET USER CHOICE ─────────────────────────────────────────
# Read input and validate it.
$Choice = Read-Host "  Enter number (1-8) or Q to quit"

# Handle quit
if ($Choice -match "^[Qq]$") {
    Write-Host ""
    Write-Host "  Exiting. Run again when ready." -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# Find the matching agent
$SelectedAgent = $Agents | Where-Object { $_.Number -eq $Choice }

# If nothing matched, tell the user and stop
if (-not $SelectedAgent) {
    Write-Host ""
    Write-Host "  [ERROR] '$Choice' is not a valid choice (enter 1-8 or Q)." -ForegroundColor Red
    Write-Host "  Run the script again to try again." -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}


# ── SHOW SELECTED AGENT DETAILS ─────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor DarkCyan
Write-Host "  ║  Agent: $($SelectedAgent.Label.PadRight(37))║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor DarkCyan
Write-Host ""
Write-Info "Purpose: " $SelectedAgent.Description
Write-Info "Run:     " $SelectedAgent.When
Write-Host ""


# ── BUILD FILE PATHS ────────────────────────────────────────
# Construct the full paths for prompt, log, and output files.
# These are the only files this script touches.
$Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm"
$DateStamp     = Get-Date -Format "yyyy-MM-dd"

$PromptFile    = Join-Path $PromptsFolder "$($SelectedAgent.PromptName).md"
$LogFile       = Join-Path $LogsFolder    "$($SelectedAgent.LogName).md"
$OutputFile    = Join-Path $OutputsFolder "$($SelectedAgent.OutputName).md"


# ── STEP 1: OPEN THE PROMPT FILE ────────────────────────────
# Opens the prompt file in Notepad so you can read it and copy the prompt text.
# This does NOT modify the file — Notepad opens it read-write, but we're not changing it.
Write-Header "Step 1 — Read the Prompt"
Write-Host ""

if (-not (Test-Path $PromptFile)) {
    Write-Host "  [WARNING] Prompt file not found: $PromptFile" -ForegroundColor Yellow
    Write-Host "  You can still continue — manually open the prompt file." -ForegroundColor DarkGray
} else {
    Write-Host "  Opening prompt in Notepad..." -ForegroundColor Green
    Write-Host "  File: $PromptFile" -ForegroundColor DarkGray
    Start-Process notepad.exe -ArgumentList "`"$PromptFile`""
}

Write-Host ""
Write-Host "  INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "  1. In the Notepad window, find the prompt block (inside the backticks)" -ForegroundColor White
Write-Host "  2. Fill in the [BRACKETED SECTIONS] with your actual information" -ForegroundColor White
Write-Host "  3. Select all the prompt text and copy it (Ctrl+A, Ctrl+C)" -ForegroundColor White
Write-Host "  4. Paste into Claude, ChatGPT, or your AI of choice" -ForegroundColor White
Write-Host "  5. Wait for the AI response" -ForegroundColor White
Write-Host "  6. Come back here when you have the response" -ForegroundColor White

Pause-AndWait "Press any key once you have the AI response ready..."


# ── STEP 2: APPEND TO LOG FILE ──────────────────────────────
# Adds a new entry to the agent's log file.
# Uses Add-Content, which APPENDS — it never overwrites existing content.
Write-Header "Step 2 — Logging This Run"

# This is the text that gets added to the log file.
# It's formatted as a markdown section with timestamp.
$LogEntry = @"


---

### $Timestamp

- **Date:** $DateStamp
- **Time:** $(Get-Date -Format "HH:mm")
- **Agent:** $($SelectedAgent.Label)
- **Status:** Prompt opened — awaiting paste of AI response into output file
- **Notes:** *(add verdict/key finding here after reviewing output)*

"@

try {
    # Add-Content appends to the file — it never overwrites
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
    Write-Host "  Log updated: $LogFile" -ForegroundColor Green
} catch {
    # If the log write fails, warn but don't stop — the output still matters
    Write-Host "  [WARNING] Could not write to log file." -ForegroundColor Yellow
    Write-Host "  File: $LogFile" -ForegroundColor DarkGray
    Write-Host "  You can add the entry manually." -ForegroundColor DarkGray
}


# ── STEP 3: CREATE OUTPUT FILE IF MISSING ───────────────────
# If the output file doesn't exist yet, create it with a basic header.
# This is a safety net — output files should already exist from vault setup.
if (-not (Test-Path $OutputFile)) {
    Write-Host ""
    Write-Host "  Output file not found — creating it..." -ForegroundColor Yellow

    # Create a minimal output file with a header
    $NewOutputContent = @"
---
agent: $($SelectedAgent.Name)
type: output-log
tags: [output]
---

# $($SelectedAgent.Label) — Outputs

> Created by run-noeau-agent.ps1 on $DateStamp
> Paste AI responses here with timestamps. Never delete entries.

---

"@
    # New-Item creates the file; Set-Content writes the header
    New-Item -Path $OutputFile -ItemType File -Force | Out-Null
    Set-Content -Path $OutputFile -Value $NewOutputContent -Encoding UTF8
    Write-Host "  Output file created: $OutputFile" -ForegroundColor Green
}


# ── STEP 4: OPEN OUTPUT FILE ────────────────────────────────
# Opens the output file in Notepad so you can paste the AI's response.
Write-Header "Step 3 — Save the AI Response"
Write-Host ""
Write-Host "  Opening output file in Notepad..." -ForegroundColor Green
Write-Host "  File: $OutputFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "  1. Scroll to the BOTTOM of the output file" -ForegroundColor White
Write-Host "  2. Add a new line: ### $Timestamp" -ForegroundColor White
Write-Host "  3. Paste the AI's full response below that line" -ForegroundColor White
Write-Host "  4. Save the file (Ctrl+S)" -ForegroundColor White

Start-Process notepad.exe -ArgumentList "`"$OutputFile`""

Pause-AndWait "Press any key once you've saved the AI response..."


# ── STEP 5: AGENT-SPECIFIC FOLLOW-UP INSTRUCTIONS ───────────
# Each agent has different things to do after saving the output.
# This section shows the right next steps based on which agent was run.
Write-Header "Step 4 — Follow-Up Actions"
Write-Host ""

switch ($SelectedAgent.Name) {
    "accountability-check" {
        Write-Host "  1. Copy the verdict line from the output" -ForegroundColor White
        Write-Host "  2. Paste it into today's daily note under 'Captures'" -ForegroundColor White
        Write-Host "  3. If verdict is Reset or Avoidance — close all tabs now and start the task" -ForegroundColor Yellow
        Write-Host "  4. Set a reminder to run Accountability Check again in 30 minutes" -ForegroundColor White
    }
    "executive-coach" {
        Write-Host "  1. Copy the TOP PRIORITY — this is your anchor for the next 3 hours" -ForegroundColor White
        Write-Host "  2. Add the NEXT ACTIONS to today's task list" -ForegroundColor White
        Write-Host "  3. Note what was deferred — don't touch those things for 3 hours" -ForegroundColor White
    }
    "learning-coach" {
        Write-Host "  1. Copy the Review Questions" -ForegroundColor White
        Write-Host "  2. Paste them into your learning note under '## Review'" -ForegroundColor White
        Write-Host "  3. Copy the Next Step and add it to tomorrow's plan" -ForegroundColor White
        Write-Host "  4. Update the Confidence Calibration Tracker in the log" -ForegroundColor White
    }
    "reflection-agent" {
        Write-Host "  1. Paste the DAILY REFLECTION into the bottom of today's daily note" -ForegroundColor White
        Write-Host "  2. Highlight TOMORROW'S FIRST MOVE — put it at the top of tomorrow's plan" -ForegroundColor White
        Write-Host "  3. Link today's note in 01-Daily/Index.md" -ForegroundColor White
        Write-Host "  4. Update the pattern tracker in the reflection log" -ForegroundColor White
    }
    "source-monitor" {
        Write-Host "  1. Create a new note in 06-Research/ from the RESEARCH NOTE section" -ForegroundColor White
        Write-Host "  2. Copy the DISCORD VERSION — paste to your study server manually" -ForegroundColor White
        Write-Host "  3. Update the reading tracker: mark source as 'done'" -ForegroundColor White
    }
    "task-renewer" {
        Write-Host "  1. Paste CARRY FORWARD tasks into today's daily note task list" -ForegroundColor White
        Write-Host "  2. Review ARCHIVE CANDIDATES — if you agree, move them to 99-Archive/" -ForegroundColor White
        Write-Host "  3. Read the PATTERN NOTE and tell Alakaʻi if it's recurring" -ForegroundColor White
    }
    "guardian-check" {
        Write-Host "  1. If SYSTEM STATUS is Red or Yellow — address HIGH priority items now" -ForegroundColor Yellow
        Write-Host "  2. If backup is overdue: git add -A && git commit -m 'vault: backup' && git push" -ForegroundColor White
        Write-Host "  3. Update the Backup Log in Noeau-OS/System/Backup-Log.md" -ForegroundColor White
    }
    "scribe-cleanup" {
        Write-Host "  1. Create new files in correct folders for each Obsidian note output" -ForegroundColor White
        Write-Host "  2. Copy Discord notes to 02-Discord-Captures/ and post to Discord manually" -ForegroundColor White
        Write-Host "  3. Mark original raw notes as 'status: processed' in their frontmatter" -ForegroundColor White
        Write-Host "  4. Clear 00-Inbox/ of processed items" -ForegroundColor White
    }
}


# ── DONE ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ═══════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  ✓ Run complete" -ForegroundColor Green
Write-Host ""
Write-Info "Agent:  " $SelectedAgent.Label
Write-Info "Logged: " $Timestamp
Write-Info "Log:    " $LogFile
Write-Info "Output: " $OutputFile
Write-Host ""
Write-Host "  Nothing was deleted. Nothing was overwritten." -ForegroundColor DarkGray
Write-Host "  All outputs are in 07-Automations/Outputs/" -ForegroundColor DarkGray
Write-Host ""

Pause-AndWait "Press any key to close this window."
