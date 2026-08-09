#Requires -Version 7
<#
.SYNOPSIS
Testet den Renderer fuer ASCII-Statistikprofil 2.

.DESCRIPTION
Erzeugt temporaere Git-Repositories und prueft deterministisch Renderer,
Schema, A11Y-Vertrag, Historienfilter, Phasenaufteilung, Idempotenz und die
Paritaet der Bash- und PowerShell-Einstiegspunkte.

Creates temporary Git repositories and deterministically verifies the renderer,
schema, accessibility contract, history filters, phase splitting, idempotency,
and parity between the Bash and PowerShell entry points.

.EXAMPLE
pwsh -NoProfile -File scripts/test-render-project-statistics.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ScriptRoot = Split-Path -Parent $PSCommandPath
$script:Renderer = Join-Path $script:ScriptRoot 'render-project-statistics.ps1'
$script:BashRenderer = Join-Path $script:ScriptRoot 'render-project-statistics.sh'
$script:Schema = Join-Path $script:ScriptRoot 'config/project-statistics.schema.json'
$script:FixtureRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'home-baseline-statistics-tests-' + [guid]::NewGuid().ToString('N')
)
$script:Passed = 0

function Confirm-TestCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
    $script:Passed++
}

function Invoke-TestProcess {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [hashtable]$Environment = @{}
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Executable
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [Text.Encoding]::UTF8
    $startInfo.StandardErrorEncoding = [Text.Encoding]::UTF8
    foreach ($argument in $Arguments) {
        $null = $startInfo.ArgumentList.Add($argument)
    }
    foreach ($key in $Environment.Keys) {
        $startInfo.Environment[$key] = [string]$Environment[$key]
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    $standardOutput = $process.StandardOutput.ReadToEnd()
    $standardError = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $standardOutput
        StdErr = $standardError
    }
}

function Invoke-TestGit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments,
        [hashtable]$Environment = @{}
    )

    $result = Invoke-TestProcess -Executable 'git' `
        -Arguments (@('-C', $Repository) + $Arguments) `
        -WorkingDirectory $Repository -Environment $Environment
    if ($result.ExitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($result.StdErr)"
    }
    $result.StdOut.Trim()
}

function Add-TestCommit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Date
    )

    $environment = @{
        GIT_AUTHOR_DATE = $Date
        GIT_COMMITTER_DATE = $Date
    }
    $null = Invoke-TestGit -Repository $Repository -Arguments @('add', '--all')
    $null = Invoke-TestGit -Repository $Repository -Arguments @(
        'commit', '-m', $Message
    ) -Environment $environment
}

function Get-TestConfiguration {
    param(
        [Parameter(Mandatory)][string]$Name,
        [object[]]$Phases = @(),
        [string[]]$ExcludedPaths = @(),
        [double]$ThorstenReference = 125
    )

    [ordered]@{
        '$schema' = '../scripts/config/project-statistics.schema.json'
        schemaVersion = 1
        methodologyVersion = 2
        repositoryName = $Name
        timeZone = 'Europe/Berlin'
        activityWindowWeeks = 52
        references = [ordered]@{
            conservativeLinesPerDay = 80
            thorstenLinesPerDay = $ThorstenReference
        }
        phases = $Phases
        excludedPaths = $ExcludedPaths
        categoryOverrides = @()
    }
}

function Write-TestConfiguration {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Configuration
    )

    $json = $Configuration | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText(
        (Join-Path $Repository 'docs/project-statistics.config.json'),
        $json + "`n",
        [Text.UTF8Encoding]::new($false)
    )
}

