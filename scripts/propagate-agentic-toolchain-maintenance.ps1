#Requires -Version 7
<#
.SYNOPSIS
    Propagiert das kanonische Toolchain-Wartungspaket in Level-1-/Level-2-Repositories.
    Propagates the canonical toolchain maintenance package to Level-1/Level-2 repositories.

.DESCRIPTION
    Liest die zentral verwaltete Dateiliste aus Level-0 und verarbeitet
    bestehende Level-1- und Level-2-Repositories ausschliesslich aus der zuvor
    validierten lokalen Registry. Nicht registrierte Verzeichnisse bleiben
    unangetastet. Lokal veraenderte verwaltete Dateien werden nicht
    ueberschrieben.

    Reads the centrally managed Level-0 file manifest and processes existing
    Level-1 and Level-2 repositories exclusively from the previously validated
    local registry. Unregistered directories remain untouched. Locally modified
    managed files are never overwritten. Exact manifest exceptions can accept
    clean, tracked, mode-correct project-specific variants without masking
    missing, untracked, or locally modified files.

.PARAMETER DryRun
    Zeigt geplante Aenderungen, ohne Dateien zu schreiben.
    Shows planned changes without writing files.

.PARAMETER CheckOnly
    Prueft nur auf Drift und liefert Exitcode 1 bei Abweichungen.
    Checks drift only and returns exit code 1 when differences exist.

.PARAMETER OnlyLevel1
    Verarbeitet nur Level-1-Repositories. / Processes Level-1 repositories only.

.PARAMETER OnlyLevel2
    Verarbeitet nur Level-2-Repositories. / Processes Level-2 repositories only.

.PARAMETER Repo
    Prueft nur das angegebene Repository. / Checks only the specified repository.

.PARAMETER HomeDir
    Alternatives Home-Verzeichnis fuer die Erkennung. / Alternative discovery home directory.

.PARAMETER Registry
    Alternative Level-2-Registry. / Alternative Level-2 registry.

.PARAMETER Manifest
    Alternative kanonische Dateiliste. / Alternative canonical file manifest.

.EXAMPLE
    pwsh -NoProfile -File scripts/propagate-agentic-toolchain-maintenance.ps1 -DryRun

.EXAMPLE
    pwsh -NoProfile -File scripts/propagate-agentic-toolchain-maintenance.ps1 -CheckOnly

.EXAMPLE
    pwsh -NoProfile -File scripts/propagate-agentic-toolchain-maintenance.ps1 -Repo ~/RiderProjects/TuiVision -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $DryRun,
    [switch] $CheckOnly,
    [switch] $OnlyLevel1,
    [switch] $OnlyLevel2,
    [string] $Repo = '',
    [string] $HomeDir = [Environment]::GetFolderPath('UserProfile'),
    [string] $Registry = '',
    [string] $Manifest = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceRoot = Split-Path -Parent $PSScriptRoot
$hardeningModule = Join-Path $sourceRoot 'scripts/lib/windows-maintenance-hardening.psm1'
if (-not (Test-Path -LiteralPath $hardeningModule -PathType Leaf)) {
    throw "Windows-Wartungsmodul fehlt / Windows maintenance module missing: ${hardeningModule}"
}
Import-Module $hardeningModule -Force
$HomeDir = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $HomeDir).Path)
if (-not $Registry) {
    $Registry = Join-Path $HomeDir '.home-baseline/level2-repository-registry.json'
}
if (-not $Manifest) {
    $Manifest = Join-Path $sourceRoot 'scripts/config/agentic-toolchain-maintenance-files.json'
}

if ($OnlyLevel1 -and $OnlyLevel2) {
    throw '-OnlyLevel1 und / and -OnlyLevel2 sind nicht kombinierbar / cannot be combined.'
}
if ($DryRun -and $CheckOnly) {
    throw '-DryRun und / and -CheckOnly sind nicht kombinierbar / cannot be combined.'
}
if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
    throw "Manifest nicht gefunden / not found: ${Manifest}"
}
if (-not $Repo -and -not (Test-Path -LiteralPath $Registry -PathType Leaf)) {
    throw "Level-2-Registry nicht gefunden / not found: ${Registry}"
}

$manifestData = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
if ($manifestData.schemaVersion -ne 1 -or -not $manifestData.files) {
    throw 'Nicht unterstuetztes Propagationsmanifest / Unsupported propagation manifest.'
}

