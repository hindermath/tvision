<#
.SYNOPSIS
Prueft die GSDB-Bereitschaft und bereitet ein Spec-Kit-Intake vor.

Checks GSDB readiness and prepares a Spec Kit intake.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Repo = @(),
    [string]$Registry = '',
    [string]$HomeDir = $HOME,
    [switch]$CheckOnly,
    [switch]$FailOnOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibFile = Join-Path $ScriptDir 'lib/secure-development-hardening.ps1'
if (-not (Test-Path $LibFile)) { throw "Hilfsbibliothek nicht gefunden: $LibFile" }
. $LibFile

$PresetConfig = Join-Path $ScriptDir 'config/spec-kit-governance-presets.json'

function Resolve-HBPath {
    param([string]$Path)
    if ($Path -like '~/*') { return (Join-Path $HOME $Path.Substring(2)) }
    return $Path
}

function Get-DefaultRegistry {
    return (Join-Path $HOME '.home-baseline/level2-repository-registry.json')
}

function Get-RegistryRepos {
    param([string]$RegistryPath, [string]$Root)
    if (-not (Test-Path $RegistryPath)) { return @() }
    $data = Get-Content $RegistryPath -Raw | ConvertFrom-Json
    return @($data.repositories |
        Where-Object { $_.gsdbRequired -eq $true } |
        ForEach-Object {
            if ([System.IO.Path]::IsPathRooted([string]$_.path)) { [string]$_.path }
            else { Join-Path $Root ([string]$_.path) }
        })
}

function Get-RegistryEntryForRepo {
    param([string]$RegistryPath, [string]$Root, [string]$Repository)
    if (-not (Test-Path $RegistryPath)) { return $null }
    $data = Get-Content $RegistryPath -Raw | ConvertFrom-Json
    $repoFull = [System.IO.Path]::GetFullPath((Resolve-HBPath $Repository))
    foreach ($item in @($data.repositories)) {
        $itemPath = [string]$item.path
        if (-not [System.IO.Path]::IsPathRooted($itemPath)) {
            $itemPath = Join-Path $Root $itemPath
        }
        $candidate = [System.IO.Path]::GetFullPath($itemPath)
        if ($candidate -eq $repoFull) { return $item }
    }
    return $null
}

function Add-ReportRow {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Status,
        [string]$Item,
        [string]$Evidence,
        [string]$Rationale,
        [string]$FollowUp
    )
    $safeItem = $Item.Replace('|','\|')
    $safeEvidence = $Evidence.Replace('|','\|')
    $safeRationale = $Rationale.Replace('|','\|')
    $safeFollowUp = $FollowUp.Replace('|','\|')
    $Lines.Add("| $Status | $safeItem | ``$safeEvidence`` | $safeRationale | $safeFollowUp |")
}

function Test-RepoPath {
    param(
        [string]$Repository,
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Label,
        [string]$RelativePath,
        [string]$FollowUp
    )
    if (Test-Path (Join-Path $Repository $RelativePath)) {
        Add-ReportRow $Lines 'OK' $Label $RelativePath 'vorhanden' '-'
        return 0
    }
    Add-ReportRow $Lines 'Open' $Label $RelativePath 'fehlt' $FollowUp
    return 1
}

function Get-ArchivedGsdbIntake {
    param([string]$Repository, [string]$RelativePath)

    $stem = [IO.Path]::GetFileNameWithoutExtension($RelativePath)
    $pattern = '^' + [regex]::Escape($stem) + '\.[0-9]{3}-.+\.md$'
    return Get-ChildItem -LiteralPath $Repository -File -Filter "$stem.*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $pattern } |
        Sort-Object Name |
        Select-Object -First 1
}

function Test-GsdbIntakePath {
    param(
        [string]$Repository,
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Label,
        [string]$RelativePath,
        [string]$FollowUp
    )

    if (Test-Path (Join-Path $Repository $RelativePath) -PathType Leaf) {
        Add-ReportRow $Lines 'OK' $Label $RelativePath 'aktiver Intake vorhanden' '-'
        return 0
    }

    $archived = Get-ArchivedGsdbIntake -Repository $Repository -RelativePath $RelativePath
    if ($archived) {
        Add-ReportRow $Lines 'OK' $Label $archived.Name 'abgeschlossener oder archivierter Intake vorhanden' '-'
        return 0
    }

    Add-ReportRow $Lines 'Open' $Label $RelativePath 'aktiver oder archivierter Intake fehlt' $FollowUp
    return 1
}

