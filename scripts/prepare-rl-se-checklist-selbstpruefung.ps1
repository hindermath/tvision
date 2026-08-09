<#
.SYNOPSIS
Bereitet Repositories fuer spaetere RL-SE-/Checklist-Selbstpruefung vor.

Prepares repositories for later RL-SE / checklist self-assessment runs.

.DESCRIPTION
Dieses Skript findet Repositories unter dem Home-Verzeichnis oder nutzt explizit
uebergebene Repositories. Es synchronisiert die zentrale
Secure-Development-Basis, erzeugt bei Bedarf
`Lastenheft_RL-SE-Checklist-Selbstpruefung.md` und pflegt
`Lastenheft_Abarbeitungsreihenfolge.md`.

Die Vorbereitung ist nicht auf MSL-Repositories beschraenkt. MSL-Status ist ein
Pruefpunkt des spaeteren Laufs, aber keine Voraussetzung fuer diese
Selbstpruefung.

This script discovers repositories below the home directory or uses explicitly
provided repositories. It synchronizes the central secure-development baseline,
creates `Lastenheft_RL-SE-Checklist-Selbstpruefung.md` when missing, and
maintains `Lastenheft_Abarbeitungsreihenfolge.md`.

The preparation is not limited to MSL repositories. MSL status is a checkpoint
of the later run, but not a prerequisite for this self-assessment.

.PARAMETER HomeDir
Home-Verzeichnis, unter dem Level-1- und Level-2-Repositories gesucht werden.

Home directory below which level-1 and level-2 repositories are discovered.

.PARAMETER Repo
Explizite Repositories, die vorbereitet werden sollen. Kann mehrfach oder als
Array uebergeben werden.

Explicit repositories to prepare. Can be passed multiple times or as an array.

.PARAMETER Registry
Pfad zum lokalen Level-2-Register. Standard ist
`~/.home-baseline/level2-repository-registry.json`.

Path to the local level-2 registry. The default is
`~/.home-baseline/level2-repository-registry.json`.

.PARAMETER Discover
Sucht anstelle des Registers unter HomeDir nach Repositories.

Discovers repositories below HomeDir instead of using the registry.

.PARAMETER BaselineOnly
Synchronisiert nur `docs/secure-development/` und verändert keine Lastenhefte.

Synchronizes only `docs/secure-development/` and does not change Lastenhefte.

.PARAMETER PrimaryLanguage
Optionale Primaersprache als Kontextinformation. Sie blockiert die Vorbereitung
nicht.

Optional primary language as context information. It does not gate preparation.

.PARAMETER Commit
Commitet geaenderte Dateien pro Repository.

Commits changed files per repository.

.PARAMETER Push
Pusht den aktuellen Branch nach dem Commit. Aktiviert Commit automatisch.

Pushes the current branch after the commit. Implies Commit.

.PARAMETER AllowDirty
Erlaubt vorhandene lokale Aenderungen in Ziel-Repositories.

Allows existing local changes in target repositories.

.EXAMPLE
pwsh scripts/prepare-rl-se-checklist-selbstpruefung.ps1 -WhatIf

.EXAMPLE
pwsh scripts/prepare-rl-se-checklist-selbstpruefung.ps1 -Repo /Users/thorstenhindermann/RiderProjects/TuiVision -WhatIf

.EXAMPLE
pwsh scripts/prepare-rl-se-checklist-selbstpruefung.ps1 -HomeDir /Users/thorstenhindermann -Commit -Push
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$HomeDir = $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }),
    [string[]]$Repo = @(),
    [string]$Registry = $(Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) '.home-baseline/level2-repository-registry.json'),
    [switch]$Discover,
    [switch]$BaselineOnly,
    [string]$PrimaryLanguage = '',
    [switch]$Commit,
    [switch]$Push,
    [switch]$AllowDirty
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibFile = Join-Path $ScriptDir 'lib/secure-development-hardening.ps1'
if (-not (Test-Path $LibFile)) {
    throw "Hilfsbibliothek nicht gefunden / helper library not found: $LibFile"
}
. $LibFile

