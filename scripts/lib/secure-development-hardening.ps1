# Shared helpers for secure-development hardening intake preparation.

$script:SdhPrepareResult = ''
$script:SdhPrepareReason = ''
$script:SdhDetectedLanguage = ''

function ConvertTo-SdhNormalizedLanguage {
    param([string]$Language)
    if (-not $Language) { return '' }
    return (($Language.ToLowerInvariant() -replace '[\s_\+\-]+', '') -replace '\.', '')
}

function Test-SdhMslLanguage {
    param([string]$Language)
    $normalized = ConvertTo-SdhNormalizedLanguage $Language
    return @(
        'c#','csharp','cs','dotnet','net','f#','fsharp','fs',
        'rust','swift','java','kotlin','scala','go','golang','dart',
        'python','py','ruby','javascript','js','typescript','ts',
        'haskell','ocaml','erlang','elixir','ada','spark'
    ) -contains $normalized
}

function Test-SdhKnownNonMslLanguage {
    param([string]$Language)
    $normalized = ConvertTo-SdhNormalizedLanguage $Language
    return @('c','cpp','cxx','cplusplus','objectivec','objc','assembly','asm','cc65','zig','nim','d') -contains $normalized
}

function Get-SdhLanguageFromConstitution {
    param([string]$Repo, [string]$ProjectName)

    foreach ($file in @((Join-Path $Repo 'constitution.md'), (Join-Path $Repo '.specify/memory/constitution.md'))) {
        if (-not (Test-Path $file)) { continue }
        foreach ($line in Get-Content $file) {
            if ($line -notlike "*$ProjectName*") { continue }
            $parts = $line -split '\|'
            if ($parts.Count -lt 4) { continue }
            $language = $parts[2].Trim()
            if ($language -match 'C#|\.NET|dotnet') { return 'C#' }
            if ($language -match 'Rust') { return 'Rust' }
            if ($language -match 'Swift') { return 'Swift' }
            if ($language -match 'TypeScript|JavaScript') { return 'TypeScript' }
            if ($language -match 'Java') { return 'Java' }
            if ($language -match 'Kotlin') { return 'Kotlin' }
            if ($language -match 'Go') { return 'Go' }
            if ($language -match 'Python') { return 'Python' }
            if ($language) { return $language }
        }
    }

    return ''
}

function Get-SdhLanguageFromProjectName {
    param([string]$ProjectName)

    switch -Regex ($ProjectName.ToLowerInvariant()) {
        '[-_.](csharp|c#)$' { return 'C#' }
        '[-_.](fsharp|f#)$' { return 'F#' }
        '[-_.]rust$' { return 'Rust' }
        '[-_.]swift$' { return 'Swift' }
        '[-_.]java$' { return 'Java' }
        '[-_.]kotlin$' { return 'Kotlin' }
        '[-_.]go$' { return 'Go' }
        '[-_.]python$' { return 'Python' }
        '[-_.]typescript$' { return 'TypeScript' }
        '[-_.]javascript$' { return 'JavaScript' }
        default { return '' }
    }
}

function Test-SdhAnyFile {
    param([string]$Repo, [string[]]$Patterns)
    foreach ($pattern in $Patterns) {
        if (Get-ChildItem -Path $Repo -Recurse -Depth 4 -File -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1) {
            return $true
        }
    }
    return $false
}

function Get-SdhLanguageFromFiles {
    param([string]$Repo)

    if (Test-SdhAnyFile $Repo @('*.sln','*.csproj','*.fsproj')) { return 'C#' }
    if (Test-SdhAnyFile $Repo @('Cargo.toml')) { return 'Rust' }
    if (Test-SdhAnyFile $Repo @('go.mod')) { return 'Go' }
    if (Test-SdhAnyFile $Repo @('Package.swift')) { return 'Swift' }
    if (Test-SdhAnyFile $Repo @('tsconfig.json')) { return 'TypeScript' }
    if (Test-SdhAnyFile $Repo @('package.json')) { return 'JavaScript' }
    if (Test-SdhAnyFile $Repo @('pyproject.toml')) { return 'Python' }
    if (Test-SdhAnyFile $Repo @('pom.xml','build.gradle','build.gradle.kts')) { return 'Java' }
    return ''
}

