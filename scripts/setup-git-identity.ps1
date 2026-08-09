#Requires -Version 7
<#
.SYNOPSIS
    Prüft und richtet die globale Git-Identität ein (Name + E-Mail).
    Checks and configures the global Git identity (name + email).

.DESCRIPTION
    Git-Commits mit Platzhalter-Autor ("Your Name <your@email.example>") entstehen,
    wenn ~/.gitconfig nicht angepasst wurde. Dieses Skript behebt das dauerhaft.

    Git commits with placeholder author ("Your Name <your@email.example>") occur when
    ~/.gitconfig has not been customised. This script fixes that permanently.

    Erkennungsquellen (in Reihenfolge) / Detection sources (in priority order):
      1. gh api user         (GitHub-Profil-Name und E-Mail)
      2. System-Benutzerkonto (Windows: ADSI/WMI; macOS: dscl; Linux: getent)
      3. git log             (Name/E-Mail aus vorhandenen Commits)

.PARAMETER CheckOnly
    Nur prüfen; Exit 1 wenn Platzhalter erkannt. Kein Dialog, keine Änderungen.
    Check only; exit 1 if placeholder detected. No prompt, no changes.

.PARAMETER Auto
    Automatische Erkennung ohne Dialog. Fehler wenn Erkennung unvollständig.
    Auto-detect identity without interactive prompt. Fails if detection is incomplete.

.PARAMETER WhatIf
    Vorschau aller Änderungen ohne Schreiben.
    Preview all changes without writing.

.EXAMPLE
    pwsh -NoProfile ~/scripts/setup-git-identity.ps1
    pwsh -NoProfile ~/scripts/setup-git-identity.ps1 -CheckOnly
    pwsh -NoProfile ~/scripts/setup-git-identity.ps1 -Auto
    pwsh -NoProfile ~/scripts/setup-git-identity.ps1 -WhatIf
#>

