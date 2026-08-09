<#
.SYNOPSIS
Initialisiert ein Level-2-Projekt idempotent. / Idempotently initializes a level-2 project.

.DESCRIPTION
Kopiert die Level-0-Basis, richtet Agenten und Spec Kit ein und installiert das
aufgeloeste Governance-Preset-Profil. Die Constitution-Version wird fail-closed
aus genau einer Überschrift `# Constitution vX.Y.Z` gelesen. `-Preview` und
`-WhatIf` schreiben nichts.

Copies the level-0 baseline, initializes agents and Spec Kit, and installs the
resolved governance preset profile. The constitution version is read
fail-closed from exactly one `# Constitution vX.Y.Z` heading. `-Preview` and
`-WhatIf` do not write.

.PARAMETER ProjectName
Projektname. / Project name.
.PARAMETER TargetWorkspace
Ziel-Workspace. / Target workspace.
.PARAMETER Preview
Nur Vorschau. / Preview only.
.PARAMETER Force
Vorhandene Dateien überschreiben. / Overwrite existing files.
.PARAMETER NoAgents
Agenten-Initialisierung auslassen. / Skip agent initialization.
.PARAMETER NoSpeckit
Spec Kit auslassen. / Skip Spec Kit.
.PARAMETER NoGovernancePresets
Governance-Presets auslassen und Profil `none` registrieren. / Skip presets and register `none`.
.PARAMETER NoRemote
Nur lokal initialisieren. / Initialize locally only.
.PARAMETER NoReleasePlease
Release Please auslassen. / Skip Release Please.
.PARAMETER PresetProfile
Explizites Profil aus `spec-kit-preset-profiles.json`; überschreibt Registry- und Katalog-Standard.

Explicit profile from `spec-kit-preset-profiles.json`; overrides registry and catalog defaults.
.PARAMETER Platform
Git-Hosting-Plattform. / Git hosting platform.
.PARAMETER GitLabUrl
GitLab-Basis-URL. / GitLab base URL.
.PARAMETER ForgejoUrl
Forgejo-Basis-URL. / Forgejo base URL.
.PARAMETER Lang
Primärsprache der Vorlagen. / Primary template language.
.PARAMETER PrimaryLanguage
Primäre Implementierungssprache. / Primary implementation language.

.EXAMPLE
pwsh -NoProfile -File scripts/bootstrap-project.ps1 -ProjectName Example -NoRemote -PresetProfile intake-sequencing-eleven-governance-presets -Preview
#>
# FR-009–016; Contract: bootstrap-project-cli.md

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [string]$TargetWorkspace = $PWD.Path,
    [switch]$Preview,
    [switch]$Force,
    [switch]$NoAgents,
    [switch]$NoSpeckit,
    [switch]$NoGovernancePresets,
    [switch]$NoRemote,
    [switch]$NoReleasePlease,
    [string]$PresetProfile = '',
    [string]$Platform = 'github',
    [string]$GitLabUrl = 'https://gitlab.com',
    [string]$ForgejoUrl = '',
    [ValidateSet('de','en')][string]$Lang = 'de',
    [string]$PrimaryLanguage = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplatesDir = Join-Path $ScriptDir 'templates'
$SecureDevLib = Join-Path $ScriptDir 'lib/secure-development-hardening.ps1'
$ForgejoLib   = Join-Path $ScriptDir 'lib/hg-forgejo.ps1'
$PresetProfileCatalog = Join-Path $ScriptDir 'config/spec-kit-preset-profiles.json'
if (Test-Path $SecureDevLib) {
    . $SecureDevLib
}
if (-not (Test-Path $ForgejoLib)) {
    throw "Forgejo support library is missing: $ForgejoLib"
}
. $ForgejoLib
$Preview = $Preview -or $WhatIfPreference
$TargetWorkspace = $TargetWorkspace.TrimEnd([IO.Path]::DirectorySeparatorChar)
$TargetDir    = Join-Path $TargetWorkspace $ProjectName

$Step = 0
$TotalSteps = 31
$Skipped = 0
$PartialFail = $false
$gitlabHostname = ''
$gitlabUser = ''
$forgejoBaseUrl = ''
$projectSlug = ''
$projectSlugChanged = $false
$summaryRepoUrl = ''
$summaryDisplayRepo = ''
$WorkspaceGitignoreHeader = '# Sub-Verzeichnisse mit eigenen Git-Repositories (automatisch erkannt)'
$SpecifyAgents = @('agy', 'opencode', 'claude', 'copilot', 'codex')
$HomeRoot = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$HomeConstitution = Join-Path $HomeRoot 'constitution.md'

