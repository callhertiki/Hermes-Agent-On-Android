#Requires -Version 7.0
# Invoke-InboxWatch.ps1 — Process inbox files or live-watch for new ones
# Usage:  noeau process          (process current inbox then exit)
#         noeau watch            (stay open, process as files arrive)

param([switch]$OneShot)

$here = $PSScriptRoot
Import-Module (Join-Path $here "modules\NoEau.psm1") -Force

$inbox       = Get-NoEauPath "inbox"
$pdfsDir     = Get-NoEauPath "research\PDFs"
$summariesDir= Get-NoEauPath "research\summaries"
$pyScript    = Join-Path $here "pdf_processor.py"
$config      = Get-NoEauConfig

# ── File processor ─────────────────────────────────────────────────────────────

function Invoke-ProcessFile {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) { return }

    $file = Get-Item $FilePath
    # Skip hidden / temp files
    if ($file.Name.StartsWith('.') -or $file.Name.EndsWith('.tmp')) { return }

    $ext = $file.Extension.ToLower()
    Write-Host "  Processing: " -NoNewline -ForegroundColor DarkGray
    Write-Host $file.Name -ForegroundColor White

    switch ($ext) {

        ".md" {
            $content = Get-Content $FilePath -Raw -Encoding UTF8
            $topic   = Get-TopicFromContent $content
            $destDir = Get-TopicPath $topic
            $dest    = Join-Path $destDir $file.Name

            if (Test-Path $dest) {
                $stamp = (Get-Date).ToString("HHmmss")
                $dest  = Join-Path $destDir "$($file.BaseName)-$stamp.md"
            }
            Move-Item $FilePath $dest
            Write-Host "    → [$topic] $($file.Name)" -ForegroundColor Green
            Write-NoEauLog "Inbox: moved $($file.Name) → knowledge\$topic"
        }

        ".txt" {
            $content = Get-Content $FilePath -Raw -Encoding UTF8
            $topic   = Get-TopicFromContent $content
            $mdName  = $file.BaseName + ".md"
            $dest    = Join-Path (Get-TopicPath $topic) $mdName

            $mdContent = "# $($file.BaseName)`n`n$content"
            Set-Content $dest -Value $mdContent -Encoding UTF8
            Remove-Item $FilePath
            Write-Host "    → [$topic] $mdName (converted from .txt)" -ForegroundColor Green
        }

        ".pdf" {
            # Archive the PDF
            $pdfDest = Join-Path $pdfsDir $file.Name
            if (Test-Path $pdfDest) {
                $stamp   = (Get-Date).ToString("HHmmss")
                $pdfDest = Join-Path $pdfsDir "$($file.BaseName)-$stamp.pdf"
            }
            Copy-Item $FilePath $pdfDest

            # Generate markdown summary
            if ((Test-Path $pyScript) -and $config.inbox_watch.process_pdfs) {
                try {
                    $raw = python $pyScript $pdfDest $summariesDir 2>&1
                    $jsonLine = @($raw) | Where-Object { $_ -match '^\{' } | Select-Object -Last 1
                    if ($jsonLine) {
                        $data = $jsonLine | ConvertFrom-Json
                        Write-Host "    → PDF archived + summary created [$($data.topic)]" -ForegroundColor Green
                        Add-LearningSession -Topic $data.topic -Notes "PDF: $($file.BaseName)" -Source "pdf"
                    } else {
                        Write-Host "    → PDF archived (no summary — check Python/pdfplumber install)" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "    → PDF archived (summary failed: $($_.Exception.Message))" -ForegroundColor Yellow
                }
            } else {
                Write-Host "    → PDF archived to research\PDFs\" -ForegroundColor Green
            }

            Remove-Item $FilePath -Force
            Write-NoEauLog "Inbox: PDF $($file.Name) archived"
        }

        default {
            Write-Host "    → Unsupported type ($ext) — left in inbox" -ForegroundColor Yellow
        }
    }
}

# ── Main ──────────────────────────────────────────────────────────────────────

# Always process existing files first
$existing = @(Get-ChildItem $inbox -File)
if ($existing.Count -gt 0) {
    Write-Host ""
    Write-Host "  Processing $($existing.Count) file(s) in inbox..." -ForegroundColor Cyan
    foreach ($f in $existing) { Invoke-ProcessFile $f.FullName }
} else {
    Write-Host "  Inbox is empty." -ForegroundColor DarkGray
}

if ($OneShot) { exit 0 }

# Live watch
Write-Host ""
Write-Host "  Watching: $inbox" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop.`n" -ForegroundColor DarkGray

$watcher = [System.IO.FileSystemWatcher]::new($inbox)
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents   = $true
$watcher.NotifyFilter          = [System.IO.NotifyFilters]::FileName

$action = {
    $path = $Event.SourceArgs[1].FullPath
    $name = $Event.SourceArgs[1].Name
    if ($name -match '^\.' -or $name -match '\.tmp$') { return }
    Start-Sleep -Milliseconds 800    # let the file finish writing
    if (Test-Path $path) { Invoke-ProcessFile $path }
}

$sub = Register-ObjectEvent $watcher Created -Action $action

try {
    while ($true) { Start-Sleep -Seconds 2 }
} finally {
    Unregister-Event $sub.Id -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Host "`n  Inbox watcher stopped." -ForegroundColor Yellow
}
