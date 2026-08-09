#Requires -Version 7
# sync-home.ps1 — Synchronisiert die dauerhafte Level-0-Quelle nach ~/
# Verwendung: pwsh ~/scripts/sync-home.ps1 [-NoPull] [-NoCommit] [-CheckOnly] [-RuntimeOnly] [-Force] [-WhatIf]

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$NoPull,
    [switch]$NoCommit,
    [switch]$CheckOnly,
    [switch]$RuntimeOnly,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($CheckOnly -and $WhatIfPreference) {
    [Console]::Error.WriteLine('CheckOnly und WhatIf sind nicht kombinierbar / cannot be combined.')
    exit 2
}
if ($RuntimeOnly -and $Force) {
    [Console]::Error.WriteLine('RuntimeOnly und Force sind nicht kombinierbar / cannot be combined.')
    exit 2
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir   = Split-Path -Parent $ScriptDir   # ein Verzeichnis über scripts/
$HomeDir   = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }

# A copied Home script resolves the permanent source through the shared contract.
if ($RepoDir -eq $HomeDir) {
    . (Join-Path $ScriptDir 'lib/resolve-home-baseline-source.ps1')
    $RepoDir = Resolve-HBSourceRepository -StartPath $MyInvocation.MyCommand.Path -AllowLegacy
}

$homeScriptsDir = Join-Path $HomeDir 'scripts'
$repoScript = Join-Path $RepoDir 'scripts/sync-home.ps1'
if ((Test-Path $homeScriptsDir) -and (Test-Path $repoScript) -and
    ((Resolve-Path -LiteralPath $ScriptDir).Path -eq (Resolve-Path -LiteralPath $homeScriptsDir).Path)) {
    $forwardArgs = @()
    if ($NoPull) { $forwardArgs += '-NoPull' }
    if ($NoCommit) { $forwardArgs += '-NoCommit' }
    if ($CheckOnly) { $forwardArgs += '-CheckOnly' }
    if ($RuntimeOnly) { $forwardArgs += '-RuntimeOnly' }
    if ($Force) { $forwardArgs += '-Force' }
    if ($WhatIfPreference) { $forwardArgs += '-WhatIf' }
    & $repoScript @forwardArgs
    exit $LASTEXITCODE
}

$DoPull   = -not $NoPull
$DoCommit = -not $NoCommit
if ($WhatIfPreference) { $DoPull = $false; $DoCommit = $false }
if ($CheckOnly) { $DoPull = $false; $DoCommit = $false }
if ($RuntimeOnly) { $DoPull = $false; $DoCommit = $false }

Write-Host "╔══════════════════════════════════════════════════╗"
Write-Host "║  sync-home — Home-Baseline Sync                  ║"
Write-Host "╚══════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "  Quelle : $RepoDir"
Write-Host "  Ziel   : $HomeDir"
Write-Host "  Pull   : $DoPull"
Write-Host "  Commit : $DoCommit"
if ($WhatIfPreference) { Write-Host "  WhatIf : true (kein Schreiben)" }
Write-Host "  Check  : $CheckOnly"
Write-Host "  Force  : $Force"
Write-Host "  Runtime: $RuntimeOnly"
Write-Host ""

$isAbsddContainer = $HomeDir -eq '/home/adedev' -and
    ((Test-Path -LiteralPath '/.dockerenv') -or (Test-Path -LiteralPath '/run/.containerenv'))
