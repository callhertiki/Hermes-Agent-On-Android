#Requires -Version 7.0
# Build-Memory.ps1 — Scan all knowledge notes and build a concept memory graph
# Usage:  noeau memory build

param([switch]$Quiet)

$here = $PSScriptRoot
Import-Module (Join-Path $here "modules\NoEau.psm1") -Force

$config = Get-NoEauConfig

if (-not $Quiet) {
    Write-Host ""
    Write-Host "  Building Noʻeau memory graph..." -ForegroundColor Cyan
}

# Stop-words to ignore when extracting concepts
$stopWords = @(
    "the","and","for","are","but","not","you","all","can","her","was","one","our",
    "out","day","get","has","him","his","how","its","may","off","old","own","put",
    "say","she","too","use","via","who","why","yet","now","see","set","let","did",
    "had","has","have","been","were","will","with","this","that","what","when",
    "from","they","them","then","than","some","also","each","both","more","most",
    "over","such","into","onto","upon","after","about","above","below","these",
    "those","their","there","here","where","which","while","would","could","should",
    "being","doing","going","using","just","very","well","good","new","old","any",
    "same","other","another"
)

# Collect all markdown files
$allFiles  = @()
foreach ($topic in $config.topics) {
    $dir = Get-NoEauPath "knowledge\$topic"
    if (Test-Path $dir) {
        $allFiles += @(Get-ChildItem $dir -Filter "*.md")
    }
}

if (-not $Quiet) {
    Write-Host "  Found $($allFiles.Count) notes to scan." -ForegroundColor DarkGray
}

$memory = Get-NoEauMemory
$conceptMap = @{}   # key → @{ label, topic, mentions, sources, cooccurs }

foreach ($f in $allFiles) {
    $topic   = Split-Path (Split-Path $f.FullName) -Leaf
    $rawText = Get-Content $f.FullName -Raw -Encoding UTF8

    # Strip frontmatter
    $body = $rawText -replace '(?s)^---.*?---\s*', '' -replace '#+ ', ' ' -replace '\*', ' '

    # Extract words (3-20 chars, only alpha)
    $words = [regex]::Matches($body.ToLower(), '\b[a-z]{3,20}\b') |
             ForEach-Object { $_.Value } |
             Where-Object { $_ -notin $stopWords }

    # Extract tags from frontmatter
    $tags = [regex]::Matches($rawText, 'tags:\s*\[(.*?)\]') |
            ForEach-Object { $_.Groups[1].Value -split ',' | ForEach-Object { $_.Trim().Trim('"') } }
    $tags += [regex]::Matches($rawText, '#(\w[\w-]+)') | ForEach-Object { $_.Groups[1].Value }
    $tags  = @($tags | Where-Object { $_ } | ForEach-Object { $_.ToLower() })

    # Count word frequency
    $freq = @{}
    foreach ($w in $words) {
        $freq[$w] = ($freq[$w] ?? 0) + 1
    }

    # Register concepts (terms appearing 2+ times in this note, or explicit tags)
    $noteConcepts = @()

    foreach ($tag in $tags) {
        $key = "$topic-$tag"
        if (-not $conceptMap.ContainsKey($key)) {
            $conceptMap[$key] = @{ label = $tag; topic = $topic; mentions = 0; sources = @(); cooccurs = @() }
        }
        $conceptMap[$key].mentions++
        if ($f.FullName -notin $conceptMap[$key].sources) { $conceptMap[$key].sources += $f.FullName }
        $noteConcepts += $key
    }

    foreach ($entry in ($freq.GetEnumerator() | Where-Object { $_.Value -ge $config.memory.min_word_frequency })) {
        $key = "$topic-$($entry.Key)"
        if (-not $conceptMap.ContainsKey($key)) {
            $conceptMap[$key] = @{ label = $entry.Key; topic = $topic; mentions = 0; sources = @(); cooccurs = @() }
        }
        $conceptMap[$key].mentions += $entry.Value
        if ($f.FullName -notin $conceptMap[$key].sources) { $conceptMap[$key].sources += $f.FullName }
        if ($key -notin $noteConcepts) { $noteConcepts += $key }
    }

    # Record co-occurrence for concepts in the same note
    for ($i = 0; $i -lt $noteConcepts.Count; $i++) {
        for ($j = $i + 1; $j -lt $noteConcepts.Count -and $j -lt $i + 6; $j++) {
            $a = $noteConcepts[$i]
            $b = $noteConcepts[$j]
            if ($b -notin $conceptMap[$a].cooccurs) { $conceptMap[$a].cooccurs += $b }
            if ($a -notin $conceptMap[$b].cooccurs) { $conceptMap[$b].cooccurs += $a }
        }
    }
}

# Build connections from co-occurrence data
$connections = @()
$seen = @{}
foreach ($key in $conceptMap.Keys) {
    foreach ($other in $conceptMap[$key].cooccurs) {
        $edgeKey = ($key, $other | Sort-Object) -join "|"
        if (-not $seen.ContainsKey($edgeKey) -and $conceptMap.ContainsKey($other)) {
            $connections += @{ from = $key; to = $other; strength = 1 }
            $seen[$edgeKey] = $true
        }
    }
}

# Assemble and save
$conceptsObj = [PSCustomObject]@{}
foreach ($key in ($conceptMap.Keys | Sort-Object)) {
    $c = $conceptMap[$key]
    $conceptsObj | Add-Member -NotePropertyName $key -NotePropertyValue ([PSCustomObject]@{
        label    = $c.label
        topic    = $c.topic
        mentions = $c.mentions
        sources  = $c.sources
        related  = $c.cooccurs | Select-Object -First 10
    })
}

$memory = [PSCustomObject]@{
    version     = "1.0"
    last_built  = Get-TodayStr
    notes_scanned = $allFiles.Count
    concepts    = $conceptsObj
    connections = $connections
}
Save-NoEauMemory $memory

$conceptCount = ($conceptsObj.PSObject.Properties | Measure-Object).Count

if (-not $Quiet) {
    Write-Host "  ✓ Memory built: $conceptCount concepts, $($connections.Count) connections" -ForegroundColor Green
    Write-Host "    Saved to: $(Get-NoEauPath 'config\memory.json')" -ForegroundColor DarkGray
    Write-Host ""
}