function Get-HBConstitutionVersion {
    param([Parameter(Mandatory)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Constitution fehlt / missing: ${Path}"
    }
    $versionMatches = @(
        Get-Content -LiteralPath $Path |
            Where-Object { $_ -match '^# Constitution (v\d+\.\d+\.\d+)$' } |
            ForEach-Object { [regex]::Match($_, '^# Constitution (v\d+\.\d+\.\d+)$').Groups[1].Value }
    )
    if ($versionMatches.Count -ne 1) {
        throw "Constitution-Version muss genau einmal als '# Constitution vX.Y.Z' vorkommen / must occur exactly once: ${Path}"
    }
    return $versionMatches[0]
}

function Resolve-HBBootstrapPresetProfile {
    param(
        [string] $RequestedProfile,
        [switch] $SkipSpecKit,
        [switch] $SkipGovernancePresets
    )

    if (-not (Test-Path -LiteralPath $PresetProfileCatalog -PathType Leaf)) {
        throw "Preset-Profilkatalog fehlt / missing: ${PresetProfileCatalog}"
    }
    if (($SkipSpecKit -or $SkipGovernancePresets) -and $RequestedProfile -notin @('', 'none')) {
        throw '-PresetProfile conflicts with -NoSpeckit/-NoGovernancePresets'
    }

    $catalog = Get-Content -LiteralPath $PresetProfileCatalog -Raw -Encoding UTF8 | ConvertFrom-Json
    $registryPath = Join-Path $HomeRoot '.home-baseline/level2-repository-registry.json'
    if ($SkipSpecKit -or $SkipGovernancePresets) {
        $selected = 'none'
    } elseif ($RequestedProfile) {
        $selected = $RequestedProfile
    } elseif (Test-Path -LiteralPath $registryPath -PathType Leaf) {
        $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $selected = if (($registry.PSObject.Properties.Name -contains 'defaultPresetProfile') -and $registry.defaultPresetProfile) {
            [string]$registry.defaultPresetProfile
        } else {
            [string]$catalog.defaultProfile
        }
    } else {
        $selected = [string]$catalog.defaultProfile
    }

    $profileProperty = $catalog.profiles.PSObject.Properties[$selected]
    if ($null -eq $profileProperty) {
        throw "Unbekanntes Preset-Profil / unknown preset profile: ${selected}"
    }

    $configuredPath = $profileProperty.Value.presetConfig
    if ($null -eq $configuredPath) {
        $resolvedConfig = 'none'
    } else {
        $repositoryRoot = Split-Path -Parent $ScriptDir
        $resolvedConfig = Join-Path $repositoryRoot ([string]$configuredPath)
        if (-not (Test-Path -LiteralPath $resolvedConfig -PathType Leaf)) {
            throw "Preset-Konfiguration fehlt / missing: ${resolvedConfig}"
        }
    }

    return [pscustomobject]@{
        Name = $selected
        ConfigPath = $resolvedConfig
    }
}

$ResolvedConstitutionVersion = Get-HBConstitutionVersion -Path $HomeConstitution
$ResolvedPresetProfile = Resolve-HBBootstrapPresetProfile `
    -RequestedProfile $PresetProfile `
    -SkipSpecKit:$NoSpeckit `
    -SkipGovernancePresets:$NoGovernancePresets

function Render-Template {
    param([string]$Template, [string]$Output)
    $wsShort = $TargetWorkspace -replace [regex]::Escape($(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE })), '~'
    (Get-Content $Template) `
        -replace '\{\{PROJECT_NAME\}\}', $ProjectName `
        -replace '\{\{WORKSPACE\}\}', $wsShort |
        Set-Content -Path $Output -Encoding UTF8
}

function Step-Start { param([string]$Desc)
    $script:Step++
    Write-Host ("[{0}/{1}] -> {2,-44}" -f $script:Step, $TotalSteps, $Desc) -NoNewline
}
function Step-Done  { param([string]$Note='')
    if ($Note) { Write-Host " ✓  $Note" } else { Write-Host " ✓" }
}
function Step-Skip  { param([string]$Why='already done')
    Write-Host " (skip: $Why)"; $script:Skipped++
}
function Step-Warn  { param([string]$Msg)
    Write-Host " WARN: $Msg"; $script:PartialFail = $true
}

function Set-DefaultWorkspaceGitignore {
    param(
        [string]$Path,
        [string[]]$ProjectNames
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($script:WorkspaceGitignoreHeader)
    foreach ($name in $ProjectNames) {
        $lines.Add("$name/")
    }
    $lines.Add('')
    $lines.AddRange(@(
        '# macOS',
        '.DS_Store',
        '.AppleDouble',
        '.LSOverride',
        '',
        '# JetBrains IDEs',
        '.idea/',
        '*.iws',
        '*.iml',
        '',
        '# VS Code (lokale Einstellungen)',
        '.vscode/c_cpp_properties.json',
        '.vscode/settings.json',
        '',
        '# Build-Artefakte',
        'bin/',
        'obj/',
        'build/',
        'node_modules/'
    ))
    $lines | Set-Content -Path $Path -Encoding UTF8
}

function Update-WorkspaceGitignoreEntry {
    param(
        [string]$WorkspaceDir,
        [string]$ProjectName
    )

    $gitignorePath = Join-Path $WorkspaceDir '.gitignore'
    $entry = "$ProjectName/"

    if (-not $ProjectName) {
        return 'Unchanged'
    }

    if (-not (Test-Path $gitignorePath)) {
        if ($WhatIfPreference) {
            return 'WouldCreate'
        }
        Set-DefaultWorkspaceGitignore -Path $gitignorePath -ProjectNames @($ProjectName)
        return 'Created'
    }

    $lines = Get-Content $gitignorePath
    if ($lines -contains $entry) {
        return 'Unchanged'
    }

    if ($WhatIfPreference) {
        return 'WouldUpdate'
    }

    $updated = [System.Collections.Generic.List[string]]::new()
    $headerIndex = [Array]::IndexOf($lines, $script:WorkspaceGitignoreHeader)
    if ($headerIndex -ge 0) {
        $insertIndex = $lines.Length
        for ($i = $headerIndex + 1; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -eq '') {
                $insertIndex = $i
                break
            }
        }
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($i -eq $insertIndex) {
                $updated.Add($entry)
            }
            $updated.Add($lines[$i])
        }
        if ($insertIndex -eq $lines.Length) {
            $updated.Add($entry)
        }
    } else {
        $updated.Add($script:WorkspaceGitignoreHeader)
        $updated.Add($entry)
        $updated.Add('')
        $updated.AddRange($lines)
    }

    $updated | Set-Content -Path $gitignorePath -Encoding UTF8
    return 'Updated'
}

function ConvertTo-GitLabSlug([string]$Name) {
    $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
}

function Convert-RemoteUrlToRepoUrl([string]$RemoteUrl) {
    if ($RemoteUrl -like 'https://*') {
        return ($RemoteUrl -replace '\.git$', '')
    }
    if ($RemoteUrl -match '^git@([^:]+):(.+)$') {
        return ('https://' + $Matches[1] + '/' + ($Matches[2] -replace '\.git$', ''))
    }
    if ($RemoteUrl -match '^ssh://git@([^/]+)/(.+)$') {
        return ('https://' + $Matches[1] + '/' + ($Matches[2] -replace '\.git$', ''))
    }
    return ($RemoteUrl -replace '\.git$', '')
}

function Get-RepoNameFromRemoteUrl([string]$RemoteUrl) {
    $repoUrl = Convert-RemoteUrlToRepoUrl $RemoteUrl
    return [IO.Path]::GetFileName($repoUrl)
}

if ($Platform -notin @('github', 'gitlab', 'forgejo', 'codeberg')) {
    Write-Error "Fehler: Ungültige Plattform '$Platform'. Gültige Werte: github, gitlab, forgejo, codeberg.`nError: Invalid platform '$Platform'. Valid values: github, gitlab, forgejo, codeberg."
    exit 2
}

