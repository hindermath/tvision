<#
.SYNOPSIS
Bereitet MSL-basierte Level-2-Repositories fuer spaetere Secure-Development-Haertung vor.

Prepares MSL-based level-2 repositories for later secure-development hardening runs.

.DESCRIPTION
Dieses Skript findet Level-2-Repositories unter dem Home-Verzeichnis, prueft die
Primaersprache gegen die MSL-Allowlist, synchronisiert bei MSL-Repositories
`docs/secure-development/`, erzeugt ein Intake-Lastenheft und pflegt die
sichtbare Reihenfolge der `Lastenheft*.md`-Dateien.

Es startet keinen Spec-Kit-Lauf, erzeugt keine Feature-Branches und befuellt
keine projektspezifischen `docs/security/`-Nachweise.

This script discovers level-2 repositories below the home directory, checks the
primary language against the MSL allow-list, synchronizes `docs/secure-development/`
for MSL repositories, creates an intake requirements document, and maintains the
visible order of `Lastenheft*.md` files.

It does not start a Spec Kit run, does not create feature branches, and does not
populate project-specific `docs/security/` evidence files.

.PARAMETER HomeDir
Home-Verzeichnis, unter dem Level-1- und Level-2-Repositories gesucht werden.

Home directory below which level-1 and level-2 repositories are discovered.

.PARAMETER Repo
Explizite Level-2-Repositories, die vorbereitet werden sollen. Kann mehrfach
oder als Array uebergeben werden.

Explicit level-2 repositories to prepare. Can be passed multiple times or as an
array.

.PARAMETER PrimaryLanguage
Explizite Primaersprache, wenn Auto-Erkennung aus Constitution oder Dateien
nicht ausreichend ist.

Explicit primary language when auto-detection from constitution or files is not
sufficient.

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
pwsh scripts/prepare-secure-development-hardening.ps1 -WhatIf

.EXAMPLE
pwsh scripts/prepare-secure-development-hardening.ps1 -Repo /Users/thorstenhindermann/RiderProjects/TuiVision -WhatIf

.EXAMPLE
pwsh scripts/prepare-secure-development-hardening.ps1 -HomeDir /Users/thorstenhindermann -Commit -Push
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$HomeDir = $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }),
    [string[]]$Repo = @(),
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

function Test-Level2Repo {
    param([string]$Repo)
    if (-not (Test-Path (Join-Path $Repo '.git'))) { return $false }
    if (Test-Path (Join-Path $Repo '.specify')) { return $true }
    if (Test-Path (Join-Path $Repo 'AGENTS.md')) { return $true }
    if (Test-Path (Join-Path $Repo 'CLAUDE.md')) { return $true }
    return $false
}

function Get-Level2Repos {
    param([string]$Root)
    $repos = [System.Collections.Generic.List[string]]::new()
    Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $workspace = $_.FullName
        if (-not (Test-Path (Join-Path $workspace '.git'))) { return }
        Get-ChildItem -Path $workspace -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-Level2Repo $_.FullName) {
                $repos.Add($_.FullName)
            }
        }
    }
    return $repos
}

function Invoke-CommitAndPush {
    param([string]$Repo)

    if (-not $Commit -and -not $Push) { return }

    if ($WhatIfPreference) {
        if ($Commit) { Write-Host '  [WhatIf] git add docs/secure-development Lastenheft_Secure-Development-Hardening.md Lastenheft_Abarbeitungsreihenfolge.md && git commit' }
        if ($Push) { Write-Host '  [WhatIf] git push origin <branch>' }
        return
    }

    git -C $Repo add docs/secure-development Lastenheft_Secure-Development-Hardening.md Lastenheft_Abarbeitungsreihenfolge.md
    git -C $Repo diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check fehlgeschlagen in $Repo" }

    git -C $Repo diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git -C $Repo commit -m 'docs: prepare secure development hardening'
        if ($LASTEXITCODE -ne 0) { throw "git commit fehlgeschlagen in $Repo" }
    }

    if ($Push) {
        $branch = ((git -C $Repo branch --show-current) | Out-String).Trim()
        if (-not $branch) { throw "Kein aktueller Branch in $Repo" }
        git -C $Repo push origin $branch
        if ($LASTEXITCODE -ne 0) { throw "git push fehlgeschlagen in $Repo" }
    }
}

function Invoke-PrepareRepo {
    param([string]$Repo)

    $projectName = Split-Path -Leaf $Repo
    Write-Host "## $Repo"

    if (-not $WhatIfPreference -and -not $AllowDirty) {
        $status = ((git -C $Repo status --short) | Out-String).Trim()
        if ($status) {
            throw "Repo hat lokale Aenderungen: $Repo"
        }
    }

    $ok = Invoke-SdhPrepareRepo `
        -Repo $Repo `
        -ProjectName $projectName `
        -PrimaryLanguage $PrimaryLanguage `
        -ScriptDir $ScriptDir `
        -WhatIfMode:$WhatIfPreference

    if (-not $ok) {
        throw $script:SdhPrepareReason
    }

    switch ($script:SdhPrepareResult) {
        'prepared' {
            Write-Host "  vorbereitet: $script:SdhPrepareReason"
            Invoke-CommitAndPush -Repo $Repo
        }
        'skipped' {
            Write-Host "  uebersprungen: $script:SdhPrepareReason"
        }
        default {
            Write-Host "  Status: $script:SdhPrepareResult $script:SdhPrepareReason"
        }
    }
}

if ($Repo.Count -gt 0) {
    $explicitRepos = @(
        $Repo |
            ForEach-Object { $_ -split ',' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
    $repos = @($explicitRepos | Where-Object { Test-Level2Repo $_ } | Select-Object -Unique)
} else {
    $repos = @(Get-Level2Repos -Root $HomeDir)
}

Write-Host 'Secure-Development-Hardening Vorbereitung'
Write-Host "  Home             : $HomeDir"
if ($Repo.Count -gt 0) { Write-Host "  Repos            : $($repos.Count) explizit" }
Write-Host "  Primaersprache   : $(if ($PrimaryLanguage) { $PrimaryLanguage } else { 'auto' })"
Write-Host "  Commit           : $Commit"
Write-Host "  Push             : $Push"
Write-Host "  WhatIf           : $WhatIfPreference"
Write-Host ''

if ($repos.Count -eq 0) {
    throw 'Keine Level-2-Repos gefunden'
}

foreach ($repo in $repos) {
    Invoke-PrepareRepo -Repo $repo
}

Write-Host ''
Write-Host 'Secure-Development-Hardening Vorbereitung abgeschlossen.'
