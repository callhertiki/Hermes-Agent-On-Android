#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Noʻeau Knowledge System — Main CLI

.DESCRIPTION
    noeau <command> [args]

    COMMANDS
      capture [topic] [title]    Capture a new knowledge note  (daily use)
      add     [topic] [minutes]  Log a learning session
      dashboard                  Show daily dashboard
      process                    Process everything in inbox right now
      watch                      Live-watch inbox for new files (stays open)
      report  daily              Generate / open today's report
      report  weekly             Generate / open this week's report
      report  monthly            Generate / open this month's report
      memory  build              Rebuild knowledge memory graph
      status                     Quick system status
      open    [location]         Open a folder in Explorer
                                 locations: inbox knowledge reports research config

.EXAMPLE
    noeau
    noeau capture python "Decorators deep dive"
    noeau add linux 30
    noeau report weekly
    noeau open inbox
#>

param(
    [Parameter(Position = 0)][string]$Command = "dashboard",
    [Parameter(Position = 1)][string]$Arg1    = "",
    [Parameter(Position = 2)][string]$Arg2    = "",
    [switch]$Help
)

$here = $PSScriptRoot
Import-Module (Join-Path $here "modules\NoEau.psm1") -Force -ErrorAction Stop

if ($Help -or $Command -eq "help") {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

switch ($Command.ToLower()) {

    "capture" {
        & (Join-Path $here "New-KnowledgeCapture.ps1") -Topic $Arg1 -Title $Arg2
    }

    { $_ -in "add","log","track" } {
        $mins = if ($Arg2 -match '^\d+$') { [int]$Arg2 } else { 0 }
        & (Join-Path $here "Update-LearningTracker.ps1") -Topic $Arg1 -Minutes $mins
    }

    "dashboard" {
        & (Join-Path $here "Show-Dashboard.ps1")
    }

    "process" {
        & (Join-Path $here "Invoke-InboxWatch.ps1") -OneShot
    }

    "watch" {
        & (Join-Path $here "Invoke-InboxWatch.ps1")
    }

    "report" {
        switch ($Arg1.ToLower()) {
            "weekly"  { & (Join-Path $here "New-WeeklyReport.ps1")  }
            "monthly" { & (Join-Path $here "New-MonthlyReport.ps1") }
            default   { & (Join-Path $here "New-DailyReport.ps1")   }
        }
    }

    "memory" {
        if ($Arg1 -in @("build","rebuild","update")) {
            & (Join-Path $here "Build-Memory.ps1")
        } else {
            $mem = Get-NoEauMemory
            $count = ($mem.concepts.PSObject.Properties | Measure-Object).Count
            Write-Host "Memory: $count concepts | Last built: $($mem.last_built)" -ForegroundColor Cyan
        }
    }

    "status" {
        $config   = Get-NoEauConfig
        $tracker  = Get-LearningTracker
        $streak   = Get-StreakInfo
        $todayMin = Get-TodayMinutes
        $captures = @(Get-TodaysCaptures)
        $mem      = Get-NoEauMemory
        $memCount = ($mem.concepts.PSObject.Properties | Measure-Object).Count
        Write-Host ""
        Write-Host "  Noʻeau Knowledge System — Status" -ForegroundColor Cyan
        Write-Host "  ──────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  Root       : $(Get-NoEauRoot)"
        Write-Host "  Sessions   : $(@($tracker.sessions).Count) total"
        Write-Host "  Streak     : $($streak.current) days"
        Write-Host "  Today      : $($captures.Count) notes, $todayMin min"
        Write-Host "  Memory     : $memCount concepts (last: $($mem.last_built))"
        Write-Host ""
    }

    "open" {
        $root   = Get-NoEauRoot
        $target = switch ($Arg1.ToLower()) {
            "inbox"    { Join-Path $root "inbox"    }
            "knowledge"{ Join-Path $root "knowledge"}
            "reports"  { Join-Path $root "reports"  }
            "research" { Join-Path $root "research" }
            "config"   { Join-Path $root "config"   }
            default    { $root }
        }
        Start-Process "explorer.exe" $target
    }

    default {
        Write-Host "Unknown command: '$Command'. Run  noeau help  for usage." -ForegroundColor Yellow
        exit 1
    }
}