if (-not $NoRemote -and $Platform -in @('forgejo', 'codeberg')) {
    try {
        $forgejoBaseUrl = Resolve-HBForgejoBaseUrl -Platform $Platform -ConfiguredUrl $ForgejoUrl
    } catch {
        Write-Error $_.Exception.Message
        exit 2
    }
    $projectSlug = ConvertTo-GitLabSlug $ProjectName
    $projectSlugChanged = $projectSlug -ne $ProjectName
}

if ($Platform -eq 'gitlab') {
    if (-not $GitLabUrl.StartsWith('https://')) {
        Write-Error "Fehler: -GitLabUrl muss mit 'https://' beginnen.`nError: -GitLabUrl must start with 'https://'."
        exit 2
    }
    $gitlabHostname = ($GitLabUrl -replace '^https://', '').TrimEnd('/')
    $projectSlug = ConvertTo-GitLabSlug $ProjectName
    $projectSlugChanged = $projectSlug -ne $ProjectName

    if (-not $NoRemote -and -not $Preview) {
        if (-not (Get-Command glab -ErrorAction SilentlyContinue)) {
            Write-Error "Fehler: glab (GitLab CLI) ist nicht installiert.`n  macOS/Linux: brew install glab`n  Windows: winget install GLabCLI.GlabCLI`nError: glab (GitLab CLI) is not installed."
            exit 2
        }

        $env:GITLAB_HOST = $gitlabHostname
        & glab auth status 2>$null | Out-Null
        $authExitCode = $LASTEXITCODE
        $env:GITLAB_HOST = $null
        if ($authExitCode -ne 0) {
            Write-Error "Fehler: Nicht bei GitLab ($gitlabHostname) authentifiziert. Bitte 'glab auth login' ausführen.`nError: Not authenticated with GitLab ($gitlabHostname). Please run 'glab auth login'."
            exit 2
        }

        $gitlabUserResponse = ((& glab api user --hostname $gitlabHostname 2>$null) | Out-String).Trim()
        $gitlabUser = ''
        if ($gitlabUserResponse) {
            try {
                $gitlabUser = ((($gitlabUserResponse | ConvertFrom-Json).username) | Out-String).Trim()
            } catch {
                $gitlabUser = ''
            }
        }
        if (-not $gitlabUser) {
            Write-Error "Fehler: GitLab-Benutzername konnte nicht ermittelt werden.`nError: Could not retrieve GitLab username."
            exit 2
        }
    }
}

# ─── Preview Mode ────────────────────────────────────────────────────────────
if ($Preview) {
    Write-Host "[PREVIEW] Folgende Aktionen wuerden ausgefuehrt:"
    $previewActions = [System.Collections.Generic.List[object[]]]::new()
    $null = $previewActions.Add(@('CREATE', $TargetDir))
    $null = $previewActions.Add(@('EXEC', "git init $TargetDir"))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/AGENTS.md", 'aus AGENTS.md.tmpl'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/CLAUDE.md", 'aus CLAUDE.md.tmpl'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/GEMINI.md", 'aus GEMINI.md.tmpl'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/.github/copilot-instructions.md", 'aus copilot-instructions.tmpl'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/README.md", 'aus readme-template.md / README.md.tmpl'))
    $null = $previewActions.Add(@('COPY', "$TargetDir/constitution.md", 'von ~/constitution.md'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/.github/workflows/homogeneity-check.yml", "Constitution $ResolvedConstitutionVersion"))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/docs/project-statistics.md", 'Statistik-Ledger (initial)'))
    $null = $previewActions.Add(@('PREPARE', "$TargetDir/docs/secure-development/", 'Hardening bei erkannter MSL; RL-SE unabhaengig davon'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/Lastenheft_Secure-Development-Hardening.md", 'bei erkannter MSL'))
    $null = $previewActions.Add(@('UPDATE', "$TargetDir/Lastenheft_Abarbeitungsreihenfolge.md", 'Lastenheft*.md-Reihenfolge'))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/STATS.md"))
    $null = $previewActions.Add(@('CREATE', "$TargetDir/.gitignore", 'aus gitignore-project.tmpl'))
    $null = $previewActions.Add(@('UPDATE', "$TargetWorkspace/.gitignore", 'Level-2-Projekt im Workspace ignorieren'))
    if (-not $NoReleasePlease -and -not $NoRemote) {
        if ($Platform -eq 'github') {
            $null = $previewActions.Add(@('CREATE', "$TargetDir/release-please-config.json", 'Release Please Konfiguration'))
            $null = $previewActions.Add(@('CREATE', "$TargetDir/.release-please-manifest.json", 'Release Please Manifest'))
            $null = $previewActions.Add(@('CREATE', "$TargetDir/.github/workflows/release-please.yml", 'Release Please Workflow'))
        } elseif ($Platform -eq 'gitlab') {
            $null = $previewActions.Add(@('PRINT', 'setup-gitlab-release.ps1 nach Projekt-CI ausfuehren', 'GitLab Release-Automation'))
        } else {
            $null = $previewActions.Add(@('PRINT', 'Forgejo-Actions-Konfiguration institutionell freigeben', 'keine ungepruefte Release-Automation'))
        }
    }
    $null = $previewActions.Add(@('COPY', "$TargetDir/scripts/", 'von ~/scripts/'))
    $null = $previewActions.Add(@('INSTALL', "$TargetDir/.git/hooks/pre-push"))
    $null = $previewActions.Add(@('EXEC', "git commit -m 'feat: initial project bootstrap'"))

    if ($NoRemote) {
        $null = $previewActions.Add(@('SKIP', 'Remote-Erstellung', '--no-remote'))
    } elseif ($Platform -eq 'github') {
        $null = $previewActions.Add(@('EXEC', 'gh repo create (privat)', 'optional'))
        $null = $previewActions.Add(@('EXEC', 'git push', 'optional'))
        if (-not $NoReleasePlease) {
            $null = $previewActions.Add(@('EXEC', 'gh api repos/.../actions/permissions/workflow', 'GitHub Actions: PR-Erstellung erlauben'))
        }
    } elseif ($Platform -eq 'gitlab') {
        $null = $previewActions.Add(@('EXEC', 'glab repo create (privat)', 'optional'))
        $null = $previewActions.Add(@('EXEC', 'git remote add origin https://HOST/USER/REPO.git', 'optional'))
        $null = $previewActions.Add(@('EXEC', 'git push', 'optional'))
    } else {
        $null = $previewActions.Add(@('EXEC', 'Forgejo API: Repository privat anlegen oder wiederverwenden', $forgejoBaseUrl))
        $null = $previewActions.Add(@('EXEC', 'git remote add origin <API-CLONE-URL>', 'HTTPS + Credential Helper'))
        $null = $previewActions.Add(@('EXEC', 'git push', 'optional'))
    }

    $null = $previewActions.Add(@('EXEC', "claude /init", 'optional'))
    $null = $previewActions.Add(@('PRINT', "Codex manuelle Anweisung"))
    $null = $previewActions.Add(@('PRINT', "Gemini manuelle Anweisung"))
    $null = $previewActions.Add(@('CHECK', 'copilot --version', 'Required-Host-Baseline'))
    foreach ($agent in $SpecifyAgents) {
        $null = $previewActions.Add(@('EXEC', "specify init --here --force --integration $agent", 'optional'))
    }
    if ($ResolvedPresetProfile.Name -ne 'none') {
        $null = $previewActions.Add(@('EXEC', "install-spec-kit-governance-presets.ps1 -Repo $TargetDir -PresetConfig $($ResolvedPresetProfile.ConfigPath)", $ResolvedPresetProfile.Name))
    }
    $null = $previewActions.Add(@('UPDATE', '~/.home-baseline/level2-repository-registry.json', "$($ResolvedPresetProfile.Name); MSL getrennt klassifiziert"))
    $null = $previewActions.Add(@('EXEC', "init-stats.sh (Baseline)", 'STATS.md'))
    $null = $previewActions.Add(@('UPDATE', "$(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE })/README.md"))

    $previewActions | ForEach-Object {
        $note = if ($_.Count -gt 2) { "($($_[2]))" } else { '' }
        $shortPath = $_[1] -replace [regex]::Escape($(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE })), '~'
        Write-Host ("  {0,-8} {1,-50} {2}" -f $_[0], $shortPath, $note)
    }
    Write-Host "  [Keine Dateien wurden geschrieben]"
    exit 0
}

# ─── Pre-flight ───────────────────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "FATAL: git not found"
    exit 2
}
if (-not (Test-Path $TargetWorkspace)) {
    Write-Error "FATAL: target workspace does not exist: $TargetWorkspace"
    exit 2
}