function Test-GsdbNonMslJustification {
    param([string]$Repository)

    $content = [System.Text.StringBuilder]::new()
    foreach ($file in @((Join-Path $Repository 'constitution.md'), (Join-Path $Repository '.specify/memory/constitution.md'))) {
        if (Test-Path $file) {
            [void]$content.AppendLine((Get-Content $file -Raw))
        }
    }

    $text = $content.ToString()
    $hasJustification = $text -match 'Nicht-MSL|non-MSL|not MSL|not an MSL|not memory-safe|C89|cc65'
    $hasControls = $text -match 'Kompensationskontrollen|compensating controls|Secure-C-Review|Makefile-Kettenpruefung|Artefakt-Hygiene|Target/Sample-Validierung|target compatibility|toolchain compatibility'
    return ($hasJustification -and $hasControls)
}

function Get-PresetIds {
    if (-not (Test-Path $PresetConfig)) { return @() }
    $data = Get-Content $PresetConfig -Raw | ConvertFrom-Json
    return @($data.presets | ForEach-Object { [string]$_.id })
}

function Write-GsdbIntake {
    param([string]$Repository, [string]$ProjectName)
    $target = Join-Path $Repository 'Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md'
    $template = Join-Path $ScriptDir 'templates/gsdb-spec-kit-intensivpruefung-lastenheft.md'
    if (-not (Test-Path $template)) { throw "GSDB-Intake-Template nicht gefunden: $template" }

    $archived = Get-ArchivedGsdbIntake -Repository $Repository -RelativePath 'Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md'
    if ((-not (Test-Path $target -PathType Leaf)) -and $archived) {
        Write-Host "  unveraendert: abgeschlossenes GSDB-Intake vorhanden: $($archived.Name)"
        return
    }

    if ($CheckOnly) {
        Write-Host "  [check-only] GSDB-Intake pruefen/aktualisieren: Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md"
        return
    }
    if ($WhatIfPreference) {
        Write-Host "  [WhatIf] GSDB-Intake pruefen/aktualisieren: Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md"
        return
    }

    $today = Get-Date -Format 'yyyy-MM-dd'
    $rendered = (Get-Content $template -Raw).Replace('{{PROJECT_NAME}}', $ProjectName).Replace('{{DATE}}', $today)
    if (Test-Path $target) {
        $content = Get-Content $target -Raw
        if ($content -match '(?s)<!-- gsdb-spec-kit-intensivpruefung:start -->.*?<!-- gsdb-spec-kit-intensivpruefung:end -->') {
            $content = [regex]::Replace($content, '(?s)<!-- gsdb-spec-kit-intensivpruefung:start -->.*?<!-- gsdb-spec-kit-intensivpruefung:end -->', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $rendered })
            $content | Set-Content -Path $target -Encoding UTF8
        } else {
            Write-Host "  Hinweis: vorhandenes GSDB-Intake ohne Marker bleibt unveraendert: $target"
        }
    } else {
        $rendered | Set-Content -Path $target -Encoding UTF8
    }
}