function Initialize-TestRepository {
    param(
        [Parameter(Mandatory)][string]$Name,
        [object[]]$Phases = @(),
        [string[]]$ExcludedPaths = @(),
        [int]$LargeFileLines = 0
    )

    $repository = Join-Path $script:FixtureRoot $Name
    $null = New-Item -ItemType Directory -Path $repository -Force
    $null = New-Item -ItemType Directory -Path (
        Join-Path $repository 'docs'
    ) -Force
    $null = New-Item -ItemType Directory -Path (
        Join-Path $repository 'scripts/config'
    ) -Force
    Copy-Item -LiteralPath $script:Schema -Destination (
        Join-Path $repository 'scripts/config/project-statistics.schema.json'
    )

    $ledger = @'
# Teststatistik / Test Statistics

## Fortschreibungsprotokoll / Progress Log

| Stand | Wert |
|---|---:|
| Historischer Wert / Historical value | 7 |

## Gesamtstatistik / Overall Statistics

| Alte Kennzahl / Previous metric | Wert / Value |
|---|---:|
| Sichtbarer Bestand / Visible base | 7 |
'@
    [IO.File]::WriteAllText(
        (Join-Path $repository 'docs/project-statistics.md'),
        $ledger.TrimStart() + "`n",
        [Text.UTF8Encoding]::new($false)
    )
    Write-TestConfiguration -Repository $repository -Configuration (
        Get-TestConfiguration -Name $Name -Phases $Phases `
            -ExcludedPaths $ExcludedPaths
    )

    if ($LargeFileLines -gt 0) {
        $null = New-Item -ItemType Directory -Path (
            Join-Path $repository 'src'
        ) -Force
        [IO.File]::WriteAllText(
            (Join-Path $repository 'src/large.txt'),
            ('line' + "`n") * $LargeFileLines,
            [Text.UTF8Encoding]::new($false)
        )
    } else {
        [IO.File]::WriteAllText(
            (Join-Path $repository 'source.txt'),
            "alpha`nbeta`n",
            [Text.UTF8Encoding]::new($false)
        )
    }
    [IO.File]::WriteAllBytes(
        (Join-Path $repository 'binary.dat'),
        [byte[]](0, 1, 2, 3)
    )

    $null = Invoke-TestProcess -Executable 'git' -Arguments @(
        'init', '-b', 'main', $repository
    ) -WorkingDirectory $script:FixtureRoot
    $null = Invoke-TestGit -Repository $repository -Arguments @(
        'config', 'user.name', 'Statistics Test'
    )
    $null = Invoke-TestGit -Repository $repository -Arguments @(
        'config', 'user.email', 'statistics-test@example.invalid'
    )
    Add-TestCommit -Repository $repository -Message 'test: initialize fixture' `
        -Date '2026-07-18T12:00:00+02:00'
    $repository
}

function Invoke-TestRenderer {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [ValidateSet('pwsh', 'bash')][string]$EntryPoint = 'pwsh',
        [string[]]$Options = @()
    )

    $environment = @{ SOURCE_DATE_EPOCH = '1784455200' }
    if ($EntryPoint -eq 'bash') {
        $bashRenderer = $script:BashRenderer
        $bashRepository = $Repository
        if ($IsWindows) {
            $toWslPath = {
                param([string]$Path)
                $resolved = [IO.Path]::GetFullPath($Path)
                $drive = $resolved.Substring(0, 1).ToLowerInvariant()
                $remainder = $resolved.Substring(3).Replace('\', '/')
                return "/mnt/${drive}/${remainder}"
            }
            $bashRenderer = & $toWslPath $script:BashRenderer
            $bashRepository = & $toWslPath $Repository
        }
        return Invoke-TestProcess -Executable 'bash' `
            -Arguments (@($bashRenderer, '--repo', $bashRepository) + $Options) `
            -WorkingDirectory $Repository -Environment $environment
    }
    $mapped = [Collections.Generic.List[string]]::new()
    foreach ($option in $Options) {
        switch ($option) {
            '--check-only' { $mapped.Add('-CheckOnly') }
            '--dry-run' { $mapped.Add('-WhatIf') }
            '--json' { $mapped.Add('-Json') }
            default { throw "Unsupported test option: $option" }
        }
    }
    Invoke-TestProcess -Executable 'pwsh' -Arguments (
        @('-NoProfile', '-File', $script:Renderer, '-Repo', $Repository) +
        $mapped.ToArray()
    ) -WorkingDirectory $Repository -Environment $environment
}

function Confirm-ChartContract {
    param([Parameter(Mandatory)][string]$Ledger)

    $insideTextBlock = $false
    foreach ($line in ($Ledger -split "`r?`n")) {
        if ($line -eq '```text') {
            $insideTextBlock = $true
            continue
        }
        if ($line -eq '```' -and $insideTextBlock) {
            $insideTextBlock = $false
            continue
        }
        if ($insideTextBlock) {
            Confirm-TestCondition -Condition ($line.Length -le 100) `
                -Message 'ASCII chart line is at most 100 characters'
            Confirm-TestCondition -Condition ($line -notmatch '[^\x00-\x7F]') `
                -Message 'ASCII chart contains ASCII characters only'
        }
    }
    Confirm-TestCondition -Condition (-not $insideTextBlock) `
        -Message 'text code blocks are balanced'
    Confirm-TestCondition -Condition ($Ledger -notmatch '[\u2588\u2591\u25A0]') `
        -Message 'ledger contains no forbidden Unicode blocks'
}