# ─── Header ───────────────────────────────────────────────────────────────────
Write-Host ('=' * 50)
Write-Host "  bootstrap-project — Workspace Homogeneity Guardian"
Write-Host ('=' * 50)
Write-Host ""
Write-Host "Projekt:    $ProjectName"
$wsShort = $TargetWorkspace -replace [regex]::Escape($(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE })), '~'
Write-Host "Workspace:  $wsShort"
$tdShort = $TargetDir -replace [regex]::Escape($(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE })), '~'
Write-Host "Ziel:       $tdShort"
Write-Host "Presets:    $($ResolvedPresetProfile.Name)"
Write-Host ""

# ─── Steps ────────────────────────────────────────────────────────────────────

# 1. Create directory
Step-Start "Verzeichnis anlegen"
if (Test-Path $TargetDir) { Step-Skip "existiert bereits" }
else { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null; Step-Done }

# 2. git init
Step-Start "git init"
if (Test-Path (Join-Path $TargetDir '.git')) { Step-Skip ".git/ vorhanden" }
else { git init $TargetDir 2>$null | Out-Null; Step-Done }

# 2b. Lokale git-Einstellungen / Local git settings
Step-Start "Lokale git-Einstellungen / Local git settings"
if (Test-Path (Join-Path $TargetDir '.git')) {
    $autocrlf = if ($IsWindows) { 'true' } else { 'input' }
    git -C $TargetDir config --local core.autocrlf $autocrlf 2>$null | Out-Null
    Step-Done "Lokale git-Einstellungen gesetzt / Local git settings applied"
} else { Step-Skip "git-Repo noch nicht initialisiert / git repo not yet initialized" }

# 3. AGENTS.md
Step-Start "AGENTS.md erzeugen"
$f = Join-Path $TargetDir 'AGENTS.md'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
elseif (Test-Path (Join-Path $TemplatesDir 'AGENTS.md.tmpl')) { Render-Template (Join-Path $TemplatesDir 'AGENTS.md.tmpl') $f; Step-Done }
else { Step-Warn "Template nicht gefunden: AGENTS.md.tmpl" }

# 4. CLAUDE.md
Step-Start "CLAUDE.md erzeugen"
$f = Join-Path $TargetDir 'CLAUDE.md'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
elseif (Test-Path (Join-Path $TemplatesDir 'CLAUDE.md.tmpl')) { Render-Template (Join-Path $TemplatesDir 'CLAUDE.md.tmpl') $f; Step-Done }
else { Step-Warn "Template nicht gefunden: CLAUDE.md.tmpl" }

# 5. GEMINI.md
Step-Start "GEMINI.md erzeugen"
$f = Join-Path $TargetDir 'GEMINI.md'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
elseif (Test-Path (Join-Path $TemplatesDir 'GEMINI.md.tmpl')) { Render-Template (Join-Path $TemplatesDir 'GEMINI.md.tmpl') $f; Step-Done }
else { Step-Warn "Template nicht gefunden: GEMINI.md.tmpl" }

# 6. copilot-instructions.md
Step-Start "copilot-instructions.md erzeugen"
$cpDir = Join-Path $TargetDir '.github'
$f = Join-Path $cpDir 'copilot-instructions.md'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
else {
    New-Item -ItemType Directory -Path $cpDir -Force | Out-Null
    $tmpl = Join-Path $TemplatesDir 'copilot-instructions.tmpl'
    if (Test-Path $tmpl) { Render-Template $tmpl $f; Step-Done }
    else { Step-Warn "Template nicht gefunden: copilot-instructions.tmpl" }
}

