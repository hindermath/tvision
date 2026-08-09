#Requires -Version 7
<#
.SYNOPSIS
    Erstellt lokale Agent-Audit-Snapshots und korreliert spaetere Aenderungen mit Agent-Logs.
    Creates local agent audit snapshots and correlates later changes with agent logs.

.DESCRIPTION
    Das Skript verfolgt agentverwaltete Dateien unter dem Home-Verzeichnis, speichert
    eine lokale Baseline und erzeugt bei spaeteren Vergleichen einen JSON-Report mit
    Heuristiken fuer Codex, Claude, Copilot und Continue.

    The script tracks agent-managed files below the home directory, stores a local
    baseline, and generates a JSON report with heuristics for Codex, Claude, Copilot,
    and Continue during later comparisons.

.PARAMETER Action
    snapshot oder report.
    snapshot or report.

.PARAMETER HomeDir
    Home-Verzeichnis fuer die Pruefung.
    Home directory to inspect.

.PARAMETER StateDir
    Lokales Audit-Verzeichnis fuer Baselines und Reports.
    Local audit directory for baselines and reports.

.PARAMETER WindowHours
    Zeitfenster in Stunden fuer die Log-Korrelation.
    Time window in hours for log correlation.

.PARAMETER Json
    Gibt den kompletten JSON-Report aus.
    Prints the full JSON report.

.PARAMETER RefreshBaseline
    Akzeptiert den aktuellen Zustand nach einem Report als neue Baseline.
    Accepts the current state as the new baseline after a report.

.EXAMPLE
    pwsh -NoProfile scripts/audit-agent-changes.ps1 -Action snapshot

.EXAMPLE
    pwsh -NoProfile scripts/audit-agent-changes.ps1 -Action report -RefreshBaseline
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('snapshot', 'report')]
    [string] $Action = 'report',

    [string] $HomeDir = $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }),

    [string] $StateDir = $(Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) '.home-baseline/agent-audit'),

    [int] $WindowHours = 4,

    [switch] $Json,

    [switch] $RefreshBaseline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$MonitoredSpecs = @(
    @{ Kind = 'tree'; Path = '.agents' },
    @{ Kind = 'tree'; Path = '.github/agents' },
    @{ Kind = 'tree'; Path = '.github/prompts' },
    @{ Kind = 'tree'; Path = '.claude/commands' },
    @{ Kind = 'file'; Path = '.gemini/antigravity-cli/settings.json' },
    @{ Kind = 'file'; Path = '.codex/config.toml' },
    @{ Kind = 'file'; Path = '.claude/settings.json' },
    @{ Kind = 'file'; Path = '.copilot/config.json' },
    @{ Kind = 'file'; Path = '.continue/config.yaml' },
    @{ Kind = 'file'; Path = '.continue/config.json' }
)

$AppSources = @{
    Antigravity = @('.gemini/antigravity-cli/history', '.gemini/antigravity-cli/logs')
    Codex    = @('.codex/history.jsonl', '.codex/log/codex-tui.log')
    Claude   = @('.claude/history.jsonl', '.claude/projects', '.claude/file-history')
    Copilot  = @('.copilot/command-history-state.json', '.copilot/logs')
    Continue = @('.continue/input_history.json', '.continue/logs')
}

$StopTerms = @(
    'agents', 'skills', 'commands', 'github', 'prompts', 'config', 'settings',
    'templates', 'scripts', 'file', 'json', 'yaml', 'yml', 'toml', 'md', 'ps1', 'sh'
)

function Get-IsoTimestamp {
    param(
        [Parameter(Mandatory)]
        [datetime] $Date
    )

    return $Date.ToString('o')
}

