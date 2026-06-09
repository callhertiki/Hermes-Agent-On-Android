# ============================================================
# run-noeau-agent.ps1
# Noʻeau OS — Manual Agent Runner
# For Windows (Lenovo Yoga 7 or any Windows 10/11 machine)
#
# HOW TO RUN:
#   1. Open PowerShell (search "PowerShell" in Start menu)
#   2. Navigate to your vault folder:
#      cd "C:\Path\To\Your\Vault"
#   3. Run this script:
#      .\07-Automations\Scripts\run-noeau-agent.ps1
#
# WHAT THIS SCRIPT DOES:
#   - Shows a menu of available agents
#   - Lets you pick one
#   - Opens the prompt file so you can copy the text
#   - Appends a timestamped entry to the agent's log file
#   - Creates a timestamped output file ready to receive AI response
#   - NEVER deletes or overwrites any file
# ============================================================


# ── CONFIGURATION ──────────────────────────────────────────
# Change this to the full path of your vault if needed.
# By default it assumes you're running from inside the vault folder.
$VaultRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$AutomationsFolder = Join-Path $VaultRoot "07-Automations"

# Paths to each agent's folders
$PromptsFolder = Join-Path $AutomationsFolder "Prompts"
$LogsFolder    = Join-Path $AutomationsFolder "Logs"
$OutputsFolder = Join-Path $AutomationsFolder "Outputs"


# ── AGENT DEFINITIONS ──────────────────────────────────────
# Each agent has a Name, description, and file prefix.
# To add a new agent later, just add a new entry to this list.
$Agents = @(
    [PSCustomObject]@{
        Number      = "1"
        Name        = "accountability-check"
        Label       = "Accountability Check"
        Description = "Compares your plan to what you're actually doing. Gives a verdict."
        When        = "Every 30 minutes during work sessions"
    },
    [PSCustomObject]@{
        Number      = "2"
        Name        = "learning-coach"
        Label       = "Learning Coach"
        Description = "Quizzes you on what you just learned. Tests real understanding."
        When        = "After any study session"
    },
    [PSCustomObject]@{
        Number      = "3"
        Name        = "reflection-agent"
        Label       = "Reflection Agent"
        Description = "Reviews your day. Names what you learned and what you avoided."
        When        = "End of day (evening)"
    },
    [PSCustomObject]@{
        Number      = "4"
        Name        = "scribe-agent"
        Label       = "Scribe Agent"
        Description = "Formats rough notes into Discord notes, Obsidian notes, summaries."
        When        = "Any time you have messy notes to clean up"
    }
)


# ── HELPER FUNCTIONS ────────────────────────────────────────

# Prints a colored section header
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "  $("-" * $Text.Length)" -ForegroundColor DarkGray
}

# Prints a colored label + value pair
function Write-Info {
    param([string]$Label, [string]$Value)
    Write-Host "  " -NoNewline
    Write-Host "$Label" -ForegroundColor DarkYellow -NoNewline
    Write-Host " $Value"
}