# 7. README.md
Step-Start "README.md erzeugen"
$f = Join-Path $TargetDir 'README.md'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
else {
    $readmeTmpl = Join-Path $TemplatesDir 'readme-template.md'
    if (-not (Test-Path $readmeTmpl)) { $readmeTmpl = Join-Path $TemplatesDir 'README.md.tmpl' }
    if (Test-Path $readmeTmpl) { Render-Template $readmeTmpl $f; Step-Done }
    else { Step-Warn "Template nicht gefunden: readme-template.md / README.md.tmpl" }
}

# 7b. constitution.md
Step-Start "constitution.md kopieren"
$fc = Join-Path $TargetDir 'constitution.md'
if (-not (Test-Path $HomeConstitution)) { Step-Warn "~/constitution.md fehlt — bitte sync-constitution.ps1 ausfuehren" }
elseif ((Test-Path $fc) -and -not $Force) { Step-Skip "Datei existiert" }
else { Copy-Item $HomeConstitution $fc; Step-Done }

# 7c. homogeneity-check.yml
Step-Start "homogeneity-check.yml erzeugen"
$wfDir  = Join-Path $TargetDir '.github' | Join-Path -ChildPath 'workflows'
$wfFile = Join-Path $wfDir 'homogeneity-check.yml'
if ((Test-Path $wfFile) -and -not $Force) { Step-Skip "Datei existiert" }
else {
    New-Item -ItemType Directory -Path $wfDir -Force | Out-Null
    @"
name: Homogeneity Check

on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main, master]

jobs:
  homogeneity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ripgrep
        run: sudo apt-get install -y ripgrep
      - name: Run homogeneity check
        run: bash scripts/check-homogeneity.sh --json --fail-fast .
        env:
          CONSTITUTION_VERSION: "$ResolvedConstitutionVersion"
"@ | Set-Content $wfFile -Encoding UTF8
    Step-Done
}

# 7d. docs/project-statistics.md
Step-Start "docs/project-statistics.md erzeugen"
$statsDoc = Join-Path $TargetDir 'docs/project-statistics.md'
if ((Test-Path $statsDoc) -and -not $Force) { Step-Skip "Datei existiert" }
else {
    New-Item -ItemType Directory -Path (Join-Path $TargetDir 'docs') -Force | Out-Null
    $today = (Get-Date -Format 'yyyy-MM-dd')
    @"
# Projektstatistik / Project Statistics — $ProjectName

> **Lebendiges Dokument / Living document** — nach jedem abgeschlossenen Feature,
> jeder Spec-Kit-Phase und auf explizite Anfrage aktualisieren.
>
> *Update after every completed feature, Spec-Kit phase, or on explicit request.*

---

## Fortschreibungsprotokoll / Update Log

Ältester Eintrag oben, neuester Eintrag unten.
*Oldest entry at top, newest entry at bottom.*

| Datum / Date | Phase / Branch | Aktivtage ges. | Zeilen ges. | Commits ges. | Hauptarbeitspakete / Main Work Packages |
|---|---|---:|---:|---:|---|
| $today | 0 — Bootstrap | 1 | — | 1 | Initialer Projekt-Bootstrap via bootstrap-project |

---

## Gesamtstand des Repositories / Repository Snapshot

Stand / As of: $today — *Erste Einträge nach dem initialen Arbeitspaket eintragen.*

| Kategorie / Category | Dateien / Files | Zeilen / Lines | Anteil / Share |
|---|---:|---:|---:|
| Produktionscode / Production code | — | — | — |
| Tests / Tests | — | — | — |
| Dokumentation / Documentation (.md) | — | — | — |
| **Gesamt / Total** | — | — | — |

---

## Gesamtstatistik / Overall Statistics

*Wird nach dem ersten dokumentierten Arbeitspaket befüllt.*
*To be filled after the first documented work package.*

| Kennzahl / Metric | Verdichteter Gesamtblick / Condensed Overview |
|---|---:|
| Artefaktbasis gesamt | — |
| Beobachtbarer Projektzeitraum | $today bis — |
| Sichtbare Git-Aktivtage | — |
| Repo-weiter Speedup gg. 80-Zeilen-Referenz | — |
| Repo-weiter Speedup gg. Thorsten-Referenz | — |
"@ | Set-Content $statsDoc -Encoding UTF8
    Step-Done
}

$statsConfig = Join-Path $TargetDir 'docs/project-statistics.config.json'
if ((Test-Path $statsConfig) -and -not $Force) {
    Step-Skip "Statistikprofil-2-Konfiguration vorhanden"
} else {
    [ordered]@{
        '$schema' = '../scripts/config/project-statistics.schema.json'
        schemaVersion = 1
        methodologyVersion = 2
        repositoryName = $ProjectName
        timeZone = 'Europe/Berlin'
        activityWindowWeeks = 52
        references = [ordered]@{
            conservativeLinesPerDay = 80
            thorstenLinesPerDay = 125
        }
        phases = @()
        excludedPaths = @()
        categoryOverrides = @()
    } | ConvertTo-Json -Depth 10 | Set-Content $statsConfig -Encoding UTF8
    Step-Done "Statistikprofil-2-Konfiguration"
}

# 7e. Secure-Development-Hardening vorbereiten
Step-Start "Secure-Development-Hardening vorbereiten"
if (-not (Test-Path $SecureDevLib) -or -not (Get-Command Invoke-SdhPrepareRepo -ErrorAction SilentlyContinue)) {
    Step-Warn "Secure-Development-Hardening-Hilfslogik nicht gefunden"
} else {
    $ok = Invoke-SdhPrepareRepo `
        -Repo $TargetDir `
        -ProjectName $ProjectName `
        -PrimaryLanguage $PrimaryLanguage `
        -ScriptDir $ScriptDir
    if (-not $ok) {
        Step-Warn $script:SdhPrepareReason
    } else {
        switch ($script:SdhPrepareResult) {
            'prepared' { Step-Done $script:SdhPrepareReason }
            'skipped'  { Step-Skip $script:SdhPrepareReason }
            default    { Step-Done "$script:SdhPrepareResult $script:SdhPrepareReason" }
        }
    }
}

