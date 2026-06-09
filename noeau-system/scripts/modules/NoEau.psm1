#Requires -Version 7.0
# NoEau.psm1 — Core module for the Noʻeau Knowledge System
# Import this at the top of every script:
#   Import-Module (Join-Path $PSScriptRoot "..\modules\NoEau.psm1") -Force

Set-StrictMode -Version Latest

$script:NoEauRoot = "C:\Noeau"

# ── Path helpers ──────────────────────────────────────────────────────────────

function Get-NoEauRoot { return $script:NoEauRoot }

function Get-NoEauPath {
    param([string]$SubPath = "")
    if ($SubPath) { return Join-Path $script:NoEauRoot $SubPath }
    return $script:NoEauRoot
}

# ── Configuration ─────────────────────────────────────────────────────────────

function Get-NoEauConfig {
    $path = Get-NoEauPath "config\preferences.json"
    if (-not (Test-Path $path)) {
        throw "Noʻeau config not found at $path. Run Install-NoEau.ps1 first."
    }
    return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-ValidTopics {
    return @((Get-NoEauConfig).topics)
}

function Get-TopicPath {
    param([string]$Topic)
    $config  = Get-NoEauConfig
    $t       = $Topic.ToLower().Trim()

    if ($config.topic_aliases.PSObject.Properties.Name -contains $t) {
        $t = $config.topic_aliases.$t
    }
    if ($t -notin $config.topics) { $t = "research" }

    return Get-NoEauPath "knowledge\$t"
}

# ── Logging ───────────────────────────────────────────────────────────────────

function Write-NoEauLog {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level = 'INFO'
    )
    $logPath = Get-NoEauPath "config\noeau.log"
    $ts      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line    = "[$ts] [$Level] $Message"
    Add-Content $logPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

# ── Date & string helpers ─────────────────────────────────────────────────────

function Get-TodayStr  { return (Get-Date).ToString("yyyy-MM-dd") }
function Get-MonthStr  { return (Get-Date).ToString("yyyy-MM") }

function Get-WeekStart {
    $today = Get-Date
    $dow   = [int]$today.DayOfWeek
    $offset = if ($dow -eq 0) { -6 } else { 1 - $dow }
    return $today.AddDays($offset).ToString("yyyy-MM-dd")
}

function Get-MonthStart {
    return (Get-Date -Day 1).ToString("yyyy-MM-dd")
}

function ConvertTo-Slug {
    param([string]$Text)
    $s = $Text.ToLower() -replace "[^a-z0-9\s\-]", '' `
                          -replace '\s+',            '-' `
                          -replace '\-+',            '-'
    $s = $s.Trim('-')
    return if ($s.Length -gt 50) { $s.Substring(0, 50) } else { $s }
}

# ── Learning tracker ──────────────────────────────────────────────────────────

function Get-LearningTracker {
    $path = Get-NoEauPath "config\learning_tracker.json"
    if (Test-Path $path) {
        return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return [PSCustomObject]@{
        version  = "1.0"
        sessions = @()
        goals    = [PSCustomObject]@{ daily_minutes = 60 }
        streaks  = [PSCustomObject]@{ current = 0; longest = 0; last_active = "" }
    }
}

function Save-LearningTracker {
    param([PSCustomObject]$Data)
    $path = Get-NoEauPath "config\learning_tracker.json"
    $Data | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
}

function Add-LearningSession {
    param(
        [string]   $Topic,
        [string]   $Notes   = "",
        [int]      $Minutes = 0,
        [string[]] $Tags    = @(),
        [string]   $Source  = "manual"
    )
    $tracker = Get-LearningTracker
    $today   = Get-TodayStr

    $session = [PSCustomObject]@{
        id               = [guid]::NewGuid().ToString("N").Substring(0, 8)
        date             = $today
        timestamp        = (Get-Date).ToString("o")
        topic            = $Topic
        duration_minutes = $Minutes
        notes            = $Notes
        tags             = $Tags
        source           = $Source
    }

    $list = [System.Collections.Generic.List[object]]::new()
    if ($tracker.sessions) { $list.AddRange([object[]]$tracker.sessions) }
    $list.Add($session)
    $tracker.sessions = $list.ToArray()

    $streak = Get-StreakInfo -TrackerData $tracker
    $tracker.streaks = [PSCustomObject]@{
        current     = $streak.current
        longest     = [Math]::Max($streak.longest, $streak.current)
        last_active = $today
    }

    Save-LearningTracker $tracker
    Write-NoEauLog "Session added: $Topic ($Minutes min)"
    return $session
}

function Get-StreakInfo {
    param([PSCustomObject]$TrackerData = $null)
    if (-not $TrackerData) { $TrackerData = Get-LearningTracker }

    if (-not $TrackerData.sessions -or @($TrackerData.sessions).Count -eq 0) {
        return @{ current = 0; longest = 0 }
    }

    $dates   = @($TrackerData.sessions) | ForEach-Object { $_.date } | Sort-Object -Unique -Descending
    $today   = [datetime]::Today
    $check   = $today
    $current = 0

    foreach ($d in $dates) {
        $dt = [datetime]::ParseExact($d, "yyyy-MM-dd", $null)
        if ($dt -ge $check.AddDays(-1) -and $dt -le $check) {
            if ($current -eq 0 -and $dt -lt $check) { $check = $dt }
            $current++
            $check = $dt.AddDays(-1)
        } elseif ($dt -lt $check) {
            break
        }
    }

    return @{
        current = $current
        longest = if ($TrackerData.streaks -and $TrackerData.streaks.longest) {
                      [int]$TrackerData.streaks.longest
                  } else { 0 }
    }
}

function Get-TodayMinutes {
    $tracker = Get-LearningTracker
    $today   = Get-TodayStr
    $today_sessions = @($tracker.sessions | Where-Object { $_.date -eq $today })
    if ($today_sessions.Count -eq 0) { return 0 }
    return [int]($today_sessions | Measure-Object -Property duration_minutes -Sum).Sum
}

function Get-TopicStats {
    param([int]$Days = 7)
    $tracker = Get-LearningTracker
    $cutoff  = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd")
    $recent  = @($tracker.sessions | Where-Object { $_.date -ge $cutoff })

    $stats = @{}
    foreach ($s in $recent) {
        $t = $s.topic
        if (-not $stats.ContainsKey($t)) { $stats[$t] = @{ count = 0; minutes = 0 } }
        $stats[$t].count++
        $stats[$t].minutes += [int]$s.duration_minutes
    }
    return $stats
}

# ── Note / file helpers ───────────────────────────────────────────────────────

function Get-TodaysCaptures {
    $today  = Get-TodayStr
    $config = Get-NoEauConfig
    $all    = @()
    foreach ($topic in $config.topics) {
        $dir = Get-NoEauPath "knowledge\$topic"
        if (Test-Path $dir) {
            $all += @(Get-ChildItem $dir -Filter "*.md" |
                      Where-Object { $_.Name.StartsWith($today) })
        }
    }
    return $all
}

function Get-CapturesByDateRange {
    param(
        [string]$From,
        [string]$To = (Get-TodayStr)
    )
    $config = Get-NoEauConfig
    $all    = @()
    foreach ($topic in $config.topics) {
        $dir = Get-NoEauPath "knowledge\$topic"
        if (Test-Path $dir) {
            $all += @(Get-ChildItem $dir -Filter "*.md" | Where-Object {
                $datePrefix = $_.BaseName.Substring(0, [Math]::Min(10, $_.BaseName.Length))
                $datePrefix.Length -eq 10 -and $datePrefix -ge $From -and $datePrefix -le $To
            })
        }
    }
    return $all
}

function New-NoteFile {
    param(
        [string]   $Topic,
        [string]   $Title,
        [string]   $Body,
        [string[]] $Tags    = @(),
        [int]      $Minutes = 0
    )
    $topicPath = Get-TopicPath $Topic
    $today     = Get-TodayStr
    $slug      = ConvertTo-Slug $Title
    $filename  = "${today}-${slug}.md"
    $filepath  = Join-Path $topicPath $filename

    $tagsFm  = ($Tags | ForEach-Object { "`"$_`"" }) -join ", "
    $tagsInline = if ($Tags.Count -gt 0) { ($Tags | ForEach-Object { "#$_" }) -join " " } else { "" }

    $content = @"
---
title: "$Title"
date: $today
topic: $Topic
tags: [$tagsFm]
minutes: $Minutes
---

# $Title

$Body

---
$tagsInline

*Captured: $(Get-Date -Format "yyyy-MM-dd HH:mm")*
"@
    Set-Content $filepath -Value $content -Encoding UTF8
    Write-NoEauLog "Note created: $filepath"
    return $filepath
}

function Get-TopicFromContent {
    param([string]$Content)
    $lower = $Content.ToLower()
    $kw = @{
        python             = @("python","pip","venv","django","flask","pandas","numpy","def ","import ")
        linux              = @("linux","bash","chmod","grep","sudo","shell","apt","systemctl","kali")
        networking         = @("tcp","ip","dns","dhcp","http","ftp","ssh","subnet","router","vlan","packet")
        cybersecurity      = @("exploit","vulnerability","cve","pentest","payload","reverse shell","xss","sqli","firewall")
        osint              = @("osint","recon","shodan","maltego","footprint","open source intelligence")
        "lds-studies"      = @("gospel","scriptures","book of mormon","covenant","priesthood","ensign","general conference")
        "personal-development" = @("habit","goal","mindset","productivity","discipline","growth","motivation","journal")
    }
    $scores = @{}
    foreach ($t in $kw.Keys) {
        $s = 0
        foreach ($word in $kw[$t]) { if ($lower -match [regex]::Escape($word)) { $s++ } }
        if ($s -gt 0) { $scores[$t] = $s }
    }
    if ($scores.Count -eq 0) { return "research" }
    return ($scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
}

# ── Memory helpers ────────────────────────────────────────────────────────────

function Get-NoEauMemory {
    $path = Get-NoEauPath "config\memory.json"
    if (Test-Path $path) {
        return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return [PSCustomObject]@{
        version     = "1.0"
        last_built  = ""
        concepts    = [PSCustomObject]@{}
        connections = @()
    }
}

function Save-NoEauMemory {
    param([PSCustomObject]$Memory)
    $path = Get-NoEauPath "config\memory.json"
    $Memory | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
}

Export-ModuleMember -Function *