$managedFiles = @()
$seenPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($entry in $manifestData.files) {
    $relativePath = [string] $entry.path
    if (-not $relativePath -or [IO.Path]::IsPathRooted($relativePath) -or
        $relativePath.Split([char[]]@('/', '\')) -contains '..' -or
        -not $seenPaths.Add($relativePath)) {
        throw "Unsicherer oder doppelter Pfad / Unsafe or duplicate path: ${relativePath}"
    }
    $sourceFile = Join-Path $sourceRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        throw "Kanonische Datei fehlt / Canonical file missing: ${sourceFile}"
    }
    $managedFiles += [pscustomobject]@{
        Path       = $relativePath
        Source     = $sourceFile
        Executable = [bool] $entry.executable
    }
}
if ($managedFiles.Count -eq 0) {
    throw 'Manifest enthaelt keine Dateien / Manifest contains no files.'
}

$exceptionMap = [Collections.Generic.Dictionary[string, string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
$exceptionsProperty = $manifestData.PSObject.Properties['exceptions']
$exceptions = if ($null -eq $exceptionsProperty) { @() } else { @($exceptionsProperty.Value) }
foreach ($entry in $exceptions) {
    if ($null -eq $entry -or $entry -isnot [pscustomobject]) {
        throw 'Ungueltige Propagationsausnahme / Invalid propagation exception.'
    }
    $repositoryPath = [string] $entry.repositoryPath
    $relativePath = [string] $entry.path
    $reason = [string] $entry.reason
    if (-not $repositoryPath -or $repositoryPath.Contains("`t") -or
        $repositoryPath.Contains("`n") -or $repositoryPath.Contains("`r") -or
        [IO.Path]::IsPathRooted($repositoryPath) -or
        $repositoryPath.Split([char[]]@('/', '\')) -contains '..' -or
        $repositoryPath -eq '.') {
        throw "Unsicherer Ausnahmepfad / Unsafe exception repository: ${repositoryPath}"
    }
    if (-not $relativePath -or -not $reason -or
        $relativePath.Contains("`t") -or $relativePath.Contains("`n") -or
        $relativePath.Contains("`r") -or $reason.Contains("`t") -or
        $reason.Contains("`n") -or $reason.Contains("`r") -or
        -not $seenPaths.Contains($relativePath)) {
        throw "Ungueltige Propagationsausnahme / Invalid propagation exception: ${repositoryPath} / ${relativePath}"
    }
    $key = "${repositoryPath}`n${relativePath}"
    if (-not $exceptionMap.TryAdd($key, $reason)) {
        throw "Doppelte Propagationsausnahme / Duplicate propagation exception: ${repositoryPath} / ${relativePath}"
    }
}

function Test-HBManagedRepository {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Path)

    return (Test-Path -LiteralPath (Join-Path $Path '.git')) -and
        ((Test-Path -LiteralPath (Join-Path $Path 'AGENTS.md') -PathType Leaf) -or
         (Test-Path -LiteralPath (Join-Path $Path 'CLAUDE.md') -PathType Leaf))
}

function Get-HBManagedRepositories {
    [CmdletBinding()]
    param()

    if ($Repo) {
        $targetPath = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Repo).Path)
        if (-not (Test-HBManagedRepository -Path $targetPath)) {
            throw "Kein verwaltetes Git-Repository / Not a managed Git repository: ${targetPath}"
        }
        return ,([pscustomobject]@{ Level = 'target'; Path = $targetPath })
    }

    $repositories = @{}
    $registryData = Get-Content -LiteralPath $Registry -Raw | ConvertFrom-Json
    foreach ($entry in @($registryData.repositories)) {
        if ($entry.level -notin 1, 2 -or -not $entry.path) {
            continue
        }
        $path = [IO.Path]::GetFullPath((Join-Path $HomeDir ([string] $entry.path)))
        $homePrefix = $HomeDir.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (-not $path.StartsWith($homePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        if ($path -ne $sourceRoot -and (Test-HBManagedRepository -Path $path)) {
            $repositories[$path] = [int] $entry.level
        }
    }

    $result = foreach ($item in $repositories.GetEnumerator()) {
        if ($OnlyLevel1 -and $item.Value -ne 1) { continue }
        if ($OnlyLevel2 -and $item.Value -ne 2) { continue }
        [pscustomobject]@{ Level = $item.Value; Path = $item.Key }
    }
    return @($result | Sort-Object Level, Path)
}

function Test-HBExecutableMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][bool] $Executable
    )

    if ($IsWindows) { return $true }
    & /bin/test -x $Path
    $isExecutable = $LASTEXITCODE -eq 0
    return $isExecutable -eq $Executable
}

function Test-HBRawFileMatches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][bool] $Executable
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) { return $false }
    $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
    return $sourceHash -eq $targetHash -and
        (Test-HBExecutableMode -Path $Target -Executable $Executable)
}

function Test-HBFileMatches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Repository,
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][string] $RepositoryRelativePath,
        [Parameter(Mandatory)][bool] $Executable
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) { return $false }
    $sourceHash = Get-HBGitNormalizedHash -Repository $Repository -Path $Source `
        -RepositoryRelativePath $RepositoryRelativePath
    $targetHash = Get-HBGitNormalizedHash -Repository $Repository -Path $Target `
        -RepositoryRelativePath $RepositoryRelativePath
    return $sourceHash -eq $targetHash -and
        (Test-HBExecutableMode -Path $Target -Executable $Executable)
}