# 7f. RL-SE-/Checklist-Selbstpruefung vorbereiten
Step-Start "RL-SE-/Checklist-Selbstpruefung vorbereiten"
$rlSeScript = Join-Path $ScriptDir 'prepare-rl-se-checklist-selbstpruefung.ps1'
if (-not (Test-Path $rlSeScript)) {
    Step-Warn "RL-SE-/Checklist-Selbstpruefungs-Skript nicht gefunden"
} else {
    $rlSeArgs = @('-Repo', $TargetDir, '-AllowDirty')
    if ($PrimaryLanguage) { $rlSeArgs += @('-PrimaryLanguage', $PrimaryLanguage) }
    try {
        & $rlSeScript @rlSeArgs | Out-Null
        Step-Done "Intake und Reihenfolge vorbereitet"
    } catch {
        Step-Warn "RL-SE-/Checklist-Selbstpruefung konnte nicht vorbereitet werden: $($_.Exception.Message)"
    }
}

# 8. STATS.md
Step-Start "STATS.md (initial) erzeugen"
$f = Join-Path $TargetDir 'STATS.md'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
else { "# STATS.md -- $ProjectName`n`nCompliance-Historie / Compliance History`n" | Set-Content $f -Encoding UTF8; Step-Done }

# 9. .gitignore
Step-Start ".gitignore erzeugen"
$f = Join-Path $TargetDir '.gitignore'
if ((Test-Path $f) -and -not $Force) { Step-Skip "Datei existiert" }
elseif (Test-Path (Join-Path $TemplatesDir 'gitignore-project.tmpl')) {
    Copy-Item (Join-Path $TemplatesDir 'gitignore-project.tmpl') $f
    Step-Done
} else { Step-Warn "Template nicht gefunden: gitignore-project.tmpl" }

# 9a. Workspace-.gitignore
Step-Start "Workspace-.gitignore aktualisieren"
$workspaceGitignoreState = Update-WorkspaceGitignoreEntry -WorkspaceDir $TargetWorkspace -ProjectName $ProjectName
switch ($workspaceGitignoreState) {
    'Created'     { Step-Done "Workspace-.gitignore erstellt und $ProjectName/ eingetragen" }
    'Updated'     { Step-Done "$ProjectName/ im Workspace ignoriert" }
    'WouldCreate' { Step-Done "wuerde Workspace-.gitignore erstellen und $ProjectName/ eintragen" }
    'WouldUpdate' { Step-Done "wuerde $ProjectName/ im Workspace ignorieren" }
    default       { Step-Skip "Eintrag vorhanden" }
}

# 9b. Release-Automation einrichten
Step-Start "Release-Automation einrichten"
if ($NoReleasePlease) { Step-Skip "-NoReleasePlease" }
elseif ($NoRemote) { Step-Skip "-NoRemote" }
elseif ($Platform -eq 'gitlab') { Step-Skip "GitLab: via setup-gitlab-release.ps1" }
elseif ($Platform -in @('forgejo', 'codeberg')) { Step-Skip "Forgejo Actions: institutionell freigegebene Konfiguration erforderlich" }
elseif ((Test-Path (Join-Path $TargetDir 'release-please-config.json')) -and -not $Force) { Step-Skip "Konfiguration existiert bereits" }
else {
    New-Item -ItemType Directory -Path (Join-Path $TargetDir '.github/workflows') -Force | Out-Null
    @'
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "simple",
  "packages": {
    ".": {
      "changelog-sections": [
        {"type": "feat",     "section": "Features / Neue Funktionen"},
        {"type": "fix",      "section": "Bug Fixes / Fehlerbehebungen"},
        {"type": "docs",     "section": "Documentation / Dokumentation"},
        {"type": "chore",    "section": "Maintenance / Wartung", "hidden": false},
        {"type": "refactor", "section": "Refactoring", "hidden": true}
      ]
    }
  }
}
'@ | Set-Content (Join-Path $TargetDir 'release-please-config.json') -Encoding UTF8
    @'
{
  ".": "0.1.0"
}
'@ | Set-Content (Join-Path $TargetDir '.release-please-manifest.json') -Encoding UTF8
    @'
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      # Pinned Node.js 24-capable upstream SHA until the next tagged v4 release targets node24.
      - uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
'@ | Set-Content (Join-Path $TargetDir '.github/workflows/release-please.yml') -Encoding UTF8
    Step-Done
}

# 10. Copy scripts/
Step-Start "scripts/ kopieren"
$scriptsTarget = Join-Path $TargetDir 'scripts'
if ((Test-Path $scriptsTarget) -and -not $Force) { Step-Skip "scripts/ vorhanden" }
elseif (Test-Path $ScriptDir) { Copy-Item $ScriptDir $scriptsTarget -Recurse -Force; Step-Done }
else { Step-Warn "~/scripts/ nicht gefunden" }

# 11. Install hook
Step-Start "pre-push Hook installieren"
$hookSrc = Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) 'scripts/hooks/pre-push'
$hookDst = Join-Path $TargetDir '.git/hooks/pre-push'
if (Test-Path $hookSrc) {
    $hooksDir = Split-Path $hookDst
    if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
    if ((Test-Path $hookDst) -and -not $Force) {
        $srcH = (Get-FileHash -Algorithm SHA256 $hookSrc).Hash
        $dstH = (Get-FileHash -Algorithm SHA256 $hookDst).Hash
        if ($srcH -eq $dstH) { Step-Skip "Hook SHA-256 match" }
        else { Copy-Item $hookSrc $hookDst -Force; Step-Done "aktualisiert" }
    } else { Copy-Item $hookSrc $hookDst -Force; Step-Done }
} else { Step-Warn "~/scripts/hooks/pre-push nicht gefunden" }

# 12. Initial commit
Step-Start "Initialer git-Commit"
$logOutput = git -C $TargetDir log --oneline 2>$null
if ($logOutput) { Step-Skip "Commits vorhanden" }
else {
    git -C $TargetDir add -A 2>$null | Out-Null
    git -C $TargetDir commit -m "feat: initial project bootstrap -- $ProjectName" 2>$null | Out-Null
    Step-Done
}

Step-Start "ASCII-Statistikprofil 2 initialisieren"
$statisticsRenderer = Join-Path $TargetDir 'scripts/render-project-statistics.ps1'
if (-not (Test-Path $statisticsRenderer)) {
    Step-Warn "Statistikrenderer nicht gefunden"
} else {
    & pwsh -NoProfile -File $statisticsRenderer -Repo $TargetDir 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $statisticsStatus = (& git -C $TargetDir status --porcelain -- docs/project-statistics.md 2>$null | Out-String).Trim()
        if ($statisticsStatus) {
            git -C $TargetDir add docs/project-statistics.md 2>$null | Out-Null
            $statisticsCommitMessage = @'
docs: initialize ASCII statistics profile 2

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
'@
            git -C $TargetDir commit -m $statisticsCommitMessage 2>$null | Out-Null
        }
        Step-Done
    } else {
        Step-Warn "ASCII-Statistikprofil 2 konnte nicht initialisiert werden"
    }
}

