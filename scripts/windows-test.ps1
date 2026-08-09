#Requires -Version 7
# windows-test.ps1 — Sammelt System-Info und Testergebnisse auf Windows
# Ausgabe wird nach ~/home-baseline-source/windows-test-output.txt geschrieben
# und automatisch committet + gepusht.
#
# Verwendung: pwsh ~/home-baseline-source/scripts/windows-test.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$HomeDir   = $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE })
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'lib/resolve-home-baseline-source.ps1')
$RepoDir   = Resolve-HBSourceRepository -StartPath $MyInvocation.MyCommand.Path -AllowLegacy
$OutFile   = Join-Path $RepoDir 'windows-test-output.txt'
$Date      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$Lines     = [System.Collections.Generic.List[string]]::new()

function Add-Line { param([string]$Text = '') $Lines.Add($Text); Write-Host $Text }

Add-Line "Windows Test Output - ${Date}"
Add-Line ""

# === System-Info ===
Add-Line "=== System-Info ==="
$os = Get-CimInstance Win32_OperatingSystem
Add-Line "OS:        $($os.Caption) $($os.Version)"
Add-Line "Arch:      $($env:PROCESSOR_ARCHITECTURE)"
Add-Line "Shell:     PowerShell $($PSVersionTable.PSVersion)"
Add-Line "Edition:   $($PSVersionTable.PSEdition)"
Add-Line ""

# === Paketmanager ===
Add-Line "=== Paketmanager ==="
foreach ($pm in @('winget', 'choco', 'scoop')) {
    if (Get-Command $pm -ErrorAction SilentlyContinue) {
        $ver = (& $pm --version 2>$null | Select-Object -First 1) -replace '\s+', ' '
        Add-Line "  OK  ${pm}: ${ver}"
    } else {
        Add-Line "  --- ${pm}: nicht installiert"
    }
}
Add-Line ""

# === WinGet Inventar ===
Add-Line "=== WinGet Pakete ==="
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wingetList = winget list --accept-source-agreements 2>&1
    $wingetList | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line "winget: nicht installiert"
}
Add-Line ""

Add-Line "=== WinGet Upgrades ==="
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wingetUpgrade = winget upgrade --accept-source-agreements 2>&1
    $wingetUpgrade | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line "winget: nicht installiert"
}
Add-Line ""

Add-Line "=== Agentic WinGet Registry Vergleich ==="
$wingetMaint = Join-Path $RepoDir 'scripts\maintain-agentic-winget-apps.ps1'
if (Test-Path $wingetMaint) {
    $wingetCompare = pwsh -NoProfile -File $wingetMaint -CompareOnly 2>&1
    $wingetCompare | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line "maintain-agentic-winget-apps.ps1: nicht gefunden"
}
Add-Line ""

Add-Line "=== PSScriptAnalyzer ==="
$moduleMaintainer = Join-Path $RepoDir 'scripts\maintain-powershell-modules.ps1'
$analyzerRunner = Join-Path $RepoDir 'scripts\invoke-psscriptanalyzer.ps1'
if ((Test-Path $moduleMaintainer) -and (Test-Path $analyzerRunner)) {
    $moduleComparison = pwsh -NoProfile -File $moduleMaintainer -CompareOnly 2>&1
    $moduleComparison | ForEach-Object { Add-Line "$_" }
    $analysisOutput = pwsh -NoProfile -File $analyzerRunner 2>&1
    $analysisOutput | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line 'PowerShell-Modulpflege oder PSScriptAnalyzer-Runner fehlt'
}
Add-Line ""

Add-Line "=== Workspace Maintenance Check ==="
$workspaceMaint = Join-Path $RepoDir 'scripts\maintain-agentic-workspace.ps1'
if (Test-Path $workspaceMaint) {
    $workspaceCheck = pwsh -NoProfile -File $workspaceMaint -CheckOnly -ScriptsOnly 2>&1
    $workspaceCheck | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line "maintain-agentic-workspace.ps1: nicht gefunden"
}
Add-Line ""

# === VS Code / Helix ===
Add-Line "=== VS Code / Helix ==="
if (Get-Command code -ErrorAction SilentlyContinue) {
    $codeVersion = code --version 2>&1
    $codeVersion | ForEach-Object { Add-Line "$_" }
    $codeExtensions = code --list-extensions 2>&1
    $codeExtensions | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line 'code: nicht installiert'
}
if (Get-Command hx -ErrorAction SilentlyContinue) {
    $hxVersion = hx --version 2>&1
    $hxVersion | ForEach-Object { Add-Line "$_" }
} else {
    Add-Line 'hx: nicht installiert'
}
Add-Line ""

# === Tools ===
Add-Line "=== Tools ==="
foreach ($cmd in @('git', 'gh', 'glab', 'rg', 'gitleaks', 'pwsh', 'node', 'npm', 'uv', 'python', 'dotnet', 'go', 'java', 'javac', 'cargo', 'rustc', 'swift', 'syft', 'specify', 'podman', 'codex', 'claude', 'agy', 'copilot', 'code', 'hx')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Add-Line "  OK  ${cmd}"
    } else {
        Add-Line "  --- ${cmd}: fehlt"
    }
}
Add-Line ""

# === WSL ===
Add-Line "=== WSL ==="
try {
    $wslList = wsl --list --verbose 2>&1
    $wslList | ForEach-Object { Add-Line "  $_" }
} catch {
    Add-Line "  WSL nicht verfuegbar oder kein Distro installiert"
}
Add-Line ""

# === sync-home ===
Add-Line "=== sync-home ==="
$syncScript = Join-Path $RepoDir 'scripts\sync-home.ps1'
$syncOutput = pwsh -NoProfile -File $syncScript -NoPull 2>&1
$syncOutput | ForEach-Object { Add-Line "$_" }
Add-Line ""

# === check-homogeneity ===
Add-Line "=== check-homogeneity ==="
$checkScript = Join-Path $HomeDir 'scripts\check-homogeneity.ps1'
$checkOutput = pwsh -NoProfile -File $checkScript -TargetDir $HomeDir 2>&1
$checkOutput | ForEach-Object { Add-Line "$_" }

# Datei schreiben
$Lines | Set-Content -Path $OutFile -Encoding UTF8

# Committen und pushen
Set-Location $RepoDir
git pull --rebase --autostash origin main 2>&1 | ForEach-Object { Write-Host $_ }
git add windows-test-output.txt
git commit -m "test: Windows Test-Output (${Date})" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin HEAD:main
Add-Line "Gepusht."