if ($isAbsddContainer -and -not $WhatIfPreference -and -not $CheckOnly -and -not $RuntimeOnly) {
    [Console]::Error.WriteLine(@'
Schreibende sync-home-Laeufe sind in der ABS-DD-Sandbox gesperrt.
Writing sync-home runs are blocked inside the ABS-DD sandbox.
Die Level-0-Referenz direkt unter ~/home-baseline-source verwenden und den Home-Sync auf dem Host ausfuehren.
'@)
    exit 2
}

$hardeningModule = Join-Path $RepoDir 'scripts/lib/windows-maintenance-hardening.psm1'
if (-not (Test-Path -LiteralPath $hardeningModule -PathType Leaf)) {
    [Console]::Error.WriteLine("Windows-Wartungsmodul fehlt / Windows maintenance module missing: ${hardeningModule}")
    exit 2
}
Import-Module $hardeningModule -Force
try {
    $pythonLauncher = Resolve-HBPythonLauncher
    Write-Host "  Python : $($pythonLauncher.Display) (major $($pythonLauncher.MajorVersion))"
} catch {
    [Console]::Error.WriteLine('Kein validierter Python-3-Launcher fuer den manifestgesteuerten Home-Sync / no validated Python 3 launcher.')
    exit 2
}

$syncHelper = Join-Path $RepoDir 'scripts/lib/home-sync-files.py'
$syncManifest = Join-Path $RepoDir 'scripts/config/home-sync-manifest.json'
$syncState = Join-Path $HomeDir '.home-baseline/home-sync-state.json'
$syncResult = Join-Path $HomeDir '.home-baseline/home-sync-result.json'
if (-not (Test-Path -LiteralPath $syncHelper -PathType Leaf)) {
    [Console]::Error.WriteLine("Home-Sync-Helfer fehlt: $syncHelper")
    exit 2
}
if (-not (Test-Path -LiteralPath $syncManifest -PathType Leaf)) {
    [Console]::Error.WriteLine("Home-Sync-Manifest fehlt: $syncManifest")
    exit 2
}

# ── 1. git pull ──────────────────────────────────────────────────────────────
if ($DoPull) {
    Write-Host "→ git pull in $RepoDir..."
    git -C $RepoDir pull --ff-only
    Write-Host ""
}

function Ensure-GitconfigBaseline {
    if ($WhatIfPreference) {
        Write-Host "  [WhatIf] ~/.gitconfig Baseline-Einstellungen prüfen / check baseline settings"
        return
    }

    $gitconfigPath = Join-Path $HomeDir '.gitconfig'
    if (-not (Test-Path $gitconfigPath)) { New-Item -ItemType File -Path $gitconfigPath -Force | Out-Null }

    $oldWarning = 'WICHTIG / IMPORTANT: Name und E-Mail MÜSSEN geändert werden!'
    $content = Get-Content -Raw -Path $gitconfigPath -ErrorAction SilentlyContinue
    if ($content -match [regex]::Escape($oldWarning)) {
        $lines = Get-Content -Path $gitconfigPath
        $remaining = [System.Collections.Generic.List[string]]::new()
        $skip = $false
        $done = $false
        foreach ($line in $lines) {
            if (-not $done -and $line -eq '; ============================================================') {
                $skip = $true
                continue
            }
            if ($skip -and $line -eq '; ============================================================') {
                $skip = $false
                $done = $true
                continue
            }
            if (-not $skip) { $remaining.Add($line) }
        }

        $header = @(
            '; ============================================================',
            '; Lokale Git-Konfiguration / Local git configuration',
            ';',
            '; user.name und user.email werden lokal durch setup-git-identity.*',
            '; gepflegt. sync-home.* überschreibt diese Identität nicht.',
            ';',
            '; user.name and user.email are maintained locally by',
            '; setup-git-identity.*. sync-home.* does not overwrite them.',
            '; ============================================================'
        )
        @($header + $remaining) | Set-Content -Path $gitconfigPath -Encoding UTF8
    }

    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    git config --global pull.rebase true

    $content = Get-Content -Raw -Path $gitconfigPath -ErrorAction SilentlyContinue
    if ($content -notmatch [regex]::Escape('gitdir:~/home-baseline-source/')) {
        Add-Content -Path $gitconfigPath -Value "`n[includeIf `"gitdir:~/home-baseline-source/`"]`n`tpath = ~/.gitconfig.d/home-baseline.inc"
    }

    Write-Host "  ✓ ~/.gitconfig Baseline-Einstellungen geprüft / baseline settings checked"
}

Write-Host "→ Dateien synchronisieren..."

$syncArguments = @(
    $syncHelper,
    'sync',
    '--repo', $RepoDir,
    '--home', $HomeDir,
    '--manifest', $syncManifest,
    '--state', $syncState,
    '--result', $syncResult
)
if ($WhatIfPreference) { $syncArguments += '--dry-run' }
if ($CheckOnly) { $syncArguments += '--check-only' }
if ($Force) { $syncArguments += '--force' }
$pythonArguments = @($pythonLauncher.PrefixArguments) + @($syncArguments)
& $pythonLauncher.FilePath @pythonArguments
$syncStatus = $LASTEXITCODE
if ($CheckOnly) { exit $syncStatus }
if ($syncStatus -ne 0) { exit $syncStatus }
if ($RuntimeOnly) {
    Write-Host ""
    Write-Host "✓ Home Runtime synchronisiert / Home Runtime synchronized."
    exit 0
}

Write-Host ""

# ── 3. ~/.gitconfig.d/ Bootstrap ─────────────────────────────────────────────
$gitconfigD = Join-Path $HomeDir '.gitconfig.d'
$placeholder = Join-Path $gitconfigD 'home-baseline.inc'
if ($WhatIfPreference) {
    if (Test-Path $gitconfigD) {
        Write-Host "  [WhatIf] ~/.gitconfig.d/ bereits vorhanden — Inhalt wird nicht überschrieben / already exists — content preserved"
    } else {
        Write-Host "  [WhatIf] ~/.gitconfig.d/ würde erstellt mit home-baseline.inc / would be created with home-baseline.inc"
    }
} elseif (Test-Path $gitconfigD) {
    Write-Host "  → ~/.gitconfig.d/ bereits vorhanden — Inhalt wird nicht überschrieben / already exists — content preserved"
} else {
    New-Item -ItemType Directory -Path $gitconfigD -Force | Out-Null
    @(
        '# home-baseline workspace git configuration',
        '# Hier workspace-spezifische git-Einstellungen eintragen:',
        '# [user]',
        '#   email = work@example.com'
    ) | Set-Content -Path $placeholder -Encoding UTF8
    Write-Host "  ✓ ~/.gitconfig.d/ erstellt mit home-baseline.inc / created with home-baseline.inc"
}

Ensure-GitconfigBaseline

Write-Host ""

# ── 4. Globale Git-Identität reparieren ──────────────────────────────────────
$identityScript = Join-Path $HomeDir 'scripts\setup-git-identity.ps1'
if ($WhatIfPreference) {
    Write-Host "  [WhatIf] pwsh -NoProfile ~/scripts/setup-git-identity.ps1 -Auto"
} elseif (Test-Path $identityScript) {
    Write-Host "→ Git-Identität in ~/.gitconfig prüfen und reparieren..."
    pwsh -NoProfile -File $identityScript -Auto
    Write-Host ""
} else {
    Write-Warning "~/scripts/setup-git-identity.ps1 nicht gefunden — Git-Identität nicht geprüft."
    Write-Warning "~/scripts/setup-git-identity.ps1 not found — git identity not checked."
    Write-Host ""
}

# ── 5. git commit in ~/ ──────────────────────────────────────────────────────
if ($DoCommit) {
    Push-Location $HomeDir
    try {
        # Falls ~/ noch kein Git-Repo ist, automatisch initialisieren
        git rev-parse --git-dir 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "→ ~/ ist noch kein Git-Repository — initialisiere..."
            git init
            $hookScript = Join-Path $HomeDir 'scripts\install-hooks.ps1'
            if (Test-Path $hookScript) { pwsh $hookScript }
            Write-Host "  ✓ Git-Repository und Hooks initialisiert."
            Write-Host ""
        }
        $result = Get-Content -Raw -LiteralPath $syncResult | ConvertFrom-Json
        $changedPaths = [System.Collections.Generic.List[string]]::new()
        foreach ($path in $result.changedPaths) { $changedPaths.Add([string]$path) }
        if (git status --porcelain -- .gitconfig) { $changedPaths.Add('.gitconfig') }
        $commitPaths = [System.Collections.Generic.List[string]]::new()
        foreach ($path in ($changedPaths | Sort-Object -Unique)) {
            $target = Join-Path $HomeDir $path
            git ls-files --error-unmatch -- $path 2>$null | Out-Null
            $isTracked = $LASTEXITCODE -eq 0
            if ((Test-Path -LiteralPath $target) -or $isTracked) {
                git add -A -- $path
                git diff --cached --quiet -- $path
                if ($LASTEXITCODE -eq 1) {
                    $commitPaths.Add($path)
                } elseif ($LASTEXITCODE -gt 1) {
                    throw "git diff fuer verwalteten Pfad fehlgeschlagen / failed: ${path}"
                }
            }
        }
        if ($commitPaths.Count -eq 0) {
            Write-Host "→ Keine verwalteten Änderungen in ~/ — kein Commit nötig."
        } else {
            $remoteSha = (git -C $RepoDir rev-parse --short HEAD 2>$null) ?? 'unbekannt'
            $message = "chore: sync mit home-baseline @ ${remoteSha}`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
            git commit --only -m $message -- @commitPaths
            Write-Host "→ Commit in ~/ erstellt."
        }
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "✓ sync-home abgeschlossen."