# 13. Repo create
Step-Start "Repo erstellen (privat)"
$existingRemote = ''
if (-not $NoRemote) {
    $existingRemote = (& git -C $TargetDir remote get-url origin 2>$null | Out-String).Trim()
}
if ($NoRemote) { Step-Skip "-NoRemote" }
elseif ($existingRemote) {
    $summaryRepoUrl = Convert-RemoteUrlToRepoUrl $existingRemote
    $summaryDisplayRepo = Get-RepoNameFromRemoteUrl $existingRemote
    Step-Skip "Remote vorhanden"
}
elseif ($Platform -eq 'github' -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    $repoName = $ProjectName.ToLower() -replace '\s+','-'
    & gh repo create $repoName --private --source $TargetDir --remote origin 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ghUser = ((gh api user --jq '.login' 2>$null) | Out-String).Trim()
        $summaryRepoUrl = "https://github.com/$ghUser/$repoName"
        $summaryDisplayRepo = $repoName
        Step-Done $repoName
    } else { Step-Warn "gh repo create fehlgeschlagen" }
}
elseif ($Platform -eq 'gitlab') {
    $remoteUrl = "https://$gitlabHostname/$gitlabUser/$projectSlug.git"
    $env:GITLAB_HOST = $gitlabHostname
    & glab repo create $projectSlug --private 2>$null | Out-Null
    $env:GITLAB_HOST = $null
    if ($LASTEXITCODE -eq 0) {
        git -C $TargetDir remote add origin $remoteUrl 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $summaryRepoUrl = "$($GitLabUrl.TrimEnd('/'))/$gitlabUser/$projectSlug"
            $summaryDisplayRepo = $projectSlug
            Step-Done $projectSlug
        } else {
            Step-Warn "git remote add origin fehlgeschlagen / git remote add origin failed"
        }
    } else { Step-Warn "glab repo create fehlgeschlagen / glab repo create failed" }
} elseif ($Platform -in @('forgejo', 'codeberg')) {
    try {
        $repository = New-HBForgejoRepository -BaseUrl $forgejoBaseUrl -RepositoryName $projectSlug -Description "Project repository for $ProjectName"
        git -C $TargetDir remote add origin $repository.CloneUrl 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'git remote add origin failed' }
        git -C $TargetDir config --local home-baseline.remote-platform $Platform
        git -C $TargetDir config --local home-baseline.remote-base-url $forgejoBaseUrl
        git -C $TargetDir config --local home-baseline.remote-owner $repository.Owner
        git -C $TargetDir config --local home-baseline.remote-repository $repository.Name
        $summaryRepoUrl = $repository.HtmlUrl
        $summaryDisplayRepo = $repository.Name
        Step-Done $(if ($repository.Created) { "$projectSlug erstellt" } else { "$projectSlug wiederverwendet" })
    } catch {
        Step-Warn "Forgejo-Repository konnte nicht erstellt oder gelesen werden: $($_.Exception.Message)"
    }
} else { Step-Skip "Plattform-CLI nicht installiert" }

# 14. git push
Step-Start "git push"
$originRemote = ''
if (-not $NoRemote) {
    $originRemote = (& git -C $TargetDir remote get-url origin 2>$null | Out-String).Trim()
}
if ($NoRemote) { Step-Skip "-NoRemote" }
elseif (-not $originRemote) { Step-Skip "kein Remote konfiguriert" }
else {
    git -C $TargetDir push -u origin HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Step-Done } else { Step-Warn "git push fehlgeschlagen" }
}

# 14b. GitHub Actions Berechtigungen
Step-Start "GitHub Actions Berechtigungen setzen"
if ($NoReleasePlease -or $NoRemote -or $Platform -ne 'github') { Step-Skip "nicht anwendbar" }
elseif (-not $summaryRepoUrl) { Step-Skip "kein Remote konfiguriert" }
elseif (Get-Command gh -ErrorAction SilentlyContinue) {
    $rpRepo = $summaryRepoUrl -replace '^https://github\.com/', ''
    & gh api --method PUT "repos/$rpRepo/actions/permissions/workflow" `
        -f default_workflow_permissions=write `
        -F can_approve_pull_request_reviews=true 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Step-Done "PR-Erstellung fuer GitHub Actions erlaubt" }
    else { Step-Warn "Berechtigungen nicht gesetzt — bitte manuell in Repo-Settings > Actions > General aktivieren" }
} else { Step-Skip "gh nicht installiert" }

# 15. Claude init
Step-Start "Claude init"
if ($NoAgents) { Step-Skip "-NoAgents" }
elseif ((Get-Content (Join-Path $TargetDir 'CLAUDE.md') -ErrorAction SilentlyContinue) -match 'claude-init-done') { Step-Skip "bereits initialisiert" }
elseif (Get-Command claude -ErrorAction SilentlyContinue) {
    Push-Location $TargetDir
    '/init' | claude 2>$null | Out-Null
    Pop-Location
    Add-Content (Join-Path $TargetDir 'CLAUDE.md') '<!-- claude-init-done -->'
    Step-Done
} else { Step-Warn "claude nicht installiert" }

# 16. Codex
Step-Start "Codex (interaktiv)"
Write-Host ""
Write-Host ("          -> Bitte manuell ausfuehren: cd $tdShort && codex")

# 17. Antigravity
Step-Start "Antigravity (interaktiv)"
Write-Host ""
Write-Host ("          -> Bitte manuell ausfuehren: cd $tdShort && agy")

# 18. Copilot check
Step-Start "Copilot verfuegbar pruefen"
if (Get-Command copilot -ErrorAction SilentlyContinue) {
    & copilot --version *> $null
    if ($LASTEXITCODE -eq 0) { Step-Done 'copilot verfuegbar' }
    else { Step-Skip 'copilot nicht nutzbar; Required-Host-Wartung ausfuehren' }
} else { Step-Skip 'copilot nicht installiert; Required-Host-Wartung ausfuehren' }