function Get-SdhPrimaryLanguage {
    param([string]$Repo, [string]$ProjectName, [string]$ExplicitLanguage)

    if ($ExplicitLanguage) { return $ExplicitLanguage }

    $fromConstitution = Get-SdhLanguageFromConstitution -Repo $Repo -ProjectName $ProjectName
    if ($fromConstitution) { return $fromConstitution }

    $fromProjectName = Get-SdhLanguageFromProjectName -ProjectName $ProjectName
    if ($fromProjectName) { return $fromProjectName }

    return Get-SdhLanguageFromFiles -Repo $Repo
}

function Get-SdhSourceDir {
    param([string]$ScriptDir)

    $repoDir = Split-Path -Parent $ScriptDir
    foreach ($candidate in @(
        (Join-Path $repoDir 'docs/secure-development'),
        (Join-Path $HOME 'docs/secure-development'),
        (Join-Path $HOME 'home-baseline-source/docs/secure-development')
    )) {
        if ((Test-Path $candidate) `
            -and (Test-Path (Join-Path $candidate 'README.md')) `
            -and (Test-Path (Join-Path $candidate 'mitgeltende-dokumente/README.md'))) {
            return $candidate
        }
    }
    return ''
}

function Get-SdhManifestPaths {
    param([string]$ManifestPath)

    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $paths = [System.Collections.Generic.List[string]]::new()
    $paths.Add('baseline-manifest.json')
    $paths.Add([string]$manifest.guideline.path)
    $paths.Add([string]$manifest.compendium.path)
    foreach ($item in $manifest.checklists) { $paths.Add([string]$item.path) }
    foreach ($item in $manifest.relatedDocuments) { $paths.Add([string]$item.path) }
    foreach ($item in $manifest.learningDocuments) { $paths.Add([string]$item.path) }
    foreach ($item in $manifest.managedBinaryFiles) { $paths.Add([string]$item) }
    foreach ($item in $manifest.managedReferenceFiles) { $paths.Add([string]$item) }
    return @($paths | Sort-Object -Unique)
}

function Sync-SdhBaseline {
    param([string]$SourceDir, [string]$TargetDir, [switch]$WhatIfMode)

    $sourceManifest = Join-Path $SourceDir 'baseline-manifest.json'
    $targetManifest = Join-Path $TargetDir 'baseline-manifest.json'
    if (-not (Test-Path $sourceManifest)) { throw "Baseline-Manifest fehlt: ${sourceManifest}" }

    $newPaths = @(Get-SdhManifestPaths -ManifestPath $sourceManifest)
    $oldPaths = if (Test-Path $targetManifest) { @(Get-SdhManifestPaths -ManifestPath $targetManifest) } else { @() }
    $copied = 0
    $removed = 0

    foreach ($relative in $oldPaths) {
        if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw "Unsicherer Manifestpfad: ${relative}" }
        if ($relative -notin $newPaths) {
            $targetFile = Join-Path $TargetDir $relative
            if (Test-Path $targetFile -PathType Leaf) {
                $removed++
                if (-not $WhatIfMode) { Remove-Item -LiteralPath $targetFile -Force }
            }
        }
    }

    foreach ($relative in $newPaths) {
        if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw "Unsicherer Manifestpfad: ${relative}" }
        $sourceFile = Join-Path $SourceDir $relative
        $targetFile = Join-Path $TargetDir $relative
        if (-not (Test-Path $sourceFile -PathType Leaf)) { throw "Verwaltete Quelldatei fehlt: ${relative}" }
        $different = -not (Test-Path $targetFile -PathType Leaf)
        if (-not $different) {
            $different = (Get-FileHash $sourceFile -Algorithm SHA256).Hash -ne (Get-FileHash $targetFile -Algorithm SHA256).Hash
        }
        if ($different) {
            $copied++
            if (-not $WhatIfMode -and $relative -ne 'baseline-manifest.json') {
                $parent = Split-Path -Parent $targetFile
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
            }
        }
    }

    if (-not $WhatIfMode) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        Copy-Item -LiteralPath $sourceManifest -Destination $targetManifest -Force
        Get-ChildItem -Path $TargetDir -Directory -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) } |
            Remove-Item -Force
    }
    Write-Host "  Baseline-Sync: $copied aktualisiert, $removed veraltet entfernt"
}

function Get-SdhTemplateFile {
    param([string]$ScriptDir)

    $repoDir = Split-Path -Parent $ScriptDir
    foreach ($candidate in @(
        (Join-Path $ScriptDir 'templates/secure-development-hardening-lastenheft.md'),
        (Join-Path $repoDir 'scripts/templates/secure-development-hardening-lastenheft.md'),
        (Join-Path $HOME 'scripts/templates/secure-development-hardening-lastenheft.md'),
        (Join-Path $HOME 'home-baseline-source/scripts/templates/secure-development-hardening-lastenheft.md')
    )) {
        if (Test-Path $candidate) { return $candidate }
    }
    return ''
}