function Get-FileSha256 {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-AuditDate {
    param(
        [Parameter(Mandatory)]
        [object] $Value
    )

    if ($Value -is [datetime]) {
        return $Value
    }

    if ($Value -is [datetimeoffset]) {
        return $Value.DateTime
    }

    return [datetimeoffset]::Parse(
        [string] $Value,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::RoundtripKind
    ).DateTime
}

function Get-MonitoredFiles {
    param(
        [Parameter(Mandatory)]
        [string] $RootHome
    )

    $items = [System.Collections.Generic.List[object]]::new()

    foreach ($spec in $MonitoredSpecs) {
        $target = Join-Path $RootHome $spec.Path
        if ($spec.Kind -eq 'file') {
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $items.Add((Get-Item -LiteralPath $target))
            }
            continue
        }

        if (-not (Test-Path -LiteralPath $target -PathType Container)) {
            continue
        }

        Get-ChildItem -LiteralPath $target -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
            $items.Add($_)
        }
    }

    return $items
}

function New-AuditSnapshot {
    param(
        [Parameter(Mandatory)]
        [string] $RootHome
    )

    $root = (Resolve-Path -LiteralPath $RootHome).Path
    $files = [System.Collections.Generic.List[object]]::new()

    foreach ($item in (Get-MonitoredFiles -RootHome $root)) {
        $relative = [IO.Path]::GetRelativePath($root, $item.FullName).Replace('\', '/')
        $files.Add([ordered]@{
            path   = $relative
            size   = $item.Length
            mtime  = (Get-IsoTimestamp -Date $item.LastWriteTime)
            sha256 = (Get-FileSha256 -Path $item.FullName)
        })
    }

    return [ordered]@{
        generatedAt    = (Get-IsoTimestamp -Date (Get-Date))
        homeDir        = $root
        monitoredSpecs = $MonitoredSpecs
        fileCount      = $files.Count
        files          = $files
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [object] $Payload
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Payload | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-FileMap {
    param(
        [Parameter(Mandatory)]
        [object] $Snapshot
    )

    $map = @{}
    foreach ($entry in $Snapshot.files) {
        $map[$entry.path] = $entry
    }
    return $map
}

function Compare-AuditSnapshot {
    param(
        [Parameter(Mandatory)]
        [object] $OldSnapshot,

        [Parameter(Mandatory)]
        [object] $NewSnapshot
    )

    $oldMap = Get-FileMap -Snapshot $OldSnapshot
    $newMap = Get-FileMap -Snapshot $NewSnapshot

    $added = [System.Collections.Generic.List[object]]::new()
    $modified = [System.Collections.Generic.List[object]]::new()
    $deleted = [System.Collections.Generic.List[object]]::new()

    foreach ($path in ($newMap.Keys | Sort-Object)) {
        if (-not $oldMap.ContainsKey($path)) {
            $added.Add([ordered]@{
                path     = $path
                current  = $newMap[$path]
                previous = $null
                mtime    = $newMap[$path].mtime
            })
            continue
        }

        if ($newMap[$path].sha256 -ne $oldMap[$path].sha256) {
            $modified.Add([ordered]@{
                path     = $path
                current  = $newMap[$path]
                previous = $oldMap[$path]
                mtime    = $newMap[$path].mtime
            })
        }
    }

    foreach ($path in ($oldMap.Keys | Sort-Object)) {
        if ($newMap.ContainsKey($path)) {
            continue
        }

        $deleted.Add([ordered]@{
            path     = $path
            current  = $null
            previous = $oldMap[$path]
            mtime    = $oldMap[$path].mtime
        })
    }

    return [ordered]@{
        added    = $added
        modified = $modified
        deleted  = $deleted
    }
}

function Get-ChangeTerms {
    param(
        [Parameter(Mandatory)]
        [object] $Changes
    )

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $terms = [System.Collections.Generic.List[string]]::new()

    foreach ($bucket in @('added', 'modified', 'deleted')) {
        foreach ($entry in $Changes.$bucket) {
            $relative = $entry.path
            $baseName = [IO.Path]::GetFileName($relative)
            foreach ($candidate in @($relative, $baseName)) {
                if ($candidate -and $seen.Add($candidate)) {
                    $terms.Add($candidate)
                }
            }

            foreach ($part in ($relative -split '[\\/._-]+')) {
                if ($part.Length -lt 3) {
                    continue
                }

                if ($StopTerms -contains $part.ToLowerInvariant()) {
                    continue
                }

                if ($seen.Add($part)) {
                    $terms.Add($part)
                }
            }
        }
    }

    return [string[]]@($terms | Select-Object -First 24)
}

function Get-SourceCandidates {
    param(
        [Parameter(Mandatory)]
        [string] $RootHome,

        [Parameter(Mandatory)]
        [string] $RelativePath,

        [Parameter(Mandatory)]
        [datetime] $WindowStart,

        [Parameter(Mandatory)]
        [datetime] $WindowEnd
    )

    $target = Join-Path $RootHome $RelativePath
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        return @(Get-Item -LiteralPath $target)
    }

    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        return @()
    }

    $recent = @(Get-ChildItem -LiteralPath $target -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $WindowStart -and $_.LastWriteTime -le $WindowEnd } |
        Sort-Object LastWriteTime -Descending)

    if ($recent.Count -gt 0) {
        return @($recent | Select-Object -First 6)
    }

    return @(Get-ChildItem -LiteralPath $target -File -Recurse -Force -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 3)
}

