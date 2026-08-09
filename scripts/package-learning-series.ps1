#Requires -Version 7
<#
.SYNOPSIS
Erzeugt ein git-freies Lernreihen-ZIP.

.DESCRIPTION
Kopiert einen Level-1-Lernreihenordner in ein temporaeres Staging-Verzeichnis,
schliesst .git-Verzeichnisse, Remote-Konfigurationen sowie lokale Build- und
IDE-Artefakte aus und erzeugt daraus ein ZIP mit SHA256-Datei.

.PARAMETER SourceDir
Level-1-Quellordner der Lernreihe.

.PARAMETER SeriesName
Anzeigename der Lernreihe fuer Manifest und Paketname. Standard ist der
Quellordnername.

.PARAMETER OutputDir
Zielverzeichnis fuer ZIP und SHA256-Datei. Standard ist
docs/learning-units/dist im Quellordner.

.PARAMETER PackagePrefix
Dateiname-Prefix. Standard wird aus SeriesName abgeleitet.

.PARAMETER StartGuide
Startanleitung relativ zu SourceDir oder absolut. Standard ist
docs/learning-units/START-HERE-FUER-LERNENDE.md.

.PARAMETER GitGuide
Git-Startanleitung relativ zu SourceDir oder absolut. Standard ist
docs/learning-units/GIT-START-FUER-LERNENDE.md.

.PARAMETER HostingGuide
Leitfaden fuer institutionelles Git-Hosting relativ zu SourceDir oder absolut.

.EXAMPLE
pwsh -NoProfile -File scripts/package-learning-series.ps1 -SourceDir ~/SecureCaseTrackerProjects -SeriesName 'Secure CaseTracker' -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SourceDir = '',
    [string]$SeriesName = '',
    [string]$OutputDir = '',
    [string]$PackagePrefix = '',
    [string]$StartGuide = 'docs/learning-units/START-HERE-FUER-LERNENDE.md',
    [string]$GitGuide = 'docs/learning-units/GIT-START-FUER-LERNENDE.md',
    [string]$HostingGuide = 'docs/learning-units/INSTITUTIONELLES-GIT-HOSTING.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SourceDir) {
    throw 'SourceDir ist erforderlich.'
}

$SourceDir = (Resolve-Path $SourceDir).Path
$rootName = Split-Path $SourceDir -Leaf
if (-not $SeriesName) { $SeriesName = $rootName }
if (-not $OutputDir) { $OutputDir = Join-Path $SourceDir 'docs/learning-units/dist' }

function ConvertTo-HBLearningSafeName {
    param([string]$Name)
    $lower = $Name.ToLowerInvariant().Replace(' ', '-')
    return ($lower -replace '[^a-z0-9_-]', '')
}

if (-not $PackagePrefix) { $PackagePrefix = ConvertTo-HBLearningSafeName -Name $SeriesName }
if (-not $PackagePrefix) { $PackagePrefix = ConvertTo-HBLearningSafeName -Name $rootName }