function Write-SdhRenderedTemplate {
    param([string]$Template, [string]$Output, [string]$ProjectName)

    $today = Get-Date -Format 'yyyy-MM-dd'
    $content = Get-Content $Template -Raw
    $content = $content.Replace('{{PROJECT_NAME}}', $ProjectName)
    $content = $content.Replace('{{DATE}}', $today)
    $content | Set-Content -Path $Output -Encoding UTF8
}

function Get-SdhOrderRank {
    param([string]$Name)
    $n = $Name.ToLowerInvariant()
    if ($n -match 'rl-se.*checklist.*selbstpruefung|checklist.*selbstpruefung') { return 45 }
    if ($n -match 'gsdb.*spec-kit.*intensivpruefung|gsdb.*intensiv') { return 48 }
    if ($n -like '*secure-development-hardening*') { return 50 }
    if ($n -match 'constitution|governance|baseline|homogeneity') { return 10 }
    if ($n -match 'migration|build|ci|cicd|tool|terminalgui|rename') { return 20 }
    if ($n -match 'compiler|worker|service|database|db|sql|mongodb|postgres|sqlite|framework|core|controls|runtime|vm|clr|assembly|pl0|wave') { return 30 }
    if ($n -match 'ui|tui|ide|a11y|dokument|doc|l10n|didactic|comment') { return 40 }
    return 60
}

function Get-SdhOrderGroup {
    param([int]$Rank)
    switch ($Rank) {
        10 { 'Governance/Baseline' }
        20 { 'Migration/Tooling' }
        30 { 'Kernlogik/Runtime' }
        40 { 'UI/A11Y/Dokumentation' }
        45 { 'RL-SE-/Checklist-Selbstpruefung' }
        48 { 'GSDB-Spec-Kit-Intensivpruefung' }
        50 { 'Secure-Development-Hardening' }
        default { 'Weitere Anforderungen' }
    }
}

function Get-SdhOrderSection {
    param([string]$Repo)

    $files = Get-ChildItem -Path $Repo -File -Filter 'Lastenheft*.md' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'Lastenheft_Abarbeitungsreihenfolge.md' } |
        ForEach-Object {
            $rank = Get-SdhOrderRank $_.Name
            [pscustomobject]@{
                Rank = $rank
                Name = $_.Name
                Group = Get-SdhOrderGroup $rank
                Status = if ($_.Name -match '\.[0-9][0-9][0-9].*\.md$') { 'archiviert oder abgeschlossen / archived or completed' } else { 'aktiv / active' }
            }
        } |
        Sort-Object Rank, Name

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('<!-- secure-development-hardening-order:start -->')
    $lines.Add('## Automatisch ermittelte Lastenheft-Reihenfolge / Automatically Detected Requirements Order')
    $lines.Add('')
    $lines.Add('Diese Tabelle wird aus `Lastenheft*.md` im Repository-Root erzeugt. Sie ist eine Vorbereitung fuer spaetere Spec-Kit-Laeufe und startet selbst keinen Lauf. Manuelle Projektentscheidungen ausserhalb dieses markierten Abschnitts bleiben erhalten.')
    $lines.Add('')
    $lines.Add('*This table is generated from `Lastenheft*.md` in the repository root. It prepares later Spec Kit runs and does not start a run. Manual project decisions outside this marked section remain preserved.*')
    $lines.Add('')
    $lines.Add('| Rang | Lastenheft | Gruppe | Status |')
    $lines.Add('|---:|---|---|---|')
    if (-not $files) {
        $lines.Add('| - | - | Keine Lastenhefte gefunden | - |')
    } else {
        $i = 0
        foreach ($file in $files) {
            $i++
            $lines.Add("| $i | ``$($file.Name)`` | $($file.Group) | $($file.Status) |")
        }
    }
    $lines.Add('<!-- secure-development-hardening-order:end -->')
    return ($lines -join [Environment]::NewLine)
}

