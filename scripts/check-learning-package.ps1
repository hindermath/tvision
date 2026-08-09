#Requires -Version 7
<#
.SYNOPSIS
    Prueft ein Lernreihen-ZIP oder fuehrt einen Paket-Selbsttest aus.

.DESCRIPTION
    Prueft genau einen Paket-Root, die Startanleitungen, Manifest, SHA-256,
    ausgeschlossene Git-/Build-/IDE-Artefakte und offensichtliche Secrets.
    Validates one package root, both start guides, manifest, SHA-256, excluded
    Git/build/IDE artefacts, and obvious secrets.

.PARAMETER PackagePath
    Pfad zum Lernreihen-ZIP. Path to the learning-series ZIP.

.PARAMETER ChecksumPath
    Abweichende SHA-256-Datei. Standard ist PackagePath plus `.sha256`.
    Alternative SHA-256 file. Defaults to PackagePath plus `.sha256`.

.PARAMETER SelfTest
    Erzeugt ein minimales Paket und prueft es vollstaendig.
    Creates a minimal package and validates it end to end.

.EXAMPLE
    pwsh -NoProfile -File scripts/check-learning-package.ps1 -SelfTest

.EXAMPLE
    pwsh -NoProfile -File scripts/check-learning-package.ps1 -PackagePath ./package.zip
#>
[CmdletBinding()]
param(
    [string]$PackagePath = '',
    [string]$ChecksumPath = '',
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packageScript = Join-Path $PSScriptRoot 'package-learning-series.ps1'
$gitleaksConfig = Join-Path $PSScriptRoot 'templates/gitleaks.toml'

function Test-HBLearningPackage {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$ShaPath
    )

    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        throw "ZIP nicht gefunden: $ZipPath"
    }
    if (-not (Test-Path -LiteralPath $ShaPath -PathType Leaf)) {
        throw "SHA-256-Datei nicht gefunden: $ShaPath"
    }

    $expected = ((Get-Content -LiteralPath $ShaPath -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
    $actual = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expected -ne $actual) { throw "SHA-256 stimmt nicht: $ShaPath" }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    try {
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $tempRoot -Force
        $roots = @(Get-ChildItem -LiteralPath $tempRoot -Force)
        if ($roots.Count -ne 1 -or -not $roots[0].PSIsContainer) {
            throw 'ZIP muss genau einen Paket-Root enthalten.'
        }
        $root = $roots[0].FullName

        foreach ($required in @('START-HERE-FUER-LERNENDE.md', 'GIT-START-FUER-LERNENDE.md', 'INSTITUTIONELLES-GIT-HOSTING.md', 'PACKAGING-MANIFEST.txt')) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $required) -PathType Leaf)) {
                throw "Verbindliche Paketdatei fehlt: $required"
            }
        }

        $forbidden = @(
            Get-ChildItem -LiteralPath $root -Recurse -Force | Where-Object {
                $relative = [System.IO.Path]::GetRelativePath($root, $_.FullName).Replace('\', '/')
                $relative -match '(^|/)(\.git|bin|obj|build|node_modules|\.vs|\.idea)(/|$)' -or
                $relative -match '(^|/)settings\.local\.json$' -or
                $relative -match '(^|/)\.vscode/(settings\.json|c_cpp_properties\.json)$'
            }
        )
        if ($forbidden.Count -gt 0) {
            throw "Ausgeschlossenes Artefakt im ZIP: $($forbidden[0].FullName)"
        }

        $manifest = (Get-Content -LiteralPath (Join-Path $root 'PACKAGING-MANIFEST.txt') -Raw) -replace "`r`n?", "`n"
        if ($manifest -notmatch '(?m)^Git data included: no ') { throw 'Manifest bestaetigt Git-Ausschluss nicht.' }
        if ($manifest -notmatch '(?m)^Original remotes included: no$') { throw 'Manifest bestaetigt Remote-Ausschluss nicht.' }
        if ($manifest -notmatch '(?m)^Start here after extracting: START-HERE-FUER-LERNENDE\.md$') {
            throw 'Manifest nennt die primaere Startdatei nicht.'
        }
        if ($manifest -notmatch '(?m)^Institutional hosting guide: INSTITUTIONELLES-GIT-HOSTING\.md$') {
            throw 'Manifest nennt den Hosting-Leitfaden nicht.'
        }

        $gitleaks = Get-Command gitleaks -ErrorAction SilentlyContinue
        if ($gitleaks) {
            $gitleaksArguments = @('dir', $root, '--no-banner', '--redact')
            if (Test-Path -LiteralPath $gitleaksConfig -PathType Leaf) {
                $gitleaksArguments += @('--config', $gitleaksConfig)
            }
            & $gitleaks.Source @gitleaksArguments *> $null
            if ($LASTEXITCODE -ne 0) { throw 'gitleaks hat einen moeglichen Secret-Befund gemeldet.' }
        } else {
            Write-Warning 'gitleaks nicht verfuegbar; Secret-Scan uebersprungen.'
        }

        Write-Host "PASS: Lernpaket ist strukturell und gegen die Ausschlussregeln geprueft: $ZipPath"
    } finally {
        if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
    }
}

function Invoke-HBLearningPackageSelfTest {
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $sourceDir = Join-Path $tempRoot 'SecureExampleProjects'
    $guideDir = Join-Path $sourceDir 'docs/learning-units'
    $outputDir = Join-Path $tempRoot 'out'
    New-Item -ItemType Directory -Path $guideDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sourceDir 'src') -Force | Out-Null
    try {
        Set-Content -LiteralPath (Join-Path $guideDir 'START-HERE-FUER-LERNENDE.md') -Value '# Start' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $guideDir 'GIT-START-FUER-LERNENDE.md') -Value '# Git Start' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $guideDir 'INSTITUTIONELLES-GIT-HOSTING.md') -Value '# Institutional Git Hosting' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $sourceDir 'README.md') -Value '# Example' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $sourceDir 'src/example.txt') -Value 'example' -Encoding UTF8

        & pwsh -NoProfile -File $packageScript -SourceDir $sourceDir -SeriesName 'Secure Example' -OutputDir $outputDir
        if ($LASTEXITCODE -ne 0) { throw 'Paket-Self-Test konnte das ZIP nicht erzeugen.' }
        $packages = @(Get-ChildItem -LiteralPath $outputDir -File -Filter '*.zip')
        if ($packages.Count -ne 1) { throw 'Paket-Self-Test erwartete genau ein ZIP.' }
        Test-HBLearningPackage -ZipPath $packages[0].FullName -ShaPath "$($packages[0].FullName).sha256"
        Write-Host 'PASS: check-learning-package.ps1 -SelfTest'
    } finally {
        if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
    }
}

if ($SelfTest) {
    if ($PackagePath) { throw '-SelfTest akzeptiert keinen PackagePath.' }
    Invoke-HBLearningPackageSelfTest
    exit 0
}

if (-not $PackagePath) { throw 'PackagePath oder -SelfTest ist erforderlich.' }
if (-not $ChecksumPath) { $ChecksumPath = "${PackagePath}.sha256" }
Test-HBLearningPackage -ZipPath $PackagePath -ShaPath $ChecksumPath