# Waits for the user to press any key before continuing
function Pause-Script {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Host "  $Message" -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


# ── WELCOME SCREEN ──────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor DarkCyan
Write-Host "  ║        Noʻeau OS — Agent Runner           ║" -ForegroundColor Cyan
Write-Host "  ║   Accountability · Learning · Reflection  ║" -ForegroundColor DarkGray
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Vault location: $VaultRoot" -ForegroundColor DarkGray
Write-Host ""


# ── VERIFY FOLDER STRUCTURE ─────────────────────────────────
# Make sure all required folders exist before proceeding.
# This is a safety check — it does NOT delete anything.
$RequiredFolders = @($PromptsFolder, $LogsFolder, $OutputsFolder)
foreach ($Folder in $RequiredFolders) {
    if (-not (Test-Path $Folder)) {
        Write-Host "  [ERROR] Folder not found: $Folder" -ForegroundColor Red
        Write-Host "  Make sure you're running this script from inside your vault folder." -ForegroundColor Yellow
        Write-Host ""
        Pause-Script "Press any key to exit."
        exit 1
    }
}


# ── SHOW AGENT MENU ─────────────────────────────────────────
Write-Header "Available Agents"
Write-Host ""
foreach ($Agent in $Agents) {
    Write-Host "  [$($Agent.Number)]  $($Agent.Label)" -ForegroundColor White
    Write-Host "       $($Agent.Description)" -ForegroundColor DarkGray
    Write-Host "       When to use: $($Agent.When)" -ForegroundColor DarkGray
    Write-Host ""
}
Write-Host "  [Q]  Quit" -ForegroundColor DarkGray
Write-Host ""

# Read user's choice
$Choice = Read-Host "  Enter agent number (1-4) or Q to quit"

# Handle quit
if ($Choice -eq "Q" -or $Choice -eq "q") {
    Write-Host ""
    Write-Host "  Exiting. Come back when you're ready." -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# Validate choice — make sure it matches one of the agent numbers
$SelectedAgent = $Agents | Where-Object { $_.Number -eq $Choice }
if (-not $SelectedAgent) {
    Write-Host ""
    Write-Host "  [ERROR] '$Choice' is not a valid choice. Please run the script again." -ForegroundColor Red
    Write-Host ""
    exit 1
}


# ── CONFIRM SELECTION ───────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor DarkCyan
Write-Host "  ║   Agent Selected: $($SelectedAgent.Label.PadRight(24))║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor DarkCyan
Write-Host ""
Write-Info "Agent:      " $SelectedAgent.Label
Write-Info "Purpose:    " $SelectedAgent.Description
Write-Info "Best used:  " $SelectedAgent.When
Write-Host ""


# ── BUILD FILE PATHS ────────────────────────────────────────
# All file paths are constructed here. Nothing is hardcoded below this point.
$AgentName    = $SelectedAgent.Name
$Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm"
$DateStamp    = Get-Date -Format "yyyy-MM-dd"
$TimeStamp    = Get-Date -Format "HH-mm"

# Path to the agent's prompt file (you copy from this)
$PromptFile   = Join-Path $PromptsFolder "$AgentName.prompt.md"

# Path to the agent's log file (we append a new entry to this)
$LogFile      = Join-Path $LogsFolder "$AgentName.log.md"

# Path to the agent's output file (you paste AI response into this)
$OutputFile   = Join-Path $OutputsFolder "$AgentName.output.md"


# ── CHECK PROMPT FILE EXISTS ────────────────────────────────
if (-not (Test-Path $PromptFile)) {
    Write-Host "  [ERROR] Prompt file not found:" -ForegroundColor Red
    Write-Host "  $PromptFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Make sure the Prompts folder is set up correctly." -ForegroundColor DarkGray
    Pause-Script "Press any key to exit."
    exit 1
}


# ── OPEN THE PROMPT FILE ────────────────────────────────────
# Opens the prompt file in Notepad so you can read and copy the prompt text.
# This does NOT modify the file — it's read-only from your perspective.
Write-Header "Step 1 — Open the Prompt"
Write-Host ""
Write-Host "  Opening prompt file in Notepad..." -ForegroundColor Green
Write-Host "  File: $PromptFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "  1. In Notepad, find the prompt block (inside the triple backticks)" -ForegroundColor White
Write-Host "  2. Fill in the [BRACKETED SECTIONS] with your actual information" -ForegroundColor White
Write-Host "  3. Copy the completed prompt" -ForegroundColor White
Write-Host "  4. Paste it into your AI chat (Claude, ChatGPT, etc.)" -ForegroundColor White
Write-Host "  5. Come back here when you have the AI's response" -ForegroundColor White
Write-Host ""

# Open Notepad with the prompt file
# notepad.exe is always available on Windows — no installation needed
Start-Process notepad.exe -ArgumentList "`"$PromptFile`""

# Wait for the user to confirm they've sent the prompt
Pause-Script "Press any key once you have the AI response ready to paste..."


# ── APPEND TO LOG FILE ──────────────────────────────────────
# Adds a new entry to the agent's log file.
# This is APPEND ONLY — existing entries are never touched.
Write-Header "Step 2 — Logging This Run"

# Build the log entry text
# The entry is formatted as a markdown section with timestamp
$LogEntry = @"


---

### $Timestamp | Run added by script

- **Date:** $DateStamp
- **Time:** $(Get-Date -Format "HH:mm")
- **Agent:** $($SelectedAgent.Label)
- **Prompt file used:** $PromptFile
- **Output file:** $OutputFile
- **Status:** Prompt opened — awaiting manual paste of AI response
- **Notes:** *(fill in after reviewing AI output)*

"@

# Append to the log file — Add-Content never overwrites, only appends
try {
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
    Write-Host "  Log updated: $LogFile" -ForegroundColor Green
} catch {
    # If logging fails, warn the user but don't stop the script
    Write-Host "  [WARNING] Could not write to log file: $LogFile" -ForegroundColor Yellow
    Write-Host "  You can add the entry manually." -ForegroundColor DarkGray
}


# ── OPEN OUTPUT FILE ────────────────────────────────────────
# Opens the output file in Notepad so you can paste the AI's response.
# The output file already exists (created as part of vault setup).
# The script just opens it — it does NOT modify it before you paste.
Write-Header "Step 3 — Save the AI Response"
Write-Host ""
Write-Host "  Opening output file in Notepad..." -ForegroundColor Green
Write-Host "  File: $OutputFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "  1. Scroll to the bottom of the output file" -ForegroundColor White
Write-Host "  2. Add a new section: ### $Timestamp" -ForegroundColor White
Write-Host "  3. Paste the AI's response below that heading" -ForegroundColor White
Write-Host "  4. Save the file (Ctrl+S)" -ForegroundColor White
Write-Host ""

# Check the output file exists before opening
if (Test-Path $OutputFile) {
    Start-Process notepad.exe -ArgumentList "`"$OutputFile`""
} else {
    Write-Host "  [WARNING] Output file not found: $OutputFile" -ForegroundColor Yellow
    Write-Host "  You can create it manually in the Outputs folder." -ForegroundColor DarkGray
}

Pause-Script "Press any key once you've saved the AI response to the output file..."


# ── AGENT-SPECIFIC NEXT STEPS ───────────────────────────────
# Each agent has slightly different follow-up instructions.
# This section shows the right next step based on which agent was run.
Write-Header "Step 4 — Follow-Up Actions"
Write-Host ""

switch ($AgentName) {
    "accountability-check" {
        Write-Host "  1. Copy the verdict line from the AI response" -ForegroundColor White
        Write-Host "  2. Paste it into today's daily note under 'Notes & Captures'" -ForegroundColor White
        Write-Host "  3. If the verdict is Reset or Avoidance — close everything and start the task now" -ForegroundColor Yellow
        Write-Host "  4. Set a reminder to run this agent again in 30 minutes" -ForegroundColor White
    }
    "learning-coach" {
        Write-Host "  1. Copy the 'Review Questions' from the AI response" -ForegroundColor White
        Write-Host "  2. Paste them into your learning note for this topic under '## Review'" -ForegroundColor White
        Write-Host "  3. Copy the 'Next Step' and add it to tomorrow's daily note" -ForegroundColor White
        Write-Host "  4. Update the Confidence Calibration Tracker in the log file" -ForegroundColor White
    }
    "reflection-agent" {
        Write-Host "  1. Paste the full reflection into the bottom of today's daily note" -ForegroundColor White
        Write-Host "  2. Copy 'TOMORROW'S FIRST MOVE' — put it at the top of tomorrow's plan" -ForegroundColor White
        Write-Host "  3. Link today's daily note in the Daily Notes Index" -ForegroundColor White
        Write-Host "  4. Update your day rating in the Reflection Log" -ForegroundColor White
    }
    "scribe-agent" {
        Write-Host "  1. For Discord notes: copy and paste into your Discord channel manually" -ForegroundColor White
        Write-Host "  2. For Obsidian notes: create a new file in the correct folder and paste" -ForegroundColor White
        Write-Host "  3. Update the Sources Processed table in the Scribe log" -ForegroundColor White
        Write-Host "  4. Update Output Type Usage counts in the log" -ForegroundColor White
    }
}


# ── DONE ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Run complete." -ForegroundColor Green
Write-Host "  Agent:  $($SelectedAgent.Label)" -ForegroundColor White
Write-Host "  Logged: $Timestamp" -ForegroundColor DarkGray
Write-Host "  Log:    $LogFile" -ForegroundColor DarkGray
Write-Host "  Output: $OutputFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Nothing was deleted. Nothing was overwritten." -ForegroundColor DarkGray
Write-Host ""

# Keep the window open so the user can read the summary
# Remove this line if you want the script to close automatically
Pause-Script "Press any key to close this window."