function Invoke-GsdbRepoCheck {
    param([string]$Repository)
    if (-not (Test-Path (Join-Path $Repository '.git'))) {
        throw "kein Git-Repository / not a Git repository: $Repository"
    }

    $projectName = Split-Path -Leaf $Repository
    $registryEntry = Get-RegistryEntryForRepo -RegistryPath $Registry -Root $HomeDir -Repository $Repository
    $registryLevel = if ($registryEntry) { [string]$registryEntry.level } else { '' }
    $registryLanguage = if ($registryEntry) { [string]$registryEntry.primaryLanguage } else { '' }
    $registryMslStatus = if ($registryEntry) { [string]$registryEntry.mslStatus } else { '' }
    $language = Get-SdhPrimaryLanguage -Repo $Repository -ProjectName $projectName -ExplicitLanguage ''
    if (($registryMslStatus -eq 'non-msl') -and $registryLanguage) {
        $language = $registryLanguage
    } elseif (-not $language -and $registryLanguage) {
        $language = $registryLanguage
    }
    if (-not $language) { $language = 'unknown' }

    Write-Host "## $Repository"
    Write-Host "  Sprache / language: $language"

    $today = Get-Date -Format 'yyyy-MM-dd'
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# GSDB Self-Assessment / GSDB Preflight')
    $lines.Add('')
    $lines.Add("**Projekt / Project:** $projectName")
    $lines.Add("**Datum / Date:** $today")
    $lines.Add("**Repository:** ``$Repository``")
    $lines.Add("**Primaersprache / Primary language:** $language")
    $lines.Add('')
    $lines.Add('Dieses Dokument ist ein Preflight-Bericht. Es startet keinen Spec-Kit-Lauf und ist keine formale Freigabe.')
    $lines.Add('')
    $lines.Add('*This document is a preflight report. It does not start a Spec Kit run and is not a formal approval.*')
    $lines.Add('')
    $lines.Add('| Status | Pruefpunkt / Check | Evidenzpfad / Evidence path | Begruendung / Rationale | Follow-up |')
    $lines.Add('|---|---|---|---|---|')

    $open = 0
    $checks = @(
        @('GSDB README','docs/secure-development/README.md','GSDB synchronisieren'),
        @('GSDB Richtlinie','docs/secure-development/Richtlinie_Sichere-Entwicklung.md','GSDB synchronisieren'),
        @('GSDB Checklistensammelband','docs/secure-development/Checklistensammelband_Sichere-Entwicklung.md','GSDB synchronisieren'),
        @('GSDB mitgeltende Dokumente','docs/secure-development/mitgeltende-dokumente/README.md','mitgeltende Dokumente synchronisieren'),
        @('GSDB Preset-Verzahnung','docs/secure-development/mitgeltende-dokumente/Verzahnung_Richtlinie_Checklisten_Spec-Kit-Presets.md','Verzahnung synchronisieren')
    )
    foreach ($check in $checks) {
        $open += Test-RepoPath $Repository $lines $check[0] $check[1] $check[2]
    }

    $missingChecklists = 0
    foreach ($n in '01','02','03','04','05','06','07','08','09','10','11','12') {
        $checklistMatches = Get-ChildItem -Path (Join-Path $Repository 'docs/secure-development/checklisten') -Filter "CL_${n}_*.md" -ErrorAction SilentlyContinue
        if (-not $checklistMatches) { $missingChecklists++ }
    }
    if ($missingChecklists -eq 0) {
        Add-ReportRow $lines 'OK' 'CL_01 bis CL_12' 'docs/secure-development/checklisten/' 'alle 12 Checklisten vorhanden' '-'
    } else {
        Add-ReportRow $lines 'Open' 'CL_01 bis CL_12' 'docs/secure-development/checklisten/' "$missingChecklists Checklisten fehlen" 'GSDB synchronisieren'
        $open++
    }

    if (($registryLevel -eq '1') -or ($registryMslStatus -eq 'n/a') -or ($language -eq 'none')) {
        Add-ReportRow $lines 'N/A' 'MSL-Status' '~/.home-baseline/level2-repository-registry.json' 'Koordinations- oder Nicht-Implementierungsrepo' '-'
    } elseif ($registryMslStatus -eq 'msl-mixed-tooling') {
        Add-ReportRow $lines 'OK' 'MSL-Status' '~/.home-baseline/level2-repository-registry.json' 'Registry dokumentiert GSDB-relevanten MSL-/Tooling-Mix' '-'
    } elseif (Test-SdhMslLanguage $language) {
        Add-ReportRow $lines 'OK' 'MSL-Status' 'constitution.md' 'Primaersprache ist auf der MSL-Allowlist' '-'
    } elseif (($registryMslStatus -eq 'non-msl') -or (Test-SdhKnownNonMslLanguage $language)) {
        if (Test-GsdbNonMslJustification -Repository $Repository) {
            Add-ReportRow $lines 'OK' 'MSL-Status' 'constitution.md' 'Nicht-MSL ist mit Begruendung und Kompensationskontrollen dokumentiert' '-'
        } else {
            Add-ReportRow $lines 'Open' 'MSL-Status' 'constitution.md' 'bekannte Nicht-MSL erkannt' 'Nicht-MSL-Begruendung pruefen'
            $open++
        }
    } else {
        Add-ReportRow $lines 'Open' 'MSL-Status' 'constitution.md' 'Primaersprache unklar oder nicht klassifiziert' 'Sprache im Repository dokumentieren'
        $open++
    }

    if ($registryLevel -eq '1') {
        Add-ReportRow $lines 'N/A' 'Spec Kit initialisiert' '.specify/' 'Koordinationsrepo ohne eigenen Spec-Kit-Implementierungslauf' '-'
    } elseif (Test-Path (Join-Path $Repository '.specify')) {
        Add-ReportRow $lines 'OK' 'Spec Kit initialisiert' '.specify/' 'Spec-Kit-Verzeichnis vorhanden' '-'
    } else {
        Add-ReportRow $lines 'Open' 'Spec Kit initialisiert' '.specify/' 'Spec-Kit-Verzeichnis fehlt' 'Spec Kit initialisieren oder N/A begruenden'
        $open++
    }

    $presetOutput = ''
    Push-Location $Repository
    try {
        if (Get-Command specify -ErrorAction SilentlyContinue) {
            $presetOutput = (specify preset list 2>$null | Out-String)
        }
    } finally {
        Pop-Location
    }

    if ($registryLevel -eq '1') {
        Add-ReportRow $lines 'N/A' 'Governance-Presets' '.specify/presets/' 'Koordinationsrepo ohne eigene Preset-Installation' '-'
    } else {
        foreach ($presetId in Get-PresetIds) {
            $presetDir = Join-Path $Repository '.specify/presets'
            $localMatch = if (Test-Path $presetDir) { Get-ChildItem $presetDir -Recurse -Directory -Filter $presetId -ErrorAction SilentlyContinue | Select-Object -First 1 } else { $null }
            if (($presetOutput -match "\($([regex]::Escape($presetId))\)") -or $localMatch) {
                Add-ReportRow $lines 'OK' "Preset $presetId" '.specify/presets/' 'nachweisbar' '-'
            } else {
                Add-ReportRow $lines 'Open' "Preset $presetId" '.specify/presets/' 'nicht nachweisbar' 'Governance-Presets installieren oder Ausnahme dokumentieren'
                $open++
            }
        }
    }

    if (Test-Path (Join-Path $Repository 'docs/security')) {
        Add-ReportRow $lines 'OK' 'Projektspezifischer Nachweisort' 'docs/security/' 'Nachweisordner vorhanden' '-'
    } else {
        Add-ReportRow $lines 'Open' 'Projektspezifischer Nachweisort' 'docs/security/' 'Nachweisordner fehlt' 'docs/security/ anlegen oder gleichwertigen Nachweisort dokumentieren'
        $open++
    }

    $open += Test-GsdbIntakePath $Repository $lines 'RL-SE-/Checklist-Selbstpruefungs-Intake' 'Lastenheft_RL-SE-Checklist-Selbstpruefung.md' 'Intake vorbereiten'
    if ($registryLevel -eq '1') {
        Add-ReportRow $lines 'N/A' 'Secure-Development-Hardening-Intake' 'Lastenheft_Secure-Development-Hardening.md' 'Koordinationsrepo ohne eigene Implementierungshaertung' '-'
    } else {
        $open += Test-GsdbIntakePath $Repository $lines 'Secure-Development-Hardening-Intake' 'Lastenheft_Secure-Development-Hardening.md' 'Intake vorbereiten'
    }
    $gsdbIntake = 'Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md'
    $gsdbIntakeMissing = $false
    if ((Test-GsdbIntakePath $Repository $lines 'GSDB-Spec-Kit-Intensivpruefungs-Intake' $gsdbIntake 'durch diesen Checker erzeugen lassen') -ne 0) {
        $open++
        $gsdbIntakeMissing = $true
    }

    $lines.Add('')
    $lines.Add('## Ergebnis / Result')
    $lines.Add('')
    $lines.Add("- Offene Punkte / Open findings: $open")
    $lines.Add('- Naechster Schritt / Next step: `Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md` spaeter manuell mit `/speckit-specify` starten, wenn die intensive Pruefung erfolgen soll.')

    if ($CheckOnly) {
        Write-Host "  check-only: Bericht und Intake nicht geschrieben; Open=$open"
    } elseif ($WhatIfPreference) {
        Write-Host "  [WhatIf] docs/security/gsdb-self-assessment.md schreiben; Open=$open"
    } else {
        $securityDir = Join-Path $Repository 'docs/security'
        New-Item -ItemType Directory -Path $securityDir -Force | Out-Null
        $lines -join [Environment]::NewLine | Set-Content -Path (Join-Path $securityDir 'gsdb-self-assessment.md') -Encoding UTF8
        Write-Host '  geschrieben: docs/security/gsdb-self-assessment.md'
    }

    Write-GsdbIntake -Repository $Repository -ProjectName $projectName
    if ($CheckOnly) {
        Write-Host '  check-only: Lastenheft_Abarbeitungsreihenfolge.md nicht aktualisiert'
    } else {
        $changedOrder = Update-SdhOrderFile -Repo $Repository -WhatIfMode:$WhatIfPreference
        if ($changedOrder) {
            if ($WhatIfPreference) { Write-Host '  [WhatIf] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren' }
            else { Write-Host '  aktualisiert: Lastenheft_Abarbeitungsreihenfolge.md' }
        } elseif ($WhatIfPreference -and $gsdbIntakeMissing) {
            Write-Host '  [WhatIf] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren'
        } else {
            Write-Host '  unveraendert: Lastenheft_Abarbeitungsreihenfolge.md'
        }
    }

    return $open
}

if (-not $Registry) { $Registry = Get-DefaultRegistry }
$Registry = Resolve-HBPath $Registry
$HomeDir = Resolve-HBPath $HomeDir
if (-not $Repo -or $Repo.Count -eq 0) {
    $Repo = Get-RegistryRepos -RegistryPath $Registry -Root $HomeDir
}
if (-not $Repo -or $Repo.Count -eq 0) {
    $Repo = @($PWD.Path)
}

$totalOpen = 0
foreach ($repoItem in $Repo) {
    $totalOpen += Invoke-GsdbRepoCheck -Repository (Resolve-HBPath $repoItem)
}

Write-Host ""
Write-Host "GSDB-Preflight abgeschlossen. Offene Punkte gesamt: $totalOpen"
if ($FailOnOpen -and $totalOpen -gt 0) {
    exit 1
}