function Test-HBExcludedLearningPath {
    param([string]$RelativePath)
    $path = $RelativePath.Replace('\', '/')
    if ($path -eq '.git' -or $path -like '*/.git' -or $path -like '*/.git/*') { return $true }
    if ($path -eq 'docs/learning-units/dist' -or $path -like 'docs/learning-units/dist/*') { return $true }
    if ($path -like '*/bin' -or $path -like '*/bin/*') { return $true }
    if ($path -like '*/obj' -or $path -like '*/obj/*') { return $true }
    if ($path -like '*/build' -or $path -like '*/build/*') { return $true }
    if ($path -like '*/node_modules' -or $path -like '*/node_modules/*') { return $true }
    if ($path -like '*/.vs' -or $path -like '*/.vs/*') { return $true }
    if ($path -like '*/.idea' -or $path -like '*/.idea/*') { return $true }
    if ((Split-Path $path -Leaf) -eq '.DS_Store') { return $true }
    if ($path -eq '__MACOSX' -or $path -like '*/__MACOSX/*') { return $true }
    if ((Split-Path $path -Leaf) -eq 'settings.local.json') { return $true }
    if ($path -eq '.vscode/settings.json' -or $path -like '*/.vscode/settings.json') { return $true }
    if ($path -eq '.vscode/c_cpp_properties.json' -or $path -like '*/.vscode/c_cpp_properties.json') { return $true }
    if ((Split-Path $path -Leaf) -in @('intake-review-result.json', 'intake-review-report.md')) { return $true }
    return $false
}

function Copy-HBLearningTree {
    param([string]$SourceRoot, [string]$DestinationRoot, [string]$CurrentPath)
    Get-ChildItem -LiteralPath $CurrentPath -Force | Sort-Object FullName | ForEach-Object {
        $relative = [System.IO.Path]::GetRelativePath($SourceRoot, $_.FullName).Replace('\', '/')
        if (Test-HBExcludedLearningPath -RelativePath $relative) { return }
        $target = Join-Path $DestinationRoot $relative
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            Copy-HBLearningTree -SourceRoot $SourceRoot -DestinationRoot $DestinationRoot -CurrentPath $_.FullName
        } else {
            $parent = Split-Path -Parent $target
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }
}

function Get-HBGitValue {
    param([string]$Repo, [string[]]$GitArgs)
    try { return (& git -C $Repo @GitArgs 2>$null).Trim() } catch { return 'unknown' }
}

if ([System.IO.Path]::IsPathRooted($StartGuide)) {
    $startGuidePath = $StartGuide
} else {
    $startGuidePath = Join-Path $SourceDir $StartGuide
}

if ([System.IO.Path]::IsPathRooted($GitGuide)) {
    $gitGuidePath = $GitGuide
} else {
    $gitGuidePath = Join-Path $SourceDir $GitGuide
}

if ([System.IO.Path]::IsPathRooted($HostingGuide)) {
    $hostingGuidePath = $HostingGuide
} else {
    $hostingGuidePath = Join-Path $SourceDir $HostingGuide
}

if (-not (Test-Path -LiteralPath $startGuidePath -PathType Leaf)) {
    throw "Verbindliche Startanleitung fehlt: $startGuidePath"
}
if (-not (Test-Path -LiteralPath $gitGuidePath -PathType Leaf)) {
    throw "Verbindliche Git-Startanleitung fehlt: $gitGuidePath"
}
if (-not (Test-Path -LiteralPath $hostingGuidePath -PathType Leaf)) {
    throw "Leitfaden fuer institutionelles Git-Hosting fehlt: $hostingGuidePath"
}

$shortSha = Get-HBGitValue -Repo $SourceDir -GitArgs @('rev-parse', '--short', 'HEAD')
if (-not $shortSha) { $shortSha = 'nogit' }
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$packageName = "${PackagePrefix}-learning-package-${stamp}-${shortSha}"
$zipPath = Join-Path $OutputDir "${packageName}.zip"
$shaPath = "${zipPath}.sha256"

if ($WhatIfPreference) {
    Write-Host 'WhatIf: Lernreihen-Paket'
    Write-Host "Reihe:  $SeriesName"
    Write-Host "Quelle: $SourceDir"
    Write-Host "Ziel:   $zipPath"
    Write-Host "Start:  $startGuidePath"
    Write-Host "Git:    $gitGuidePath"
    Write-Host "Hosting:$hostingGuidePath"
    Write-Host 'Ausgeschlossen: .git, dist, Build-, IDE-, lokale Settings- und Intake-Review-Ergebnisartefakte'
    return
}

if ($PSCmdlet.ShouldProcess($zipPath, 'Create learning series ZIP package')) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $packageRoot = Join-Path $tempRoot $rootName
    New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
    try {
        Copy-HBLearningTree -SourceRoot $SourceDir -DestinationRoot $packageRoot -CurrentPath $SourceDir
        Copy-Item -LiteralPath $startGuidePath -Destination (Join-Path $packageRoot (Split-Path $startGuidePath -Leaf)) -Force
        Copy-Item -LiteralPath $gitGuidePath -Destination (Join-Path $packageRoot (Split-Path $gitGuidePath -Leaf)) -Force
        Copy-Item -LiteralPath $hostingGuidePath -Destination (Join-Path $packageRoot (Split-Path $hostingGuidePath -Leaf)) -Force

        $manifest = Join-Path $packageRoot 'PACKAGING-MANIFEST.txt'
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add("${SeriesName} learning package")
        $lines.Add("Generated UTC: $stamp")
        $lines.Add("Source directory: $rootName")
        $lines.Add('Git data included: no (.git directories excluded)')
        $lines.Add('Original remotes included: no')
        $lines.Add('')
        $lines.Add('Repository states without remote URLs:')
        @($SourceDir) + @(Get-ChildItem -Path $SourceDir -Directory | ForEach-Object { $_.FullName }) | ForEach-Object {
            if (Test-Path (Join-Path $_ '.git')) {
                $name = Split-Path $_ -Leaf
                $branch = Get-HBGitValue -Repo $_ -GitArgs @('branch', '--show-current')
                $commit = Get-HBGitValue -Repo $_ -GitArgs @('rev-parse', '--short', 'HEAD')
                $dirty = if ((Get-HBGitValue -Repo $_ -GitArgs @('status', '--short'))) { 'yes' } else { 'no' }
                $lines.Add("- ${name}: branch=${branch}, commit=${commit}, dirty=${dirty}")
            }
        }
        $lines.Add('')
        $lines.Add("Start here after extracting: $(Split-Path $startGuidePath -Leaf)")
        $lines.Add("Git guide: $(Split-Path $gitGuidePath -Leaf)")
        $lines.Add("Institutional hosting guide: $(Split-Path $hostingGuidePath -Leaf)")
        Set-Content -Path $manifest -Value $lines -Encoding UTF8

        if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }
        if (Test-Path $shaPath) { Remove-Item -Path $shaPath -Force }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
        $hash = Get-FileHash -Path $zipPath -Algorithm SHA256
        "{0}  {1}" -f $hash.Hash.ToLowerInvariant(), (Split-Path $zipPath -Leaf) | Set-Content -Path $shaPath -Encoding ASCII
        Write-Host "ZIP erzeugt: $zipPath"
        Write-Host "SHA256:      $shaPath"
    } finally {
        if (Test-Path $tempRoot) { Remove-Item -Path $tempRoot -Recurse -Force }
    }
}
