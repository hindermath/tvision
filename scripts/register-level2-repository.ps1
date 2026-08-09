<#
.SYNOPSIS
Registriert Level-1-/Level-2-Repositories in der operativen GSDB-Registry.

Registers level-1/level-2 repositories in the operational GSDB registry.

.DESCRIPTION
Aktualisiert standardmaessig die lokale Registry
~/.home-baseline/level2-repository-registry.json idempotent. Das Repository
enthaelt nur eine public-safe Beispiel-Registry unter scripts/config/.

Mit -ScanRoot koennen Workspace-Wurzeln nach Git-Repositories durchsucht
werden. So erkennt die wiederkehrende Wartung neue GSDB-Kandidaten, ohne
maschinenbezogene Pfade in das oeffentliche Repository zu schreiben.

Updates the local ~/.home-baseline/level2-repository-registry.json registry by
default. The repository only contains a public-safe example registry under
scripts/config/.

With -ScanRoot, workspace roots can be scanned for Git repositories. This lets
recurring maintenance detect new GSDB candidates without writing machine-
specific paths to the public repository.

Maintenance scans preserve stronger existing language, MSL, GSDB, and preset
metadata. Level-2 repositories default to GSDB scope independently of their MSL
classification. When the registry defines defaultPresetProfile, new entries use
that opt-in profile unless -PresetProfile overrides it.

.PARAMETER Repo
Ein oder mehrere Repositories. / One or more repositories to register.

.PARAMETER ScanRoot
Ein oder mehrere Workspace-Wurzeln. / One or more workspace roots to scan.

.PARAMETER Registry
Alternative lokale Registry-Datei. / Alternate local registry file.

.PARAMETER Level
Explizite Repository-Ebene 1 oder 2. / Explicit repository level 1 or 2.

.PARAMETER PrimaryLanguage
Explizite Primaersprache oder Zielsprache. / Explicit primary or target language.

.PARAMETER MslStatus
Explizite MSL-Klassifikation. / Explicit MSL classification.

.PARAMETER GsdbRequired
Explizite GSDB-Pflicht. / Explicit GSDB requirement.

.PARAMETER PresetProfile
Explizites, eintragsbezogenes Governance-Preset-Profil. Der globale Registry-
Default wird dadurch nicht geaendert.

Explicit entry-scoped governance preset profile. This does not change the
global registry default.

.PARAMETER Role
Repository-Rolle in der Registry. / Repository role in the registry.

.PARAMETER Source
Quelle der Registrierung. / Registration source.

.EXAMPLE
pwsh -NoProfile -File scripts/register-level2-repository.ps1 -ScanRoot ~/SecureOrderDeskProjects -WhatIf

Prueft Registry-Drift ohne Schreibzugriff. / Checks registry drift without writing.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Repo = @(),
    [string[]]$ScanRoot = @(),
    [string]$Registry = '',
    [ValidateSet('1','2')][string]$Level = '',
    [string]$PrimaryLanguage = '',
    [ValidateSet('msl','non-msl','msl-mixed-tooling','n/a','unknown','')][string]$MslStatus = '',
    [ValidateSet('true','false','')][string]$GsdbRequired = '',
    [string]$PresetProfile = '',
    [string]$Role = '',
    [string]$Source = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibFile = Join-Path $ScriptDir 'lib/secure-development-hardening.ps1'
$PresetProfileCatalog = Join-Path $ScriptDir 'config/spec-kit-preset-profiles.json'
if (Test-Path $LibFile) {
    . $LibFile
}

function Resolve-HBPath {
    param([string]$Path)
    if ($Path -like '~/*') { return (Join-Path $HOME $Path.Substring(2)) }
    return $Path
}

function Get-DefaultRegistry {
    return (Join-Path $HOME '.home-baseline/level2-repository-registry.json')
}

function Assert-HBPresetProfile {
    param([Parameter(Mandatory)][string]$Name)
    if (-not (Test-Path -LiteralPath $PresetProfileCatalog -PathType Leaf)) {
        throw "Preset-Profilkatalog fehlt / missing: ${PresetProfileCatalog}"
    }
    $catalog = Get-Content -LiteralPath $PresetProfileCatalog -Raw | ConvertFrom-Json
    if ($null -eq $catalog.profiles.PSObject.Properties[$Name]) {
        throw "Unbekanntes Preset-Profil / unknown preset profile: ${Name}"
    }
}

