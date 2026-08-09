#Requires -Version 7
<#
.SYNOPSIS
    Propagiert Lernreihen-Material aus Level-0 in Level-1/Level-2-Repos.
    Propagates learning-series material from Level-0 into Level-1/Level-2 repos.

.DESCRIPTION
    Ruft das kanonische Bash-Aequivalent ueber WSL2 auf (empfohlener Weg auf Windows).
    Die Bash-Version `propagate-learning-series.sh` ist die maßgebliche Implementierung.

    Calls the canonical Bash equivalent via WSL2 (recommended on Windows).
    The Bash version `propagate-learning-series.sh` is the authoritative implementation.

.PARAMETER DryRun
    Vorschau ohne Schreiben / Preview without writing.

.PARAMETER NoPush
    Committen ohne Push / Commit without pushing.

.PARAMETER Series
    Serien-/Registry-Praefix (Standard: SecureCaseTracker).
    Series/registry prefix (default: SecureCaseTracker).

.PARAMETER FilePrefix
    Datei-Praefix mit Bindestrich (Standard aus Series abgeleitet, z. B. Secure-CaseTracker).
    File prefix with hyphen (default derived from Series, e.g. Secure-CaseTracker).

.PARAMETER HomeDir
    Basisverzeichnis fuer Repos (Standard: ~). / Base directory for repos (default: ~).

.EXAMPLE
    # Empfohlen auf Windows mit WSL2 / Recommended on Windows with WSL2:
    wsl bash ~/scripts/propagate-learning-series.sh --dry-run

    # Dieses Script (Wrapper) / This script (wrapper):
    pwsh -NoProfile ~/scripts/propagate-learning-series.ps1 -DryRun
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun,
    [switch]$NoPush,
    [ValidateNotNullOrEmpty()]
    [string]$Series = 'SecureCaseTracker',
    [string]$FilePrefix = '',
    [string]$HomeDir = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# WSL2-Pruefung / WSL2 check
$wslAvailable = $false
try {
    $null = Get-Command wsl -ErrorAction Stop
    $wslAvailable = $true
} catch {
    Write-Verbose "WSL ist nicht verfuegbar / is unavailable: $($_.Exception.Message)"
}

if (-not $wslAvailable) {
    Write-Error @"
Dieses Script erfordert WSL2 mit Ubuntu. Alternativ direkt in WSL ausfuehren:
  wsl bash ~/scripts/propagate-learning-series.sh --dry-run

This script requires WSL2 with Ubuntu. Alternatively run directly in WSL:
  wsl bash ~/scripts/propagate-learning-series.sh --dry-run

Die Bash-Version ist kanonisch / The Bash version is canonical.
"@
    exit 1
}

# Argumente sicher zusammensetzen / assemble arguments safely (keine Invoke-Expression)
$argsToPass = @()
if ($DryRun) { $argsToPass += '--dry-run' }
if ($NoPush) { $argsToPass += '--no-push' }
if ($Series)     { $argsToPass += @('--series', $Series) }
if ($FilePrefix) { $argsToPass += @('--file-prefix', $FilePrefix) }
if ($HomeDir)    { $argsToPass += @('--home-dir', $HomeDir) }
if ($VerbosePreference -ne 'SilentlyContinue') { $argsToPass += '--verbose' }

$bashCmd = "bash ~/scripts/propagate-learning-series.sh " + ($argsToPass -join ' ')

if ($WhatIfPreference) {
    Write-Host "[WhatIf] Wuerde ausfuehren / Would execute: wsl ${bashCmd}"
    exit 0
}

wsl bash -c $bashCmd
exit $LASTEXITCODE