function Find-TermHitsInFile {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [AllowNull()]
        [string[]] $Terms
    )

    $hits = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return @()
    }
    if ($null -eq $Terms) {
        $Terms = @()
    }

    $lineNo = 0
    Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction SilentlyContinue | ForEach-Object {
        $lineNo++
        $line = $_
        foreach ($term in $Terms) {
            if ($line.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $excerpt = $line.Trim()
                if ($excerpt.Length -gt 180) {
                    $excerpt = $excerpt.Substring(0, 177) + '...'
                }
                $hit = '{0}:{1}: {2}' -f $Path, $lineNo, $excerpt
                if (-not $hits.Contains($hit)) {
                    $hits.Add($hit)
                }
                break
            }
        }
    }

    return @($hits | Select-Object -First 3)
}

function Get-AppSignals {
    param(
        [Parameter(Mandatory)]
        [string] $RootHome,

        [AllowNull()]
        [string[]] $Terms,

        [Parameter(Mandatory)]
        [datetime] $WindowStart,

        [Parameter(Mandatory)]
        [datetime] $WindowEnd
    )

    if ($null -eq $Terms) {
        $Terms = @()
    }

    $signals = [System.Collections.Generic.List[object]]::new()

    foreach ($appName in ($AppSources.Keys | Sort-Object)) {
        $recentSources = [System.Collections.Generic.List[object]]::new()
        $matchingHits = [System.Collections.Generic.List[string]]::new()
        $latestSeen = $null

        foreach ($relativePath in $AppSources[$appName]) {
            $source = Join-Path $RootHome $relativePath
            if (-not (Test-Path -LiteralPath $source)) {
                continue
            }

            $item = Get-Item -LiteralPath $source
            $sourceMtime = $item.LastWriteTime
            if ($null -eq $latestSeen -or $sourceMtime -gt $latestSeen) {
                $latestSeen = $sourceMtime
            }

            if ($sourceMtime -ge $WindowStart -and $sourceMtime -le $WindowEnd) {
                $recentSources.Add([ordered]@{
                    path  = $relativePath
                    mtime = (Get-IsoTimestamp -Date $sourceMtime)
                })
            }

            foreach ($candidate in (Get-SourceCandidates -RootHome $RootHome -RelativePath $relativePath -WindowStart $WindowStart -WindowEnd $WindowEnd)) {
                foreach ($hit in (Find-TermHitsInFile -Path $candidate.FullName -Terms $Terms)) {
                    if (-not $matchingHits.Contains($hit)) {
                        $matchingHits.Add($hit)
                    }
                    if ($matchingHits.Count -ge 3) {
                        break
                    }
                }
                if ($matchingHits.Count -ge 3) {
                    break
                }
            }
        }

        $signals.Add([ordered]@{
            app           = $appName
            score         = ($matchingHits.Count * 10) + $recentSources.Count
            recentSources = $recentSources
            matchingHits  = $matchingHits
            latestSeen    = if ($latestSeen) { Get-IsoTimestamp -Date $latestSeen } else { $null }
        })
    }

    return @($signals | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = 'app'; Descending = $false })
}

