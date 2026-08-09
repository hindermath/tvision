#Requires -Version 7
<#
.SYNOPSIS
    Richtet die Codex CLI status_line in ~/.codex/config.toml ein.
    Sets up the Codex CLI status_line in ~/.codex/config.toml.
.DESCRIPTION
    Windows-Gegenstueck zu setup-codex-settings.sh.
    Windows counterpart to setup-codex-settings.sh.

    Liest die zentrale Vorlage scripts/templates/codex-statusline.toml
    und setzt daraus [tui].status_line in der Codex-Konfiguration.

    Reads the central template scripts/templates/codex-statusline.toml
    and sets [tui].status_line in the Codex configuration.

    Verwendung / Usage:
        pwsh -NoProfile scripts/setup-codex-settings.ps1           # einrichten
        pwsh -NoProfile scripts/setup-codex-settings.ps1 -WhatIf   # Vorschau
        pwsh -NoProfile scripts/setup-codex-settings.ps1 -Force    # ueberschreiben
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-HomeDir {
    if ($env:HOME) {
        return $env:HOME
    }

    return $env:USERPROFILE
}

function Get-StatusLineFromTemplate {
    param(
        [Parameter(Mandatory)]
        [string] $TemplateText
    )

    $match = [regex]::Match($TemplateText, '(?m)^status_line\s*=\s*\[.*\]\s*$')
    if (-not $match.Success) {
        throw 'Fehler / Error: template contains no status_line entry.'
    }

    return $match.Value
}

function Test-HasCodexStatusLine {
    param(
        [Parameter(Mandatory)]
        [string] $ConfigText
    )

    $lines = [regex]::Split($ConfigText, "\r?\n")
    $inTui = $false

    foreach ($line in $lines) {
        if ($line -match '^\[[^\]]+\]\s*$') {
            $inTui = $line -match '^\[tui\]\s*$'
            continue
        }

        if ($inTui -and $line -match '^\s*status_line\s*=') {
            return $true
        }
    }

    return $false
}

function Set-CodexStatusLine {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $ConfigText,

        [Parameter(Mandatory)]
        [string] $StatusLine,

        [Parameter(Mandatory)]
        [string] $TemplateText
    )

    if ([string]::IsNullOrEmpty($ConfigText)) {
        $lines = @()
    } else {
        $lines = @([regex]::Split($ConfigText, "\r?\n"))
    }

    while ($lines.Count -gt 0 -and $lines[-1] -eq '') {
        $lines = $lines[0..($lines.Count - 2)]
    }

    $sectionHeaderPattern = '^\[[^\]]+\]\s*$'
    $out = [System.Collections.Generic.List[string]]::new()
    $foundTui = $false
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        if ($line -match '^\[tui\]\s*$') {
            $foundTui = $true
            $out.Add('[tui]')
            $i++

            $section = [System.Collections.Generic.List[string]]::new()
            while ($i -lt $lines.Count -and -not ($lines[$i] -match $sectionHeaderPattern)) {
                if ($lines[$i] -notmatch '^\s*status_line\s*=') {
                    $section.Add($lines[$i])
                }
                $i++
            }

            $insertAt = 0
            while ($insertAt -lt $section.Count) {
                $trimmed = $section[$insertAt].Trim()
                if ($trimmed -eq '' -or $section[$insertAt].TrimStart().StartsWith('#')) {
                    $insertAt++
                    continue
                }
                break
            }

            $section.Insert($insertAt, $StatusLine)
            foreach ($entry in $section) {
                $out.Add($entry)
            }
            continue
        }

        $out.Add($line)
        $i++
    }

    if (-not $foundTui) {
        if ($out.Count -gt 0 -and $out[$out.Count - 1].Trim() -ne '') {
            $out.Add('')
        }

        foreach ($line in ($TemplateText.Trim() -split "\r?\n")) {
            $out.Add($line)
        }
    }

    return (($out -join "`n").TrimEnd() + "`n")
}

$scriptDir = $PSScriptRoot
$templateFile = Join-Path $scriptDir 'templates/codex-statusline.toml'
$settingsDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path (Get-HomeDir) '.codex' }
$settingsFile = Join-Path $settingsDir 'config.toml'

if (-not (Test-Path $templateFile)) {
    throw "Fehler / Error: template not found: $templateFile"
}

if ($WhatIfPreference) {
    Write-Host "[WhatIf] Wuerde Codex status_line setzen in / Would set Codex status_line in: $settingsFile"
    Write-Host "[WhatIf] Vorlage / Template: $templateFile"
    Write-Host "[WhatIf] Elemente / Items: model-with-reasoning | context-remaining | current-dir | git-branch | context-used | five-hour-limit | weekly-limit"
    return
}

$templateText = Get-Content $templateFile -Raw
$statusLine = Get-StatusLineFromTemplate -TemplateText $templateText

if ((Test-Path $settingsFile) -and -not $Force) {
    $existing = Get-Content $settingsFile -Raw
    if (Test-HasCodexStatusLine -ConfigText $existing) {
        Write-Host 'Codex status_line bereits konfiguriert / already configured. Verwende -Force zum Ueberschreiben / Use -Force to overwrite.'
        return
    }
}

if ($PSCmdlet.ShouldProcess($settingsDir, 'Verzeichnis anlegen / Create directory')) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$configText = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw } else { '' }
$updatedText = Set-CodexStatusLine -ConfigText $configText -StatusLine $statusLine -TemplateText $templateText

if ($PSCmdlet.ShouldProcess($settingsFile, 'Codex status_line setzen / Set Codex status_line')) {
    Set-Content -Path $settingsFile -Value $updatedText -Encoding UTF8
    Write-Host "OK  Codex status_line gesetzt / set in $settingsFile" -ForegroundColor Green
    Write-Host '    Items: model-with-reasoning | context-remaining | current-dir | git-branch | context-used | five-hour-limit | weekly-limit'
}
