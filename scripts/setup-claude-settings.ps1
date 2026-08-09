#Requires -Version 7
<#
.SYNOPSIS
    Richtet die Claude Code statusLine in %APPDATA%\Claude\settings.json ein.
    Sets up the Claude Code statusLine in %APPDATA%\Claude\settings.json.
.DESCRIPTION
    Windows-Gegenstück zu setup-claude-settings.sh.
    Windows counterpart to setup-claude-settings.sh.

    Schreibt ein PowerShell-Hilfsscript nach %APPDATA%\Claude\statusline.ps1
    und setzt statusLine.command darauf.

    Writes a PowerShell helper script to %APPDATA%\Claude\statusline.ps1
    and sets statusLine.command to reference it.

    Verwendung / Usage:
        pwsh -NoProfile scripts/setup-claude-settings.ps1           # einrichten
        pwsh -NoProfile scripts/setup-claude-settings.ps1 -WhatIf   # Vorschau
        pwsh -NoProfile scripts/setup-claude-settings.ps1 -Force    # überschreiben
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Windows: %APPDATA%\Claude\
$settingsDir  = Join-Path $env:APPDATA 'Claude'
$settingsFile = Join-Path $settingsDir 'settings.json'
$helperScript = Join-Path $settingsDir 'statusline.ps1'

# --- Vorschau / Dry-run (via -WhatIf) ---
if ($WhatIfPreference) {
    Write-Host "[WhatIf] Würde statusLine-Hilfsscript schreiben nach / Would write helper to: $helperScript"
    Write-Host "[WhatIf] Würde statusLine setzen in / Would set statusLine in: $settingsFile"
    Write-Host "[WhatIf] Format: Modell | ~/Pfad [Branch] | ctx: % | 5h: % | 7d: %"
    return
}

# --- Prüfe bestehende Konfiguration / Check for existing statusLine ---
if ((Test-Path $settingsFile) -and -not $Force) {
    $existing = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
    if ($existing -and $existing.ContainsKey('statusLine')) {
        Write-Host "statusLine bereits konfiguriert / already configured. Verwende -Force zum Überschreiben / Use -Force to overwrite."
        return
    }
}

# --- Verzeichnis anlegen / Create directory ---
if ($PSCmdlet.ShouldProcess($settingsDir, 'Verzeichnis anlegen / Create directory')) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

# --- Hilfsscript schreiben / Write helper script ---
# Das Hilfsscript liest JSON von stdin und gibt die formatierte Statuszeile aus.
# The helper script reads JSON from stdin and outputs the formatted status line.
$helperContent = @'
# Claude Code statusLine helper — automatisch generiert / auto-generated
# Lies JSON von stdin / Read JSON from stdin
$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

$model   = $data.model.display_name
$raw_cwd = $data.cwd

# Home-Verzeichnis normalisieren / Normalize home directory
$homeDir = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$cwd = $raw_cwd -replace [regex]::Escape($homeDir), '~'

# Git-Branch ermitteln / Get git branch
$branch = ''
try {
    $branch = (git -C $raw_cwd --no-optional-locks rev-parse --abbrev-ref HEAD 2>$null)
    $branch = ($branch | Out-String).Trim()
} catch {}
$cwd_display = if ($branch) { "$cwd [$branch]" } else { $cwd }

# Context-Fenster / Context window
$remaining = $data.context_window.remaining_percentage
$ctx = if ($null -ne $remaining) { "ctx: $([math]::Round($remaining))%" } else { 'ctx: n/a' }

# Rate-Limits
$five = $data.rate_limits.five_hour.used_percentage
$week = $data.rate_limits.seven_day.used_percentage
$rl = ''
if ($null -ne $five) { $rl += " | 5h: $([math]::Round($five))%" }
if ($null -ne $week) { $rl += " | 7d: $([math]::Round($week))%" }

Write-Host "$model | $cwd_display | $ctx$rl"
'@

if ($PSCmdlet.ShouldProcess($helperScript, 'Hilfsscript schreiben / Write helper script')) {
    Set-Content -Path $helperScript -Value $helperContent -Encoding UTF8
    Write-Host "OK  Hilfsscript / Helper script: $helperScript" -ForegroundColor Green
}

# --- settings.json aktualisieren / Update settings.json ---
$statusLineCmd = "pwsh -NoProfile -File `"$helperScript`""

$data = [ordered]@{}
if (Test-Path $settingsFile) {
    $raw = Get-Content $settingsFile -Raw
    if ($raw.Trim()) {
        $parsed = $raw | ConvertFrom-Json -AsHashtable
        foreach ($key in $parsed.Keys) { $data[$key] = $parsed[$key] }
    }
}

$data['statusLine'] = [ordered]@{
    type    = 'command'
    command = $statusLineCmd
}

if ($PSCmdlet.ShouldProcess($settingsFile, 'statusLine setzen / Set statusLine')) {
    $data | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8
    Write-Host "OK  statusLine gesetzt / set in $settingsFile" -ForegroundColor Green
    Write-Host "    Format: Modell | ~/Pfad [Branch] | ctx: % | 5h: % | 7d: %"
}