function Update-SdhOrderFile {
    param([string]$Repo, [switch]$WhatIfMode)

    $orderFile = Join-Path $Repo 'Lastenheft_Abarbeitungsreihenfolge.md'
    $section = Get-SdhOrderSection -Repo $Repo

    if (Test-Path $orderFile) {
        $content = Get-Content $orderFile -Raw
        if ($content -match '(?s)<!-- secure-development-hardening-order:start -->.*?<!-- secure-development-hardening-order:end -->') {
            $newContent = [regex]::Replace($content, '(?s)<!-- secure-development-hardening-order:start -->.*?<!-- secure-development-hardening-order:end -->', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $section })
        } else {
            $newContent = $content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $section + [Environment]::NewLine
        }
    } else {
        $newContent = @"
# Lastenheft-Abarbeitungsreihenfolge / Requirements Processing Order

Diese Datei haelt die sichtbare Abarbeitungsreihenfolge der vorhandenen Lastenhefte fest. Sie ist eine Vorbereitung fuer spaetere Spec-Kit-Laeufe und startet selbst keinen Lauf.

*This file records the visible processing order of existing requirements documents. It prepares later Spec Kit runs and does not start a run by itself.*

$section
"@
    }

    $newContent = $newContent.TrimEnd("`r", "`n") + [Environment]::NewLine

    if ((Test-Path $orderFile) -and ((Get-Content $orderFile -Raw) -eq $newContent)) {
        return $false
    }

    if ($WhatIfMode) { return $true }

    [IO.File]::WriteAllText($orderFile, $newContent, [Text.UTF8Encoding]::new($false))
    return $true
}

function Invoke-SdhPrepareRepo {
    param(
        [string]$Repo,
        [string]$ProjectName,
        [string]$PrimaryLanguage,
        [string]$ScriptDir,
        [switch]$Force,
        [switch]$WhatIfMode
    )

    $script:SdhPrepareResult = 'skipped'
    $script:SdhPrepareReason = ''
    $script:SdhDetectedLanguage = ''

    if (-not (Test-Path (Join-Path $Repo '.git'))) {
        $script:SdhPrepareReason = 'kein Git-Repository'
        return $true
    }

    $language = Get-SdhPrimaryLanguage -Repo $Repo -ProjectName $ProjectName -ExplicitLanguage $PrimaryLanguage
    if (-not $language) {
        $script:SdhPrepareReason = 'Primaersprache unklar; nutze -PrimaryLanguage fuer automatische Vorbereitung'
        return $true
    }
    $script:SdhDetectedLanguage = $language

    if (-not (Test-SdhMslLanguage $language)) {
        if (Test-SdhKnownNonMslLanguage $language) {
            $script:SdhPrepareReason = "nicht-MSL erkannt: $language"
        } else {
            $script:SdhPrepareReason = "Sprache nicht auf MSL-Allowlist: $language"
        }
        return $true
    }

    $sourceDir = Get-SdhSourceDir -ScriptDir $ScriptDir
    $templateFile = Get-SdhTemplateFile -ScriptDir $ScriptDir
    if (-not $sourceDir) {
        $script:SdhPrepareResult = 'error'
        $script:SdhPrepareReason = 'docs/secure-development Quelle nicht gefunden'
        return $false
    }
    if (-not $templateFile) {
        $script:SdhPrepareResult = 'error'
        $script:SdhPrepareReason = 'Lastenheft-Template nicht gefunden'
        return $false
    }

    $targetDocs = Join-Path $Repo 'docs/secure-development'
    $intakeFile = Join-Path $Repo 'Lastenheft_Secure-Development-Hardening.md'

    if ($WhatIfMode) {
        Write-Host "  [WhatIf] docs/secure-development nach $targetDocs synchronisieren"
    } else {
        Sync-SdhBaseline -SourceDir $sourceDir -TargetDir $targetDocs
    }

    if ((Test-Path $intakeFile) -and -not $Force) {
        if ($WhatIfMode) { Write-Host "  [WhatIf] Lastenheft vorhanden, wird nicht ueberschrieben: Lastenheft_Secure-Development-Hardening.md" }
    } else {
        if ($WhatIfMode) {
            Write-Host '  [WhatIf] Lastenheft_Secure-Development-Hardening.md erzeugen'
        } else {
            Write-SdhRenderedTemplate -Template $templateFile -Output $intakeFile -ProjectName $ProjectName
        }
    }

    $changedOrder = Update-SdhOrderFile -Repo $Repo -WhatIfMode:$WhatIfMode
    if ($WhatIfMode) {
        if ($changedOrder) { Write-Host '  [WhatIf] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren' }
        else { Write-Host '  [WhatIf] Lastenheft_Abarbeitungsreihenfolge.md unveraendert' }
    }

    $script:SdhPrepareResult = 'prepared'
    $script:SdhPrepareReason = "MSL erkannt: $language"
    return $true
}
