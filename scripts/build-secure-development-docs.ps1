<#
.SYNOPSIS
Builds and validates the generated secure-development compendium.

.DESCRIPTION
Validates the secure-development manifest, checklist IDs and versions, then
generates the checklist compendium from the twelve canonical checklist files.

.PARAMETER Check
Checks that the generated compendium is current without changing files.

.EXAMPLE
pwsh -NoProfile -File scripts/build-secure-development-docs.ps1

.EXAMPLE
pwsh -NoProfile -File scripts/build-secure-development-docs.ps1 -Check
#>
[CmdletBinding()]
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocRoot = Join-Path $RepoRoot 'docs/secure-development'
$ManifestPath = Join-Path $DocRoot 'baseline-manifest.json'
$HeaderTemplate = Join-Path $PSScriptRoot 'templates/secure-development-compendium-header.md'

if (-not (Test-Path $ManifestPath)) { throw "Manifest missing: ${ManifestPath}" }
if (-not (Test-Path $HeaderTemplate)) { throw "Header template missing: ${HeaderTemplate}" }

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.checklists.Count -ne 12) {
    throw 'Manifest must use schema version 1 and contain exactly 12 checklists.'
}

$guidelinePath = Join-Path $DocRoot $manifest.guideline.path
if (-not (Test-Path $guidelinePath)) { throw "Guideline missing: $($manifest.guideline.path)" }
$guideline = Get-Content $guidelinePath -Raw
if ($guideline -notmatch [regex]::Escape("| Versionsnummer | $($manifest.guideline.version) |")) {
    throw "Guideline version mismatch: $($manifest.guideline.path)"
}

foreach ($document in @($manifest.relatedDocuments) + @($manifest.learningDocuments)) {
    $documentPath = Join-Path $DocRoot $document.path
    if (-not (Test-Path $documentPath)) { throw "Controlled document missing: $($document.path)" }
    $documentText = Get-Content $documentPath -Raw
    if ($documentText -notmatch [regex]::Escape("**Version / Version:** $($document.version)")) {
        throw "Controlled document version mismatch: $($document.path)"
    }
}

foreach ($relative in @($manifest.managedBinaryFiles) + @($manifest.managedReferenceFiles)) {
    if (-not (Test-Path (Join-Path $DocRoot $relative))) { throw "Managed reference missing: ${relative}" }
}

$header = Get-Content $HeaderTemplate -Raw
$content = $header.Replace('{{BASELINE_VERSION}}', [string]$manifest.baselineVersion)
$content = $content.Replace('{{COMPENDIUM_VERSION}}', [string]$manifest.compendium.version)
$content = $content.Replace('{{RELEASE_DATE}}', [string]$manifest.releaseDate)
$content = $content.TrimEnd("`r", "`n") + "`n"
$ids = [System.Collections.Generic.List[string]]::new()

foreach ($checklist in $manifest.checklists) {
    $sourceFile = Join-Path $DocRoot $checklist.path
    if (-not (Test-Path $sourceFile)) { throw "Checklist missing: $($checklist.path)" }
    $source = (Get-Content $sourceFile -Raw) -replace "`r`n", "`n"
    if ($source -notmatch [regex]::Escape("**Dokument-ID / Document ID:** $($checklist.id)")) {
        throw "Document ID mismatch: $($checklist.path)"
    }
    if ($source -notmatch [regex]::Escape("**Version / Version:** $($checklist.version)")) {
        throw "Version mismatch: $($checklist.path)"
    }
    foreach ($match in [regex]::Matches($source, '(?m)^#### (CL-[0-9]{2}-[0-9]{2}):')) {
        $ids.Add($match.Groups[1].Value)
    }
    $source = $source.Replace('](../Richtlinie_Sichere-Entwicklung.md', '](Richtlinie_Sichere-Entwicklung.md')
    $source = $source.Replace('](../../../constitution.md', '](../../constitution.md')
    $source = $source.Replace('](../README.md', '](README.md')
    $source = $source.Replace('](../mitgeltende-dokumente/', '](mitgeltende-dokumente/')
    $source = $source.Replace('](CL_', '](checklisten/CL_')
    $content += "`n---`n`n" + $source.TrimEnd("`r", "`n") + "`n"
}

if ($ids.Count -ne $manifest.checklistItemCount) {
    throw "Expected $($manifest.checklistItemCount) checklist items, found $($ids.Count)."
}
$duplicates = $ids | Group-Object | Where-Object Count -gt 1
if ($duplicates) { throw "Duplicate checklist IDs: $($duplicates.Name -join ', ')" }

$content += @"

---

## Versionshistorie / Version History

| Version | Datum / Date | Änderung / Change |
|---|---|---|
| $($manifest.compendium.version) | $($manifest.releaseDate) | Aus den zwölf kanonischen Einzelchecklisten der sicheren-Entwicklung-Basis $($manifest.baselineVersion) erzeugt; einheitliches zweiachsiges Statusmodell und klare Trennung zwischen Vorlage und Projektnachweis. / Generated from the twelve canonical individual checklists of secure-development baseline $($manifest.baselineVersion); unified two-axis status model and clear separation between template and project evidence. |
"@
$content = ($content -replace "`r`n", "`n").TrimEnd("`r", "`n") + "`n"
$output = Join-Path $DocRoot $manifest.compendium.path

if ($Check) {
    if (-not (Test-Path $output)) { throw "Generated compendium missing: ${output}" }
    $existing = (Get-Content $output -Raw) -replace "`r`n", "`n"
    if ($existing -ne $content) { throw "Generated compendium is stale: ${output}" }
    Write-Host 'Secure-development generated documents are current.'
} else {
    [System.IO.File]::WriteAllText($output, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Generated ${output}"
}