param(
    [switch]$CheckOnly,
    [switch]$Auto,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PlaceholderName  = 'Your Name'
$PlaceholderEmail = 'your@email.example'

# --- Hilfsfunktionen / Helper functions ----------------------------------------

function Write-Ok   { param([string]$Msg) Write-Host "✓ $Msg" }
function Write-Info { param([string]$Msg) Write-Host "→ $Msg" }
function Write-HBLog { param([string]$Msg) Write-Host "  $Msg" }

# --- Aktuelle Werte lesen / Read current values --------------------------------

$CurrentName  = git config --global user.name  2>$null
$CurrentEmail = git config --global user.email 2>$null
if (-not $CurrentName)  { $CurrentName  = '' }
if (-not $CurrentEmail) { $CurrentEmail = '' }

# --- Platzhalter-Prüfung / Placeholder detection -------------------------------

$IsPlaceholder = ($CurrentName -eq $PlaceholderName) -or
                 ($CurrentName -eq '')                -or
                 ($CurrentEmail -eq $PlaceholderEmail) -or
                 ($CurrentEmail -eq '')

if (-not $IsPlaceholder) {
    Write-Ok "Git-Identität konfiguriert: $CurrentName <$CurrentEmail>"
    exit 0
}

if ($CheckOnly) {
    Write-Error "Git-Identität enthält Platzhalter:" -ErrorAction Continue
    Write-HBLog "  user.name  = $(if ($CurrentName) { $CurrentName } else { '(leer / empty)' })"
    Write-HBLog "  user.email = $(if ($CurrentEmail) { $CurrentEmail } else { '(leer / empty)' })"
    Write-HBLog ''
    Write-HBLog "Behebung / Fix:"
    Write-HBLog "  pwsh -NoProfile ~/scripts/setup-git-identity.ps1"
    Write-HBLog ''
    Write-HBLog 'Error: Git identity is still at placeholder values.'
    exit 1
}

Write-Info 'Git-Identität nicht konfiguriert oder enthält Platzhalter.'

# --- Automatische Erkennung / Auto-detection -----------------------------------

$DetectedName  = ''
$DetectedEmail = ''

# Quelle 1: gh API
# Source 1: gh API
if (Get-Command gh -ErrorAction SilentlyContinue) {
    & gh auth status *> $null
    if ($LASTEXITCODE -eq 0) {
        $GhName  = gh api user --jq '.name // ""' 2>$null
        $GhEmail = gh api user --jq '.email // ""' 2>$null
        if ($GhName)  { $DetectedName  = $GhName }
        if ($GhEmail) { $DetectedEmail = $GhEmail }
        # GitHub no-reply-Adresse als Fallback / GitHub no-reply address as fallback
        if (-not $DetectedEmail) {
            $GhId    = gh api user --jq '.id'    2>$null
            $GhLogin = gh api user --jq '.login' 2>$null
            if ($GhId -and $GhLogin) {
                $DetectedEmail = "${GhId}+${GhLogin}@users.noreply.github.com"
            }
        }
    }
}

# Quelle 2a: Windows — ADSI (Active Directory / lokales Konto)
# Source 2a: Windows — ADSI (Active Directory / local account)
if (-not $DetectedName -and $IsWindows) {
    try {
        $Adsi = [ADSI]"WinNT://$env:COMPUTERNAME/$env:USERNAME,user"
        $FullName = $Adsi.FullName.Value
        if ($FullName -and $FullName -ne $env:USERNAME) {
            $DetectedName = $FullName
        }
    } catch {
        Write-Verbose "ADSI nicht verfuegbar / unavailable: $($_.Exception.Message)"
    }
}

# Quelle 2b: macOS — dscl
# Source 2b: macOS — dscl
if (-not $DetectedName -and $IsMacOS) {
    try {
        $DsclOut = dscl . read "/Users/$env:USER" RealName 2>$null
        if ($DsclOut) {
            $SysName = ($DsclOut -split "`n" | Select-Object -Last 1).Trim()
            if ($SysName) { $DetectedName = $SysName }
        }
    } catch {
        Write-Verbose "dscl nicht verfuegbar / unavailable: $($_.Exception.Message)"
    }
}

# Quelle 2c: Linux — getent
# Source 2c: Linux — getent
if (-not $DetectedName -and $IsLinux) {
    try {
        $Getent = getent passwd $env:USER 2>$null
        if ($Getent) {
            $Gecos = ($Getent -split ':')[4] -split ',' | Select-Object -First 1
            if ($Gecos) { $DetectedName = $Gecos }
        }
    } catch {
        Write-Verbose "getent nicht verfuegbar / unavailable: $($_.Exception.Message)"
    }
}

# Quelle 3: git log — vorhandene Commits (ohne Platzhalter)
# Source 3: git log — existing commits (excluding placeholders)
if (-not $DetectedName) {
    $LogName = git -C ~ log --format='%an' 2>$null |
        Where-Object { $_ -and $_ -ne $PlaceholderName } |
        Select-Object -First 1
    if ($LogName) { $DetectedName = $LogName }
}
if (-not $DetectedEmail) {
    $LogEmail = git -C ~ log --format='%ae' 2>$null |
        Where-Object { $_ -and $_ -ne $PlaceholderEmail } |
        Select-Object -First 1
    if ($LogEmail) { $DetectedEmail = $LogEmail }
}

# --- Auto-Modus: Abbruch wenn Erkennung unvollständig -------------------------

if ($Auto) {
    if (-not $DetectedName -or -not $DetectedEmail) {
        $MissName  = if ($DetectedName)  { $DetectedName }  else { '(nicht erkannt / not detected)' }
        $MissEmail = if ($DetectedEmail) { $DetectedEmail } else { '(nicht erkannt / not detected)' }
        Write-Error "Git-Identität konnte nicht automatisch ermittelt werden." -ErrorAction Continue
        Write-HBLog "  Name : $MissName"
        Write-HBLog "  Email: $MissEmail"
        Write-HBLog ''
        Write-HBLog "Tipp: 'gh auth login' ausführen oder Skript ohne -Auto starten."
        Write-HBLog 'Error: Could not auto-detect git identity. Run "gh auth login" or use interactive mode.'
        exit 1
    }
    $NewName  = $DetectedName
    $NewEmail = $DetectedEmail
} else {
    # --- Interaktiver Dialog / Interactive prompt --------------------------------
    Write-Host ''
    if ($DetectedName -or $DetectedEmail) {
        Write-HBLog 'Erkannte Werte / Detected values:'
        if ($DetectedName)  { Write-HBLog "  Name : $DetectedName" }
        if ($DetectedEmail) { Write-HBLog "  Email: $DetectedEmail" }
        Write-Host ''
        Write-HBLog 'Eingabe leer lassen = erkannten Wert übernehmen.'
        Write-HBLog 'Leave input empty to accept the detected value.'
        Write-Host ''
    }

    if ($DetectedName) {
        $nameInput = Read-Host "  Git-Name [$DetectedName]"
        $NewName = if ($nameInput) { $nameInput } else { $DetectedName }
    } else {
        do {
            $NewName = Read-Host '  Git-Name (Vor- und Nachname / full name)'
        } while (-not $NewName)
    }

    if ($DetectedEmail) {
        $emailInput = Read-Host "  Git-E-Mail [$DetectedEmail]"
        $NewEmail = if ($emailInput) { $emailInput } else { $DetectedEmail }
    } else {
        do {
            $NewEmail = Read-Host '  Git-E-Mail'
        } while (-not $NewEmail)
    }
}

# --- Vorschau / Schreiben / Preview and write ----------------------------------

Write-Host ''
Write-HBLog 'Git-Identität wird gesetzt / Setting git identity:'
Write-HBLog "  user.name  = $NewName"
Write-HBLog "  user.email = $NewEmail"
Write-Host ''

if ($WhatIf) {
    Write-HBLog '[WhatIf] Keine Änderungen vorgenommen / No changes made.'
    exit 0
}

git config --global user.name  $NewName
git config --global user.email $NewEmail

Write-Ok 'Globale Git-Identität gesetzt / Global git identity configured.'
Write-Host ''
Write-HBLog 'Verifizierung / Verification:'
Write-HBLog "  git config --global user.name  => $(git config --global user.name)"
Write-HBLog "  git config --global user.email => $(git config --global user.email)"