function Render-HumanReport {
    param(
        [Parameter(Mandatory)]
        [object] $Report
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('Agent-Audit Report')
    $lines.Add("Home: $($Report.homeDir)")
    $lines.Add("Baseline: $($Report.baselineFile)")
    $lines.Add("Report: $($Report.reportFile)")
    $lines.Add('')
    $lines.Add("Aenderungen / Changes: $($Report.summary.added) hinzugefuegt / added, $($Report.summary.modified) geaendert / modified, $($Report.summary.deleted) geloescht / deleted")
    $lines.Add('')

    foreach ($bucket in @(
        @{ Label = 'ADDED'; Key = 'added' },
        @{ Label = 'MODIFIED'; Key = 'modified' },
        @{ Label = 'DELETED'; Key = 'deleted' }
    )) {
        $entries = $Report.changes.($bucket.Key)
        if ($entries.Count -eq 0) {
            continue
        }

        $lines.Add($bucket.Label)
        foreach ($entry in $entries) {
            $lines.Add("  $($entry.path)  [$($entry.mtime)]")
        }
        $lines.Add('')
    }

    $lines.Add('Kandidaten / Candidate app signals')
    $shown = 0
    foreach ($signal in $Report.appSignals) {
        if ($signal.score -le 0 -and -not $signal.latestSeen) {
            continue
        }

        $shown++
        $latestLabel = if ($signal.latestSeen) { $signal.latestSeen } else { 'n/a' }
        $lines.Add("- $($signal.app): score=$($signal.score), latest=$latestLabel")
        foreach ($source in $signal.recentSources) {
            $lines.Add("    recent: $($source.path) ($($source.mtime))")
        }
        foreach ($hit in $signal.matchingHits) {
            $lines.Add("    hit: $hit")
        }
    }

    if ($shown -eq 0) {
        $lines.Add('- Keine zuordenbaren Agent-Log-Signale gefunden / No attributable app signals found.')
    }

    if ($Report.baselineRefreshed) {
        $lines.Add('')
        $lines.Add("Neue Baseline / New baseline: $($Report.newBaselineFile)")
    }

    return ($lines -join [Environment]::NewLine)
}

$resolvedHome = (Resolve-Path -LiteralPath $HomeDir).Path
$baselineFile = Join-Path $StateDir 'baseline.json'
$snapshotDir = Join-Path $StateDir 'snapshots'
$reportDir = Join-Path $StateDir 'reports'

if ($PSCmdlet.ShouldProcess($StateDir, 'Audit-Verzeichnisse vorbereiten / Prepare audit directories')) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
    New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$currentSnapshot = New-AuditSnapshot -RootHome $resolvedHome

if ($Action -eq 'snapshot') {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $snapshotFile = Join-Path $snapshotDir "snapshot-$timestamp.json"

    if ($PSCmdlet.ShouldProcess($baselineFile, 'Baseline schreiben / Write baseline')) {
        Write-JsonFile -Path $snapshotFile -Payload $currentSnapshot
        Write-JsonFile -Path $baselineFile -Payload $currentSnapshot
    }

    $result = [ordered]@{
        action       = 'snapshot'
        homeDir      = $resolvedHome
        baselineFile = $baselineFile
        snapshotFile = $snapshotFile
        fileCount    = $currentSnapshot.fileCount
    }

    if ($Json) {
        $result | ConvertTo-Json -Depth 10
        exit 0
    }

    Write-Host 'Agent-Audit Baseline erstellt / baseline created'
    Write-Host "Home: $resolvedHome"
    Write-Host "Dateien / Files: $($currentSnapshot.fileCount)"
    Write-Host "Baseline: $baselineFile"
    Write-Host "Snapshot: $snapshotFile"
    exit 0
}

if (-not (Test-Path -LiteralPath $baselineFile -PathType Leaf)) {
    throw 'Fehler / Error: no baseline found. Run the snapshot action first.'
}

$baseline = Get-Content -LiteralPath $baselineFile -Raw | ConvertFrom-Json -AsHashtable
$changes = Compare-AuditSnapshot -OldSnapshot $baseline -NewSnapshot $currentSnapshot

$changeTimes = [System.Collections.Generic.List[datetime]]::new()
foreach ($bucket in @('added', 'modified', 'deleted')) {
    foreach ($entry in $changes.$bucket) {
        $changeTimes.Add((ConvertTo-AuditDate -Value $entry.mtime))
    }
}

if ($changeTimes.Count -gt 0) {
    $windowStart = ($changeTimes | Measure-Object -Minimum).Minimum.AddHours(-1 * $WindowHours)
    $windowEnd = ($changeTimes | Measure-Object -Maximum).Maximum.AddHours($WindowHours)
} else {
    $windowStart = (Get-Date).AddHours(-1 * $WindowHours)
    $windowEnd = (Get-Date).AddHours($WindowHours)
}

$terms = @(Get-ChangeTerms -Changes $changes)
$signals = Get-AppSignals -RootHome $resolvedHome -Terms $terms -WindowStart $windowStart -WindowEnd $windowEnd

$reportTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportFile = Join-Path $reportDir "report-$reportTimestamp.json"
$report = [ordered]@{
    action          = 'report'
    generatedAt     = (Get-IsoTimestamp -Date (Get-Date))
    homeDir         = $resolvedHome
    stateDir        = $StateDir
    baselineFile    = $baselineFile
    reportFile      = $reportFile
    summary         = [ordered]@{
        added    = $changes.added.Count
        modified = $changes.modified.Count
        deleted  = $changes.deleted.Count
    }
    window          = [ordered]@{
        hours = $WindowHours
        start = (Get-IsoTimestamp -Date $windowStart)
        end   = (Get-IsoTimestamp -Date $windowEnd)
    }
    searchTerms     = $terms
    changes         = $changes
    appSignals      = $signals
    baselineRefreshed = $false
}

if ($PSCmdlet.ShouldProcess($reportFile, 'Report schreiben / Write report')) {
    Write-JsonFile -Path $reportFile -Payload $report
    Write-JsonFile -Path (Join-Path $reportDir 'latest-report.json') -Payload $report
}

if ($RefreshBaseline) {
    $snapshotTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $newSnapshotFile = Join-Path $snapshotDir "snapshot-$snapshotTimestamp.json"
    if ($PSCmdlet.ShouldProcess($baselineFile, 'Baseline aktualisieren / Refresh baseline')) {
        Write-JsonFile -Path $newSnapshotFile -Payload $currentSnapshot
        Write-JsonFile -Path $baselineFile -Payload $currentSnapshot
    }
    $report.baselineRefreshed = $true
    $report.newBaselineFile = $newSnapshotFile
    if ($PSCmdlet.ShouldProcess($reportFile, 'Report mit neuer Baseline aktualisieren / Update report with refreshed baseline')) {
        Write-JsonFile -Path $reportFile -Payload $report
        Write-JsonFile -Path (Join-Path $reportDir 'latest-report.json') -Payload $report
    }
}

if ($Json) {
    $report | ConvertTo-Json -Depth 10
    exit 0
}

Write-Host (Render-HumanReport -Report $report)