function Test-HBManagedPathDirty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Repository,
        [Parameter(Mandatory)] $File
    )

    $target = Join-Path $Repository $File.Path
    if (Test-HBFileMatches -Repository $Repository -Source $File.Source -Target $target `
        -RepositoryRelativePath $File.Path -Executable $File.Executable) {
        return $false
    }
    if (-not (Test-Path -LiteralPath $target)) {
        $null = & git -C $Repository ls-files --error-unmatch -- $File.Path 2>$null
        if ($LASTEXITCODE -ne 0) { return $false }
    }
    $status = @(& git -C $Repository status --porcelain=v1 --untracked-files=all -- $File.Path 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "git status fehlgeschlagen / failed: ${Repository}"
    }
    return $status.Count -gt 0
}

function Get-HBPropagationExceptionReason {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Repository,
        [Parameter(Mandatory)][string] $RepositoryRelativePath
    )

    $relativeRepository = [IO.Path]::GetRelativePath($HomeDir, $Repository).Replace('\', '/')
    if ($relativeRepository -eq '..' -or $relativeRepository.StartsWith('../')) {
        return $null
    }
    $reason = ''
    if ($exceptionMap.TryGetValue(
        "${relativeRepository}`n${RepositoryRelativePath}",
        [ref] $reason
    )) {
        return $reason
    }
    return $null
}

$repositories = @(Get-HBManagedRepositories)
$preview = $DryRun -or $WhatIfPreference
$reposCurrent = 0
$reposChanged = 0
$reposDrifted = 0
$reposSkipped = 0
$filesDifferent = 0
$rawDifferences = 0
$filesExcepted = 0

foreach ($repository in $repositories) {
    $repoPath = [string] $repository.Path
    Write-Host ''
    Write-Host "-> Level $($repository.Level): ${repoPath}"

    $dirtyFiles = @($managedFiles | Where-Object {
        Test-HBManagedPathDirty -Repository $repoPath -File $_
    })
    if ($dirtyFiles.Count -gt 0) {
        foreach ($file in $dirtyFiles) {
            Write-Warning "Lokale Aenderung an verwalteter Datei / local managed-file change: $(Join-Path $repoPath $file.Path)"
        }
        Write-Warning "Repository uebersprungen / skipped: ${repoPath}"
        $reposSkipped++
        continue
    }

    $repoDifferences = 0
    foreach ($file in $managedFiles) {
        $target = Join-Path $repoPath $file.Path
        if (-not (Test-HBRawFileMatches -Source $file.Source -Target $target -Executable $file.Executable)) {
            $rawDifferences++
        }
        if (Test-HBFileMatches -Repository $repoPath -Source $file.Source -Target $target `
            -RepositoryRelativePath $file.Path -Executable $file.Executable) {
            Write-Verbose "[CURRENT] $($file.Path)"
            continue
        }

        $exceptionReason = Get-HBPropagationExceptionReason -Repository $repoPath `
            -RepositoryRelativePath $file.Path
        if ($null -ne $exceptionReason -and
            (Test-Path -LiteralPath $target -PathType Leaf) -and
            (Test-HBExecutableMode -Path $target -Executable $file.Executable)) {
            $null = & git -C $repoPath ls-files --error-unmatch -- $file.Path 2>$null
            if ($LASTEXITCODE -eq 0) {
                $filesExcepted++
                Write-Host "  [EXCEPTED] $($file.Path): ${exceptionReason}"
                continue
            }
        }

        $repoDifferences++
        $filesDifferent++
        if ($CheckOnly) {
            Write-Host "  [DRIFT] $($file.Path)"
            continue
        }
        if ($preview) {
            Write-Host "  [DRY-RUN] $($file.Path)"
            continue
        }
        if ($PSCmdlet.ShouldProcess($target, 'Kanonische Wartungsdatei kopieren / Copy canonical maintenance file')) {
            $targetDirectory = Split-Path -Parent $target
            New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
            $temporary = "${target}.tmp.$PID"
            Copy-Item -LiteralPath $file.Source -Destination $temporary -Force
            if (-not $IsWindows) {
                if ($file.Executable) {
                    & chmod 0755 $temporary
                } else {
                    & chmod 0644 $temporary
                }
            }
            Move-Item -LiteralPath $temporary -Destination $target -Force
            Write-Host "  [CHANGED] $($file.Path)"
        }
    }

    if ($repoDifferences -eq 0) {
        $reposCurrent++
        Write-Host "OK: Bereits aktuell / already current: ${repoPath}"
    } elseif ($CheckOnly -or $preview) {
        $reposDrifted++
    } else {
        $reposChanged++
    }
}

Write-Host ''
Write-Host 'Zusammenfassung / Summary'
Write-Host "  repositories.total:   $($repositories.Count)"
Write-Host "  repositories.current: ${reposCurrent}"
Write-Host "  repositories.changed: ${reposChanged}"
Write-Host "  repositories.drifted: ${reposDrifted}"
Write-Host "  repositories.skipped: ${reposSkipped}"
Write-Host "  files.raw_differences: ${rawDifferences}"
Write-Host "  files.exceptions:      ${filesExcepted}"
Write-Host "  files.actionable_drift: ${filesDifferent}"
Write-Host "  files.different:       ${filesDifferent}"

if ($repositories.Count -eq 0 -or $reposSkipped -gt 0) { exit 2 }
if ($CheckOnly -and $reposDrifted -gt 0) { exit 1 }
exit 0
