#Requires -Version 7
<#
.SYNOPSIS
    Prueft die Antigravity-Migration in Level-0/1/2-Repositories.
    Audits the Antigravity migration across Level-0/1/2 repositories.
.DESCRIPTION
    Prueft Spec-Kit-Manifeste, Skills, Gitignore-Schutz, MCP-Tracking und aktive
    Gemini-CLI-Aufrufe. Abgeschlossene Specs und Wartungshistorie sind ausgenommen.

    Checks Spec Kit manifests, skills, gitignore protection, MCP tracking, and
    active Gemini CLI invocations. Completed specs and maintenance history are excluded.
.PARAMETER HomeDir
    Zu pruefendes Home-Verzeichnis. Standard: HOME oder USERPROFILE.
.PARAMETER Json
    Gibt den Bericht als JSON aus.
.PARAMETER FailOnOpen
    Liefert Exit-Code 2, wenn offene Befunde vorhanden sind.
.EXAMPLE
    pwsh -NoProfile -File scripts/audit-antigravity-migration.ps1 -FailOnOpen
#>
[CmdletBinding()]
param(
    [string] $HomeDir = $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }),
    [switch] $Json,
    [switch] $FailOnOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'lib/resolve-home-baseline-source.ps1')
$level0Source = Resolve-HBSourceRepository -StartPath $MyInvocation.MyCommand.Path -AllowLegacy

function Test-HBSpecRepository {
    param([Parameter(Mandatory)][string] $Path)
    return (Test-Path (Join-Path $Path '.git')) -and (Test-Path (Join-Path $Path '.specify'))
}

function Get-HBRepositories {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string] $Level0
    )
    $items = [System.Collections.Generic.List[object]]::new()
    if (Test-HBSpecRepository -Path $Level0) {
        $items.Add([pscustomobject]@{ Level = 0; Path = $Level0 })
    }
    foreach ($workspace in Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | Sort-Object FullName) {
        if ($workspace.FullName -eq $Level0 -or -not (Test-HBSpecRepository -Path $workspace.FullName)) { continue }
        $items.Add([pscustomobject]@{ Level = 1; Path = $workspace.FullName })
        foreach ($project in Get-ChildItem -Path $workspace.FullName -Directory -ErrorAction SilentlyContinue | Sort-Object FullName) {
            if (Test-HBSpecRepository -Path $project.FullName) {
                $items.Add([pscustomobject]@{ Level = 2; Path = $project.FullName })
            }
        }
    }
    return $items
}

function Get-HBActiveGeminiReferences {
    param([Parameter(Mandatory)][string] $Repository)
    $patterns = @('(?m)^\s*(?:\$\s*)?gemini(?:\s|$)', '--integration(?:=|\s+)gemini\b', 'setup-gemini-settings')
    $files = @(& git -C $Repository ls-files)
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($relative in $files) {
        if ($relative -eq 'CHANGELOG.md' -or
            $relative -eq 'docs/project-statistics.md' -or
            $relative.StartsWith('docs/maintenance/') -or
            $relative.StartsWith('docs/bug-reports/') -or
            $relative.StartsWith('docs/learning-units/dist/') -or
            $relative.StartsWith('specs/') -or
            (Split-Path $relative -Leaf).StartsWith('Lastenheft') -or
            $relative.StartsWith('scripts/audit-antigravity-migration.')) { continue }
        if ([IO.Path]::GetExtension($relative) -notin @('.md', '.txt', '.sh', '.ps1', '.json', '.toml', '.yml', '.yaml')) { continue }
        $path = Join-Path $Repository $relative
        if (-not (Test-Path $path -PathType Leaf)) { continue }
        try { $content = Get-Content -Path $path -Raw -ErrorAction Stop }
        catch { continue }
        if ($patterns | Where-Object { $content -match $_ }) { $hits.Add($relative) }
    }
    return @($hits | Sort-Object -Unique)
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($repo in Get-HBRepositories -Root (Resolve-Path $HomeDir).ProviderPath -Level0 $level0Source) {
    $findings = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path (Join-Path $repo.Path '.specify/integrations/agy.manifest.json'))) {
        $findings.Add('missing agy integration manifest')
    }
    if (Test-Path (Join-Path $repo.Path '.specify/integrations/gemini.manifest.json')) {
        $findings.Add('legacy gemini integration manifest present')
    }
    if (Test-Path (Join-Path $repo.Path '.gemini/commands')) {
        $findings.Add('legacy .gemini/commands present')
    }
    $skills = Get-ChildItem -Path (Join-Path $repo.Path '.agents/skills') -Directory -Filter 'speckit-*' -ErrorAction SilentlyContinue
    if (-not $skills) { $findings.Add('missing .agents/skills/speckit-*') }
    $gitignore = Join-Path $repo.Path '.gitignore'
    if (-not (Test-Path $gitignore)) {
        $findings.Add('missing .gitignore')
    } else {
        $ignoreText = Get-Content $gitignore -Raw
        if (-not $ignoreText.Contains('.agents/*') -or -not $ignoreText.Contains('!.agents/skills/')) {
            $findings.Add('unsafe or incomplete .agents gitignore allowlist')
        }
    }
    & git -C $repo.Path ls-files --error-unmatch .agents/mcp_config.json *> $null
    if ($LASTEXITCODE -eq 0) { $findings.Add('tracked .agents/mcp_config.json') }
    foreach ($relative in Get-HBActiveGeminiReferences -Repository $repo.Path) {
        $findings.Add("active Gemini CLI reference: $relative")
    }
    $results.Add([pscustomobject]@{
        level = $repo.Level
        repository = $repo.Path
        status = $(if ($findings.Count -eq 0) { 'PASS' } else { 'FAIL' })
        findings = @($findings)
    })
}

$summary = [ordered]@{
    repositories = $results.Count
    passed = @($results | Where-Object status -eq 'PASS').Count
    failed = @($results | Where-Object status -eq 'FAIL').Count
    openFindings = [int](($results | ForEach-Object { $_.findings.Count } | Measure-Object -Sum).Sum ?? 0)
}
$report = [ordered]@{ summary = $summary; results = @($results) }
if ($Json) {
    $report | ConvertTo-Json -Depth 8
} else {
    Write-Host 'Antigravity Migration Audit'
    foreach ($item in $results) {
        Write-Host "[$($item.status)] Level-$($item.level) $($item.repository)"
        $item.findings | ForEach-Object { Write-Host "  - $_" }
    }
    Write-Host "Summary: repositories=$($summary.repositories) passed=$($summary.passed) failed=$($summary.failed) open=$($summary.openFindings)"
}
if ($FailOnOpen -and $summary.openFindings -gt 0) { exit 2 }