# 19. Spec-kit
Step-Start "Spec-kit installieren"
if ($NoSpeckit) { Step-Skip "-NoSpeckit" }
elseif ((Test-Path (Join-Path $TargetDir '.specify')) -and -not $Force) { Step-Skip ".specify/ vorhanden" }
elseif (Get-Command specify -ErrorAction SilentlyContinue) {
    Push-Location $TargetDir
    foreach ($agent in $SpecifyAgents) {
        specify init --here --force --integration $agent 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Step-Warn "specify init fehlgeschlagen fuer $agent"
        }
    }
    Pop-Location
    if (Test-Path (Join-Path $TargetDir '.specify')) { Step-Done } else { Step-Warn "specify init kein .specify/ erstellt" }
} else {
    Step-Warn "specify nicht installiert"
    Write-Host "          -> uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
    Write-Host "          -> Dann je Agent: cd $tdShort && specify init --here --force --integration {agy|opencode|claude|copilot|codex}"
}

$projectConstitution = Join-Path $TargetDir 'constitution.md'
$specifyMemoryDir = Join-Path (Join-Path $TargetDir '.specify') 'memory'
if ((Test-Path $projectConstitution) -and (Test-Path $specifyMemoryDir)) {
    Copy-Item -Path $projectConstitution -Destination (Join-Path $specifyMemoryDir 'constitution.md') -Force
}

# 20. Governance-Presets
Step-Start "Governance-Presets installieren"
if ($NoSpeckit) {
    Step-Skip "-NoSpeckit"
} elseif ($ResolvedPresetProfile.Name -eq 'none') {
    Step-Skip "Preset-Profil none"
} elseif (-not (Test-Path (Join-Path $TargetDir '.specify'))) {
    Step-Skip "Spec Kit nicht initialisiert"
} else {
    $presetInstaller = Join-Path $ScriptDir 'install-spec-kit-governance-presets.ps1'
    if (-not (Test-Path $presetInstaller)) {
        Step-Warn "Preset-Installer nicht gefunden"
    } else {
        $presetArgs = @('-Repo', $TargetDir, '-PresetConfig', $ResolvedPresetProfile.ConfigPath)
        if ($Force) { $presetArgs += '-Force' }
        & $presetInstaller @presetArgs
        if ($LASTEXITCODE -eq 0) { Step-Done $ResolvedPresetProfile.Name }
        else { Step-Warn "Governance-Preset-Installation fehlgeschlagen" }
    }
}

# 20b. GSDB-Registry aktualisieren
Step-Start "GSDB-Registry aktualisieren"
$registryHelper = Join-Path $ScriptDir 'register-level2-repository.ps1'
if (-not (Test-Path $registryHelper)) {
    Step-Warn "Registry-Helper nicht gefunden"
} else {
    $registryArgs = @('-Repo', $TargetDir, '-Level', '2', '-Source', 'bootstrap-project')
    if ($PrimaryLanguage) { $registryArgs += @('-PrimaryLanguage', $PrimaryLanguage) }
    $registryArgs += @('-PresetProfile', $ResolvedPresetProfile.Name)
    try {
        & $registryHelper @registryArgs | Out-Null
        Step-Done "Level-2-Repo registriert"
    } catch {
        Step-Warn "GSDB-Registry konnte nicht aktualisiert werden: $($_.Exception.Message)"
    }
}

# 21. Compliance check + STATS baseline
Step-Start "Compliance-Check + STATS-Baseline"
$initStatsScript = Join-Path $ScriptDir 'init-stats.ps1'
$checkScript = Join-Path $ScriptDir 'check-homogeneity.sh'
if (Test-Path $initStatsScript) {
    & $initStatsScript $TargetDir 2>$null | Out-Null
    Step-Done "STATS.md Baseline geschrieben"
} elseif (Test-Path $checkScript) {
    $score = (bash $checkScript --dry-run $TargetDir 2>$null | Select-String 'Overall:').Line -replace '.*(\d+) %.*','$1'
    Step-Done "Score: $score %"
} else { Step-Skip "check-homogeneity.sh nicht gefunden" }

# 21. Update ~/README.md
Step-Start "~/README.md aktualisieren"
$homeReadme = Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) 'README.md'
if ((Get-Content $homeReadme -ErrorAction SilentlyContinue) -match $ProjectName) { Step-Skip "Eintrag vorhanden" }
elseif ((Test-Path $homeReadme) -and (Select-String -Path $homeReadme -Pattern '<!-- workspace-table-end -->')) {
    $content = Get-Content $homeReadme -Raw
    $repoCell = if ($summaryRepoUrl -and $summaryDisplayRepo) { "[$summaryDisplayRepo]($summaryRepoUrl)" } else { '—' }
    $row = "| ``$tdShort/`` | $repoCell | ``bootstrap-project`` |`n"
    $content = $content -replace '<!-- workspace-table-end -->', "${row}<!-- workspace-table-end -->"
    $content | Set-Content $homeReadme -Encoding UTF8
    Step-Done
} else { Step-Skip "README.md oder Marker nicht gefunden" }

# ─── Footer ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ('=' * 50)
if ($PartialFail) { Write-Host "  Bootstrap teilweise abgeschlossen (Warnungen vorhanden)" }
else { Write-Host "  Bootstrap abgeschlossen ✓" }
if ($Platform -eq 'gitlab' -and $projectSlugChanged) {
    Write-Host "  GitLab-Slug : $projectSlug (normalisiert von: $ProjectName)"
}
if ($summaryRepoUrl) {
    Write-Host "  Repo   : $summaryRepoUrl"
    Write-Host "  Clone  : git clone $summaryRepoUrl.git $TargetDir"
}
Write-Host "  $tdShort/ ist bereit."
Write-Host ""
Write-Host "  Naechste Schritte:"
Write-Host "  -> cd $tdShort"
Write-Host "  -> codex   (interaktive Initialisierung)"
Write-Host "  -> agy     (interaktive Initialisierung)"
Write-Host "  -> Spec-Kit ist fuer agy, opencode, claude, copilot und codex vorbereitet"
Write-Host "  -> specify specify `"Feature-Name`""
Write-Host ('=' * 50)

if ($PartialFail) { exit 1 }
exit 0