if ($Push) { $Commit = $true }

function Test-RlSeTargetRepo {
    param([string]$Repo)
    if (-not (Test-Path (Join-Path $Repo '.git'))) { return $false }
    if (Test-Path (Join-Path $Repo '.specify')) { return $true }
    if (Test-Path (Join-Path $Repo 'AGENTS.md')) { return $true }
    if (Test-Path (Join-Path $Repo 'CLAUDE.md')) { return $true }
    return $false
}

function Get-RlSeTargetRepos {
    param([string]$Root)
    $repos = [System.Collections.Generic.List[string]]::new()
    Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $workspace = $_.FullName
        if (-not (Test-Path (Join-Path $workspace '.git'))) { return }
        Get-ChildItem -Path $workspace -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-RlSeTargetRepo $_.FullName) {
                $repos.Add($_.FullName)
            }
        }
    }
    return $repos
}

function Get-RlSeTemplateFile {
    $repoDir = Split-Path -Parent $ScriptDir
    foreach ($candidate in @(
        (Join-Path $ScriptDir 'templates/rl-se-checklist-selbstpruefung-lastenheft.md'),
        (Join-Path $repoDir 'scripts/templates/rl-se-checklist-selbstpruefung-lastenheft.md'),
        (Join-Path $HOME 'scripts/templates/rl-se-checklist-selbstpruefung-lastenheft.md'),
        (Join-Path $HOME 'home-baseline-source/scripts/templates/rl-se-checklist-selbstpruefung-lastenheft.md')
    )) {
        if (Test-Path $candidate) { return $candidate }
    }
    return ''
}

function Invoke-RlSeCommitAndPush {
    param([string]$Repo)

    if (-not $Commit -and -not $Push) { return }

    if ($WhatIfPreference) {
        if ($Commit -and $BaselineOnly) { Write-Host '  [WhatIf] git add docs/secure-development && git commit' }
        elseif ($Commit) { Write-Host '  [WhatIf] git add docs/secure-development Lastenheft_RL-SE-Checklist-Selbstpruefung.md Lastenheft_Abarbeitungsreihenfolge.md && git commit' }
        if ($Push) { Write-Host '  [WhatIf] git push origin <branch>' }
        return
    }

    if ($BaselineOnly) { git -C $Repo add docs/secure-development }
    else { git -C $Repo add docs/secure-development Lastenheft_RL-SE-Checklist-Selbstpruefung.md Lastenheft_Abarbeitungsreihenfolge.md }
    git -C $Repo diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check fehlgeschlagen in $Repo" }

    git -C $Repo diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        $message = if ($BaselineOnly) { 'docs: update secure development baseline to 3.0.0' } else { 'docs: prepare RL-SE checklist self-assessment' }
        git -C $Repo commit -m $message
        if ($LASTEXITCODE -ne 0) { throw "git commit fehlgeschlagen in $Repo" }
    }

    if ($Push) {
        $branch = ((git -C $Repo branch --show-current) | Out-String).Trim()
        if (-not $branch) { throw "Kein aktueller Branch in $Repo" }
        git -C $Repo push origin $branch
        if ($LASTEXITCODE -ne 0) { throw "git push fehlgeschlagen in $Repo" }
    }
}