function Get-HomeRelativePath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    $homeFull = [System.IO.Path]::GetFullPath($HOME).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if ($full.StartsWith($homeFull + [IO.Path]::DirectorySeparatorChar)) {
        return $full.Substring($homeFull.Length + 1) -replace '\\','/'
    }
    return $full -replace '\\','/'
}

function Get-HBInferredLevel {
    param([string]$Repository)
    $parent = Split-Path -Parent $Repository
    if (Test-Path (Join-Path $parent '.git')) { return '2' }
    return '1'
}

function Get-HBDiscoveredRepository {
    param([string[]]$Roots)
    foreach ($root in $Roots) {
        $resolvedRoot = Resolve-HBPath $root
        if (-not (Test-Path $resolvedRoot)) {
            Write-Warning "Scan-Root nicht gefunden / scan root not found: ${resolvedRoot}"
            continue
        }
        $rootFull = [System.IO.Path]::GetFullPath($resolvedRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
        Get-ChildItem -LiteralPath $resolvedRoot -Directory -Force -Recurse -Filter '.git' -ErrorAction SilentlyContinue |
            ForEach-Object {
                $repoPath = Split-Path -Parent $_.FullName
                $repoFull = [System.IO.Path]::GetFullPath($repoPath).TrimEnd([IO.Path]::DirectorySeparatorChar)
                if ($repoFull -ne $rootFull) { $repoPath }
            }
    }
}

function Register-HBRepository {
    param(
        [string]$Repository,
        [string]$RegistryPath,
        [string]$RegistrationSource
    )

    if (-not (Test-Path (Join-Path $Repository '.git'))) {
        throw "kein Git-Repository / not a Git repository: ${Repository}"
    }

    $projectName = Split-Path -Leaf $Repository
    $effectiveLevel = if ($Level) { $Level } else { Get-HBInferredLevel -Repository $Repository }

    $language = $PrimaryLanguage
    if (-not $language) {
        $language = Get-SdhPrimaryLanguage -Repo $Repository -ProjectName $projectName -ExplicitLanguage ''
    }
    if (-not $language) { $language = 'unknown' }

    $effectiveMslStatus = $MslStatus
    if (-not $effectiveMslStatus) {
        $effectiveMslStatus = 'unknown'
        if (Test-SdhMslLanguage $language) { $effectiveMslStatus = 'msl' }
        elseif (Test-SdhKnownNonMslLanguage $language) { $effectiveMslStatus = 'non-msl' }
        elseif ($language -eq 'none') { $effectiveMslStatus = 'n/a' }
    }

    $gsdbRequiredValue = $GsdbRequired
    if (-not $gsdbRequiredValue) {
        $gsdbRequiredValue = if ($effectiveLevel -eq '2') { 'true' } else { 'false' }
    }

    $effectiveRole = $Role
    if (-not $effectiveRole) {
        $effectiveRole = if ($effectiveLevel -eq '2') { 'level-2-project' } else { 'level-1-workspace' }
    }

    $today = Get-Date -Format 'yyyy-MM-dd'
    $repoRel = Get-HomeRelativePath $Repository

    if (Test-Path $RegistryPath) {
        $data = Get-Content $RegistryPath -Raw | ConvertFrom-Json
    } else {
        $data = [pscustomobject]@{
            schemaVersion = 1
            description = "Local operational registry for GSDB-relevant level-1 and level-2 repositories. Paths are relative to the user's home directory."
            defaultPresetProfile = 'standard-eight-governance-presets'
            updatedAt = $today
            repositories = @()
        }
    }
    $effectivePresetProfile = $PresetProfile
    if (-not $effectivePresetProfile -and
        ($data.PSObject.Properties.Name -contains 'defaultPresetProfile') -and
        $data.defaultPresetProfile) {
        $effectivePresetProfile = [string]$data.defaultPresetProfile
    }
    if (-not $effectivePresetProfile) {
        $effectivePresetProfile = if (($effectiveLevel -eq '2') -and ($gsdbRequiredValue -eq 'true')) { 'standard-eight-governance-presets' } else { 'none' }
    }

    $repos = @($data.repositories)
    $existing = $repos | Where-Object { $_.path -eq $repoRel } | Select-Object -First 1

    if ($existing) {
        $preserveCurated = ($RegistrationSource -eq 'maintenance-discovery') -and ($existing.source -notin @($null, '', 'maintenance-discovery'))
        if ((-not $PrimaryLanguage) -and ($preserveCurated -or ($language -eq 'unknown')) -and ($existing.primaryLanguage -notin @($null, '', 'unknown'))) {
            $language = [string]$existing.primaryLanguage
        }
        if ((-not $MslStatus) -and ($preserveCurated -or ($effectiveMslStatus -eq 'unknown')) -and ($existing.mslStatus -notin @($null, '', 'unknown'))) {
            $effectiveMslStatus = [string]$existing.mslStatus
        }
        if ((-not $GsdbRequired) -and ($preserveCurated -or ([bool]$existing.gsdbRequired))) {
            $gsdbRequiredValue = if ([bool]$existing.gsdbRequired) { 'true' } else { 'false' }
        }
        $existingPresetProfile = [string]$existing.presetProfile
        if ($existingPresetProfile -in @('standard-six-governance-presets', 'standard-seven-governance-presets')) {
            $existingPresetProfile = 'standard-eight-governance-presets'
        }
        if ((-not $PresetProfile) -and ($preserveCurated -or ($effectivePresetProfile -eq 'none')) -and ($existingPresetProfile -notin @($null, ''))) {
            $effectivePresetProfile = $existingPresetProfile
        }
        if ((-not $Role) -and $preserveCurated -and ($existing.role -notin @($null, ''))) {
            $effectiveRole = [string]$existing.role
        }
        if (($RegistrationSource -eq 'maintenance-discovery') -and $existing.source) {
            $RegistrationSource = [string]$existing.source
        }
    }

    Assert-HBPresetProfile -Name $effectivePresetProfile

    $entry = [pscustomobject]@{
        path = $repoRel
        level = [int]$effectiveLevel
        primaryLanguage = $language
        mslStatus = $effectiveMslStatus
        gsdbRequired = ($gsdbRequiredValue -eq 'true')
        presetProfile = $effectivePresetProfile
        role = $effectiveRole
        source = $RegistrationSource
        registeredAt = if ($existing -and $existing.registeredAt) { [string]$existing.registeredAt } else { $today }
    }

    if ($existing) {
        $changed = $false
        foreach ($property in @('path','level','primaryLanguage','mslStatus','gsdbRequired','presetProfile','role','source','registeredAt')) {
            if ($existing.$property -ne $entry.$property) {
                $changed = $true
                break
            }
        }
        if ($changed) {
            $repos = @($repos | Where-Object { $_.path -ne $repoRel }) + @($entry)
            $action = 'updated'
        } else {
            $action = 'unchanged'
        }
    } else {
        $repos = @($repos) + @($entry)
        $action = 'added'
    }
    if ($action -ne 'unchanged') {
        $data.updatedAt = $today
        $data.repositories = @($repos | Sort-Object path)
    }

    $shouldWrite = ($action -ne 'unchanged') -and $PSCmdlet.ShouldProcess($RegistryPath, "$action $repoRel")
    if ($shouldWrite) {
        $data | ConvertTo-Json -Depth 8 | Set-Content -Path $RegistryPath -Encoding UTF8
    }
    if ($WhatIfPreference) {
        Write-Host "[WhatIf] ${action}: ${repoRel} -> ${RegistryPath}"
    } else {
        Write-Host "${action}: ${repoRel} -> ${RegistryPath}"
    }
}

if ((@($Repo).Count -eq 0) -and (@($ScanRoot).Count -eq 0)) {
    throw "-Repo oder -ScanRoot ist erforderlich / -Repo or -ScanRoot is required"
}

if (-not $Registry) { $Registry = Get-DefaultRegistry }
$Registry = Resolve-HBPath $Registry
$registryDirectory = Split-Path -Parent $Registry
if (-not $WhatIfPreference) {
    New-Item -ItemType Directory -Path $registryDirectory -Force | Out-Null
} elseif (-not (Test-Path $registryDirectory)) {
    Write-Host "[WhatIf] Registry-Verzeichnis erzeugen: $registryDirectory"
}

$registrationSource = $Source
if (-not $registrationSource) {
    $registrationSource = if (@($ScanRoot).Count -gt 0) { 'maintenance-discovery' } else { 'manual-registration' }
}

$repositories = @()
foreach ($repoPath in @($Repo)) {
    if ($repoPath) { $repositories += (Resolve-HBPath $repoPath) }
}
if (@($ScanRoot).Count -gt 0) {
    $repositories += @(Get-HBDiscoveredRepository -Roots $ScanRoot)
}

$repositories = @($repositories | Where-Object { $_ } | Sort-Object -Unique)
foreach ($repository in $repositories) {
    Register-HBRepository -Repository $repository -RegistryPath $Registry -RegistrationSource $registrationSource
}
