#Requires -Version 7
<#
.SYNOPSIS
    Überträgt die GitHub Copilot CLI-Einstellungen nach ~/.copilot/config.json.
    Transfers GitHub Copilot CLI settings to ~/.copilot/config.json.
.DESCRIPTION
    Windows-Gegenstück zu setup-copilot-settings.sh.
    Windows counterpart to setup-copilot-settings.sh.

    Schreibt nur übertragbare Einstellungen / Writes only transferable settings:
      effortLevel   → Reasoning-Tiefe in der Statusline, z. B. "(high)"
      banner        → Begrüßungs-Banner unterdrücken
      renderMarkdown → Markdown-Rendering in Antworten
      theme         → Farbthema (auto / light / dark)

    Lässt maschinenspezifische Daten unangetastet / Leaves untouched:
      logged_in_users, trusted_folders, firstLaunchAt

    Verwendung / Usage:
        pwsh -NoProfile scripts/setup-copilot-settings.ps1                     # einrichten
        pwsh -NoProfile scripts/setup-copilot-settings.ps1 -WhatIf             # Vorschau
        pwsh -NoProfile scripts/setup-copilot-settings.ps1 -Force              # überschreiben
        pwsh -NoProfile scripts/setup-copilot-settings.ps1 -EffortLevel medium # anderer Level
        pwsh -NoProfile scripts/setup-copilot-settings.ps1 -Theme dark         # dunkles Theme
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Force,
    [ValidateSet('low', 'medium', 'high')]
    [string] $EffortLevel = 'high',
    [ValidateSet('auto', 'light', 'dark')]
    [string] $Theme = 'auto'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$homeDir    = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$configDir  = Join-Path $homeDir '.copilot'
$configFile = Join-Path $configDir 'config.json'

# --- Vorschau / Dry-run (via -WhatIf) ---
if ($WhatIfPreference) {
    Write-Host "[WhatIf] Würde Copilot-Einstellungen schreiben nach / Would write Copilot settings to: $configFile"
    Write-Host "[WhatIf] effortLevel=$EffortLevel | banner=never | renderMarkdown=true | theme=$Theme"
    Write-Host "[WhatIf] Statusline-Effekt / Statusline effect: ~/Pfad [⎇ Branch] Modell ($EffortLevel)"
    return
}

# --- Prüfe bestehende Konfiguration / Check for existing settings ---
if ((Test-Path $configFile) -and -not $Force) {
    $existing = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
    if ($existing -and $existing.ContainsKey('effortLevel')) {
        Write-Host "Copilot-Einstellungen bereits konfiguriert / already configured (effortLevel=$($existing['effortLevel']))."
        Write-Host "Verwende -Force zum Überschreiben / Use -Force to overwrite."
        return
    }
}

# --- Verzeichnis anlegen / Create directory ---
if ($PSCmdlet.ShouldProcess($configDir, 'Verzeichnis anlegen / Create directory')) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# --- config.json aktualisieren / Update config.json ---
# Nur übertragbare Schlüssel setzen; maschinenspezifische Daten (Auth, Pfade) bleiben erhalten.
# Only set transferable keys; machine-specific data (auth, paths) is preserved.
$data = [ordered]@{}
if (Test-Path $configFile) {
    $raw = Get-Content $configFile -Raw
    if ($raw.Trim()) {
        $parsed = $raw | ConvertFrom-Json -AsHashtable
        foreach ($key in $parsed.Keys) { $data[$key] = $parsed[$key] }
    }
}

$data['effortLevel']    = $EffortLevel
$data['banner']         = 'never'
$data['renderMarkdown'] = $true
$data['theme']          = $Theme

if ($PSCmdlet.ShouldProcess($configFile, 'Copilot-Einstellungen schreiben / Write Copilot settings')) {
    $data | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
    Write-Host "OK  Copilot-Einstellungen gesetzt / settings written to $configFile" -ForegroundColor Green
    Write-Host "    effortLevel=$EffortLevel | banner=never | renderMarkdown=true | theme=$Theme"
    Write-Host "    Statusline-Effekt / Statusline effect: ~/Pfad [⎇ Branch] Modell ($EffortLevel)"
}
