#Requires -Version 7
<#
.SYNOPSIS
    Propagiert Security-Guidance-Updates aus Level-0 auf Level-1/Level-2-Repos.
    Propagates security guidance updates from Level-0 to Level-1/Level-2 repos.

.DESCRIPTION
    Ruft das Bash-Äquivalent über WSL2 auf (empfohlener Weg auf Windows).
    Alternativ kann das Script manuell portiert werden — die Bash-Version ist kanonisch.

    Calls the Bash equivalent via WSL2 (recommended on Windows).
    Alternatively the script can be ported manually — the Bash version is canonical.

    Für eine vollständige native PowerShell-Implementierung: TODO (separate Aufgabe).
    For a full native PowerShell implementation: TODO (separate task).

.PARAMETER DryRun
    Vorschau ohne Schreiben / Preview without writing.

.PARAMETER Verbose
    Auch unveränderte Dateien anzeigen / Show unchanged files too.

.PARAMETER OnlyLevel1
    Nur Level-1-Repos / Level-1 repos only.

.PARAMETER OnlyConstitution
    Nur constitution.md-Dateien / Only constitution.md files.

.PARAMETER OnlyEnvironmentRegistry
    Nur das Level-2-Umgebungsregister / Only the Level-2 environment registry.

.EXAMPLE
    # Empfohlen auf Windows mit WSL2 / Recommended on Windows with WSL2:
    wsl bash ~/scripts/propagate-security-guidance.sh --dry-run

    # Dieses Script (Wrapper):
    pwsh -NoProfile ~/scripts/propagate-security-guidance.ps1 -DryRun
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun,
    [switch]$OnlyLevel1,
    [switch]$OnlyConstitution,
    [switch]$OnlyEnvironmentRegistry
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# WSL2-Prüfung / WSL2 check
$wslAvailable = $false
try {
    $null = Get-Command wsl -ErrorAction Stop
    $wslAvailable = $true
} catch {
    Write-Verbose "WSL ist nicht verfuegbar / is unavailable: $($_.Exception.Message)"
}

if (-not $wslAvailable) {
    Write-Error @"
Dieses Script erfordert WSL2 mit Ubuntu. Alternativ direkt in WSL ausführen:
  wsl bash ~/scripts/propagate-security-guidance.sh --dry-run

This script requires WSL2 with Ubuntu. Alternatively run directly in WSL:
  wsl bash ~/scripts/propagate-security-guidance.sh --dry-run

Eine vollständige native PowerShell-Implementierung ist geplant (TODO).
A full native PowerShell implementation is planned (TODO).
"@
    exit 1
}

$args_to_pass = @()
if ($DryRun)            { $args_to_pass += '--dry-run' }
if ($OnlyLevel1)        { $args_to_pass += '--only-level1' }
if ($OnlyConstitution)  { $args_to_pass += '--only-constitution' }
if ($OnlyEnvironmentRegistry) { $args_to_pass += '--only-environment-registry' }
if ($VerbosePreference -ne 'SilentlyContinue') { $args_to_pass += '--verbose' }

$bashCmd = "bash ~/scripts/propagate-security-guidance.sh " + ($args_to_pass -join ' ')

if ($WhatIfPreference) {
    Write-Host "[WhatIf] Würde ausführen / Would execute: wsl $bashCmd"
    exit 0
}

wsl bash -c $bashCmd
exit $LASTEXITCODE