function Test-InvalidConfiguration {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Configuration,
        [Parameter(Mandatory)][string]$Name
    )

    $configFile = Join-Path $Repository 'docs/project-statistics.config.json'
    $original = [IO.File]::ReadAllText($configFile)
    try {
        Write-TestConfiguration -Repository $Repository -Configuration $Configuration
        $result = Invoke-TestRenderer -Repository $Repository -Options @(
            '--dry-run', '--json'
        )
        Confirm-TestCondition -Condition ($result.ExitCode -eq 2) `
            -Message "$Name exits with code 2"
    } finally {
        [IO.File]::WriteAllText(
            $configFile,
            $original,
            [Text.UTF8Encoding]::new($false)
        )
    }
}

try {
    $null = New-Item -ItemType Directory -Path $script:FixtureRoot -Force

    $repository = Initialize-TestRepository -Name 'normal'
    $initial = Invoke-TestRenderer -Repository $repository -Options @('--json')
    Confirm-TestCondition -Condition ($initial.ExitCode -eq 0) `
        -Message 'initial rendering succeeds'
    $ledgerFile = Join-Path $repository 'docs/project-statistics.md'
    $ledger = [IO.File]::ReadAllText($ledgerFile)
    Confirm-TestCondition -Condition ($ledger.Contains('project-statistics-v2:begin')) `
        -Message 'generated begin marker exists'
    Confirm-TestCondition -Condition ($ledger.Contains('Statistikprofil-1-Archiv')) `
        -Message 'historical overall statistics are archived'
    Confirm-TestCondition -Condition (
        $ledger.TrimEnd().EndsWith('<!-- project-statistics-v2:end -->')
    ) -Message 'overall statistics remain the final section'
    Confirm-TestCondition -Condition ($ledger.Contains('Monatsvolumen / Monthly Volume')) `
        -Message 'zero phases use the monthly fallback'
    Confirm-TestCondition -Condition ($ledger.Contains(' -')) `
        -Message 'the deterministic partial week marks future days'
    Confirm-ChartContract -Ledger $ledger

    Add-TestCommit -Repository $repository -Message 'docs: render statistics' `
        -Date '2026-07-19T12:15:00+02:00'
    $checkPowerShell = Invoke-TestRenderer -Repository $repository `
        -Options @('--check-only', '--json')
    $checkBash = Invoke-TestRenderer -Repository $repository -EntryPoint bash `
        -Options @('--check-only', '--json')
    Confirm-TestCondition -Condition ($checkPowerShell.ExitCode -eq 0) `
        -Message 'statistics-only commit does not create drift'
    Confirm-TestCondition -Condition ($checkPowerShell.StdOut -ceq $checkBash.StdOut) `
        -Message "Bash and PowerShell JSON status are byte-identical`nPowerShell: $($checkPowerShell.StdOut)`nBash: $($checkBash.StdOut)`nBash stderr: $($checkBash.StdErr)"

    $currentPreviewPowerShell = Invoke-TestRenderer -Repository $repository `
        -Options @('--dry-run')
    $currentPreviewBash = Invoke-TestRenderer -Repository $repository -EntryPoint bash `
        -Options @('--dry-run')
    Confirm-TestCondition -Condition ($currentPreviewPowerShell.ExitCode -eq 0) `
        -Message 'dry-run succeeds when the generated block is already current'
    Confirm-TestCondition -Condition (
        $currentPreviewPowerShell.StdOut.Contains('project-statistics-v2:begin') -and
        $currentPreviewPowerShell.StdOut.Contains('[DRY_RUN]')
    ) -Message 'current dry-run still prints the generated block and dry-run status'
    Confirm-TestCondition -Condition (
        $currentPreviewPowerShell.StdOut -ceq $currentPreviewBash.StdOut
    ) -Message 'current Bash and PowerShell dry-run output is byte-identical'

    foreach ($bootstrapFile in @(
            'bootstrap-workspace.sh',
            'bootstrap-workspace.ps1',
            'bootstrap-project.sh',
            'bootstrap-project.ps1'
        )) {
        $bootstrapContent = [IO.File]::ReadAllText(
            (Join-Path $script:ScriptRoot $bootstrapFile)
        )
        Confirm-TestCondition -Condition (
            $bootstrapContent -match (
                'docs: initialize ASCII statistics profile 2[\s\S]{0,120}' +
                'Co-authored-by: Copilot <223556219\+Copilot@users\.noreply\.github\.com>'
            )
        ) -Message "$bootstrapFile includes the required statistics commit trailer"
    }

    $bashHomogeneity = [IO.File]::ReadAllText(
        (Join-Path $script:ScriptRoot 'check-homogeneity.sh')
    )
    $powerShellHomogeneity = [IO.File]::ReadAllText(
        (Join-Path $script:ScriptRoot 'check-homogeneity.ps1')
    )
    Confirm-TestCondition -Condition (
        $bashHomogeneity.Contains('command -v pwsh') -and
        $powerShellHomogeneity.Contains('Get-Command pwsh')
    ) -Message 'both homogeneity entry points diagnose a missing pwsh executable'

    $null = New-Item -ItemType Directory -Path (
        Join-Path $repository 'src'
    ) -Force
    $null = Invoke-TestGit -Repository $repository -Arguments @(
        'mv', 'source.txt', 'src/renamed.txt'
    )
    [IO.File]::AppendAllText(
        (Join-Path $repository 'src/renamed.txt'),
        "gamma`n",
        [Text.UTF8Encoding]::new($false)
    )
    Add-TestCommit -Repository $repository -Message 'test: rename text file' `
        -Date '2026-07-19T12:30:00+02:00'

    $previewPowerShell = Invoke-TestRenderer -Repository $repository `
        -Options @('--dry-run')
    $previewBash = Invoke-TestRenderer -Repository $repository -EntryPoint bash `
        -Options @('--dry-run')
    Confirm-TestCondition -Condition ($previewPowerShell.StdOut -ceq $previewBash.StdOut) `
        -Message 'Bash and PowerShell generated output are byte-identical'
    Confirm-TestCondition -Condition ($previewPowerShell.StdOut.Contains('2026-07-19')) `
        -Message 'rename activity is grouped into the configured time zone'

    $configuration = Get-TestConfiguration -Name 'normal'
    $configuration.references.conservativeLinesPerDay = 0
    Test-InvalidConfiguration -Repository $repository `
        -Configuration $configuration -Name 'zero reference'

    $configuration = Get-TestConfiguration -Name 'normal'
    $configuration.excludedPaths = @('../outside')
    Test-InvalidConfiguration -Repository $repository `
        -Configuration $configuration -Name 'parent path'

    $configuration = Get-TestConfiguration -Name 'normal'
    $configuration.excludedPaths = @('/absolute/path')
    Test-InvalidConfiguration -Repository $repository `
        -Configuration $configuration -Name 'absolute path'

    $duplicatePhases = @(
        [ordered]@{
            slot = 0
            id = 'first'
            labelDe = 'Erste'
            labelEn = 'First'
            netLines = 1
        },
        [ordered]@{
            slot = 0
            id = 'second'
            labelDe = 'Zweite'
            labelEn = 'Second'
            netLines = 2
        }
    )
    $configuration = Get-TestConfiguration -Name 'normal' -Phases $duplicatePhases
    Test-InvalidConfiguration -Repository $repository `
        -Configuration $configuration -Name 'duplicate phase slot'

    $phases = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt 49; $index++) {
        $phases.Add([ordered]@{
                slot = $index
                id = "phase-$index"
                labelDe = "Phase $index"
                labelEn = "Phase $index"
                netLines = $index + 1
            })
    }
    $phaseRepository = Initialize-TestRepository -Name 'phases-49' `
        -Phases $phases.ToArray()
    $phaseResult = Invoke-TestRenderer -Repository $phaseRepository `
        -Options @('--dry-run')
    Confirm-TestCondition -Condition ($phaseResult.ExitCode -eq 0) `
        -Message '49-phase rendering succeeds'
    Confirm-TestCondition -Condition (
        $phaseResult.StdOut.Contains('Slots 0..15') -and
        $phaseResult.StdOut.Contains('Slots 16..31') -and
        $phaseResult.StdOut.Contains('Slots 32..47') -and
        $phaseResult.StdOut.Contains('Slots 48..48')
    ) -Message 'more than 48 phases split into stable 16-slot blocks'

    $emptyRepository = Initialize-TestRepository -Name 'no-activity' `
        -ExcludedPaths @('*')
    $emptyResult = Invoke-TestRenderer -Repository $emptyRepository `
        -Options @('--dry-run')
    Confirm-TestCondition -Condition ($emptyResult.ExitCode -eq 0) `
        -Message (
            'repository without relevant activity renders: ' +
            $emptyResult.StdOut + $emptyResult.StdErr
        )
    Confirm-TestCondition -Condition (
        $emptyResult.StdOut.Contains('Aktivtage / Active days | 0') -and
        $emptyResult.StdOut.Contains('Keine Aktivitaet / No activity')
    ) -Message 'empty state reports zero activity'

    $largePhase = @([ordered]@{
            slot = 0
            id = 'large'
            labelDe = 'Gross'
            labelEn = 'Large'
            netLines = 50001
        })
    $largeRepository = Initialize-TestRepository -Name 'large-speedup' `
        -Phases $largePhase -LargeFileLines 50001
    $largeResult = Invoke-TestRenderer -Repository $largeRepository `
        -Options @('--dry-run')
    Confirm-TestCondition -Condition ($largeResult.StdOut.Contains('>500x')) `
        -Message 'speedups above 500x are bounded and labelled'

    $null = New-Item -ItemType Directory -Path (
        Join-Path $repository 'branch-work'
    ) -Force
    $null = Invoke-TestGit -Repository $repository -Arguments @(
        'switch', '-c', 'fixture-branch'
    )
    [IO.File]::WriteAllText(
        (Join-Path $repository 'branch-work/branch.txt'),
        "branch`n",
        [Text.UTF8Encoding]::new($false)
    )
    Add-TestCommit -Repository $repository -Message 'test: branch commit' `
        -Date '2026-07-18T13:00:00+02:00'
    $null = Invoke-TestGit -Repository $repository -Arguments @('switch', 'main')
    [IO.File]::WriteAllText(
        (Join-Path $repository 'main.txt'),
        "main`n",
        [Text.UTF8Encoding]::new($false)
    )
    Add-TestCommit -Repository $repository -Message 'test: main commit' `
        -Date '2026-07-18T13:10:00+02:00'
    $mergeEnvironment = @{
        GIT_AUTHOR_DATE = '2026-07-18T13:20:00+02:00'
        GIT_COMMITTER_DATE = '2026-07-18T13:20:00+02:00'
    }
    $null = Invoke-TestGit -Repository $repository -Arguments @(
        'merge', '--no-ff', 'fixture-branch', '-m', 'test: merge fixture'
    ) -Environment $mergeEnvironment
    $mergeResult = Invoke-TestRenderer -Repository $repository `
        -Options @('--dry-run')
    Confirm-TestCondition -Condition ($mergeResult.ExitCode -eq 0) `
        -Message 'merge history renders while merge commits remain excluded'

    Write-Output (
        "PASS: $($script:Passed) assertions; fixtures: $script:FixtureRoot"
    )
} finally {
    if (Test-Path -LiteralPath $script:FixtureRoot) {
        Remove-Item -LiteralPath $script:FixtureRoot -Recurse -Force
    }
}