function Invoke-RlSePrepareRepo {
    param([string]$Repo)

    $projectName = Split-Path -Leaf $Repo
    Write-Host "## $Repo"

    if (-not $WhatIfPreference -and -not $AllowDirty) {
        $status = ((git -C $Repo status --short) | Out-String).Trim()
        if ($status) {
            throw "Repo hat lokale Aenderungen: $Repo"
        }
    }

    $sourceDir = Get-SdhSourceDir -ScriptDir $ScriptDir
    $templateFile = Get-RlSeTemplateFile
    if (-not $sourceDir) { throw 'docs/secure-development Quelle nicht gefunden' }
    if (-not $templateFile) { throw 'RL-SE-/Checklist-Selbstpruefungs-Template nicht gefunden' }

    $language = Get-SdhPrimaryLanguage -Repo $Repo -ProjectName $projectName -ExplicitLanguage $PrimaryLanguage
    if (-not $language) { $language = 'unklar / unknown' }
    Write-Host "  Sprache / language: $language"

    $targetDocs = Join-Path $Repo 'docs/secure-development'
    $intakeFile = Join-Path $Repo 'Lastenheft_RL-SE-Checklist-Selbstpruefung.md'

    if ($WhatIfPreference) {
        Sync-SdhBaseline -SourceDir $sourceDir -TargetDir $targetDocs -WhatIfMode
    } else {
        Sync-SdhBaseline -SourceDir $sourceDir -TargetDir $targetDocs
    }

    if ($BaselineOnly) {
        Invoke-RlSeCommitAndPush -Repo $Repo
        return
    }

    if ((Test-Path $intakeFile)) {
        if ($WhatIfPreference) { Write-Host '  [WhatIf] Lastenheft vorhanden, wird nicht ueberschrieben: Lastenheft_RL-SE-Checklist-Selbstpruefung.md' }
    } else {
        if ($WhatIfPreference) {
            Write-Host '  [WhatIf] Lastenheft_RL-SE-Checklist-Selbstpruefung.md erzeugen'
        } else {
            Write-SdhRenderedTemplate -Template $templateFile -Output $intakeFile -ProjectName $projectName
        }
    }

    $changedOrder = Update-SdhOrderFile -Repo $Repo -WhatIfMode:$WhatIfPreference
    if ($WhatIfPreference) {
        if ($changedOrder) { Write-Host '  [WhatIf] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren' }
        else { Write-Host '  [WhatIf] Lastenheft_Abarbeitungsreihenfolge.md unveraendert' }
    }

    Invoke-RlSeCommitAndPush -Repo $Repo
}

if ($Repo.Count -gt 0) {
    $explicitRepos = @(
        $Repo |
            ForEach-Object { $_ -split ',' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
    $repos = @($explicitRepos | Where-Object { Test-RlSeTargetRepo $_ } | Select-Object -Unique)
} else {
    if ($Discover) {
        $repos = @(Get-RlSeTargetRepos -Root $HomeDir)
    } else {
        if (-not (Test-Path $Registry)) { throw "Registry nicht gefunden: $Registry (alternativ -Discover nutzen)" }
        $registryData = Get-Content $Registry -Raw | ConvertFrom-Json
        $repos = @(
            $registryData.repositories |
                Where-Object { $_.level -eq 2 -and $_.gsdbRequired -eq $true } |
                ForEach-Object {
                    if ([IO.Path]::IsPathRooted($_.path)) { $_.path } else { Join-Path $HomeDir $_.path }
                } |
                Where-Object { Test-RlSeTargetRepo $_ } |
                Select-Object -Unique
        )
    }
}

Write-Host 'RL-SE-/Checklist-Selbstpruefung Vorbereitung'
Write-Host "  Home             : $HomeDir"
if ($Repo.Count -gt 0) { Write-Host "  Repos            : $($repos.Count) explizit" }
Write-Host "  Primaersprache   : $(if ($PrimaryLanguage) { $PrimaryLanguage } else { 'auto/optional' })"
Write-Host "  Registry         : $Registry"
Write-Host "  Discover         : $Discover"
Write-Host "  Baseline only    : $BaselineOnly"
Write-Host "  Commit           : $Commit"
Write-Host "  Push             : $Push"
Write-Host "  WhatIf           : $WhatIfPreference"
Write-Host ''

if ($repos.Count -eq 0) {
    throw 'Keine Ziel-Repositories gefunden'
}

foreach ($repo in $repos) {
    Invoke-RlSePrepareRepo -Repo $repo
}

Write-Host ''
Write-Host 'RL-SE-/Checklist-Selbstpruefung Vorbereitung abgeschlossen.'
