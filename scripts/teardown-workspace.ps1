#Requires -Version 7
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string] $WorkspaceName,

    [switch] $Backup,
    [switch] $KeepRemote,
    [switch] $Recursive,
    [switch] $Force,
    [switch] $Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$forgejoLib = Join-Path $PSScriptRoot 'lib/hg-forgejo.ps1'
if (Test-Path $forgejoLib) {
    . $forgejoLib
}

$script:ExitCode = 0
$script:Results = [System.Collections.Generic.List[object]]::new()
$script:Level2Projects = [System.Collections.Generic.List[string]]::new()
$script:DryRun = [bool]$WhatIfPreference
$script:HomeDir = ''
$script:WorkspaceDir = ''
$script:NormalizedName = ''
$script:ReadmePath = ''
$script:GitignorePath = ''
$script:GitconfigPath = ''
$script:GitconfigD = ''
$script:IncFile = ''

function Show-Usage {
    @'
Verwendung / Usage:
  teardown-workspace.ps1 -WorkspaceName <Name> [OPTIONEN / OPTIONS]

Optionen / Options:
  -Backup         Erstellt vor der Löschung ein Backup-Archiv / Create backup archive before deletion
  -KeepRemote     Überspringt das Remote-Repository / Skip remote repository deletion
  -Recursive      Verarbeitet Level-2-Repositories vor dem Workspace / Process Level-2 repositories first
  -Force          Überspringt Sicherheitsprüfungen / Skip safety checks
  -Yes            Überspringt die Rückfrage / Skip confirmation prompt
  -WhatIf         Zeigt alle Aktionen ohne Ausführung / Show all actions without executing
'@
}

function Set-WarningExit {
    if ($script:ExitCode -lt 1) {
        $script:ExitCode = 1
    }
}

function Add-Result([string]$Status, [string]$Message) {
    $script:Results.Add([pscustomobject]@{
        Status  = $Status
        Message = $Message
    })
}

function Set-FileLines([string]$Path, [string[]]$Lines) {
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $encoding)
}

function Show-Box {
    param(
        [string] $Title,
        [string[]] $Lines
    )

    Write-Host '╔════════════════════════════════════════════════════════════════════╗'
    Write-Host ("║ {0,-66} ║" -f "  $Title")
    Write-Host '╠════════════════════════════════════════════════════════════════════╣'
    foreach ($line in $Lines) {
        $text = if ($line.Length -gt 66) { $line.Substring(0, 66) } else { $line }
        Write-Host ("║ {0,-66} ║" -f $text)
    }
    Write-Host '╚════════════════════════════════════════════════════════════════════╝'
}

function ConvertTo-NormalizedName([string]$Name) {
    $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
}

function Resolve-HomeDirectory {
    $candidate = if ($env:HOME) { $env:HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { '~' }
    (Resolve-Path -LiteralPath $candidate).Path
}

function Initialize-Context {
    $script:HomeDir = Resolve-HomeDirectory
    $script:WorkspaceDir = Join-Path $script:HomeDir $WorkspaceName
    $script:NormalizedName = ConvertTo-NormalizedName $WorkspaceName
    $script:ReadmePath = Join-Path $script:HomeDir 'README.md'
    $script:GitignorePath = Join-Path $script:HomeDir '.gitignore'
    $script:GitconfigPath = Join-Path $script:HomeDir '.gitconfig'
    $script:GitconfigD = Join-Path $script:HomeDir '.gitconfig.d'
    $script:IncFile = Join-Path $script:GitconfigD "$($script:NormalizedName).inc"

    if ($WorkspaceName -eq 'home-baseline') {
        throw "Fehler: 'home-baseline' ist geschützt / Error: 'home-baseline' is protected"
    }

    if (-not (Test-Path -LiteralPath $script:WorkspaceDir -PathType Container)) {
        throw "Fehler: Workspace '$script:WorkspaceDir' nicht gefunden / Error: Workspace '$script:WorkspaceDir' not found"
    }
}

function Get-Level2Projects {
    $script:Level2Projects.Clear()
    $children = Get-ChildItem -LiteralPath $script:WorkspaceDir -Directory -ErrorAction SilentlyContinue
    foreach ($child in $children) {
        if (Test-Path -LiteralPath (Join-Path $child.FullName '.git') -PathType Container) {
            $script:Level2Projects.Add($child.FullName)
        }
    }
}

function Get-RemotePlatform([string]$Dir) {
    if (-not (Test-Path -LiteralPath (Join-Path $Dir '.git') -PathType Container)) {
        return 'kein Remote / no remote'
    }

    $remoteUrl = (& git -C $Dir remote get-url origin 2>$null)
    if (-not $remoteUrl) {
        return 'kein Remote / no remote'
    }

    $configuredPlatform = ((& git -C $Dir config --local --get home-baseline.remote-platform 2>$null) | Out-String).Trim()
    if ($configuredPlatform -in @('forgejo', 'codeberg')) {
        return $configuredPlatform
    }

    if ($remoteUrl -match 'github\.com') {
        return 'GitHub'
    }
    if ($remoteUrl -match 'gitlab\.com') {
        return 'GitLab'
    }

    return 'anderes Remote / other remote'
}

function Get-PlannedBackupPath([string]$TargetName) {
    Join-Path $script:HomeDir "$TargetName-backup-$(Get-Date -Format 'yyyy-MM-dd').tar.gz"
}

function Get-UniqueBackupPath([string]$TargetName) {
    $base = Join-Path $script:HomeDir "$TargetName-backup-$(Get-Date -Format 'yyyy-MM-dd')"
    $archivePath = "$base.tar.gz"
    $index = 1

    while (Test-Path -LiteralPath $archivePath) {
        $archivePath = "$base-$index.tar.gz"
        $index++
    }

    $archivePath
}

function Show-Preamble {
    $title = 'teardown-workspace - Workspace-Entfernung / Workspace Removal'
    if ($script:DryRun) {
        $title = "[DRY-RUN] $title"
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("  Workspace:   $WorkspaceName")
    $lines.Add("  Pfad / Path: $script:WorkspaceDir")
    $lines.Add('')
    $lines.Add('  Geplante Aktionen / Planned actions:')

    foreach ($project in $script:Level2Projects) {
        $projectName = Split-Path $project -Leaf
        if ($Force) {
            $lines.Add("    L2 ${projectName}: --force überspringt Safety / --force skips safety")
        } else {
            $lines.Add("    L2 ${projectName}: Sicherheitsprüfung / Safety")
        }
        if ($Backup) {
            $lines.Add("      Backup / backup: $(Split-Path (Get-PlannedBackupPath $projectName) -Leaf)")
        }
        $lines.Add("      Remote / remote: $(Get-RemotePlatform $project)")
        $lines.Add('      Lokal löschen / delete local directory')
    }

    if ($Backup) {
        $lines.Add("    1. Backup / backup: $(Split-Path (Get-PlannedBackupPath $WorkspaceName) -Leaf)")
    }

    if ($Force) {
        $lines.Add('    2. --force: Sicherheitsprüfungen übersprungen / safety checks skipped')
    } else {
        $lines.Add('    2. Sicherheitsprüfung / safety check')
    }

    $lines.Add("    3. Remote / remote: $(Get-RemotePlatform $script:WorkspaceDir)")
    $lines.Add('    4. Verzeichnis löschen / delete directory')
    $lines.Add('    5. Artefakte bereinigen / clean up artifacts')
    $lines.Add('       - ~/README.md')
    $lines.Add('       - ~/.gitignore')
    $lines.Add('       - ~/.gitconfig')
    $lines.Add("       - ~/.gitconfig.d/$($script:NormalizedName).inc")

    Show-Box -Title $title -Lines $lines
}

function Confirm-OrAbort {
    if ($script:DryRun -or $Yes) {
        return
    }

    $answer = Read-Host 'Fortfahren? / Proceed? [y/N]'
    if ($answer -notmatch '^(?i:y)$') {
        throw 'Abgebrochen / Aborted.'
    }
}

function Test-Safety([string]$Label, [string]$Dir) {
    if ($Force) {
        Add-Result 'skip' "Sicherheitsprüfung übersprungen / Safety check skipped: $Label"
        return $true
    }

    if (-not (Test-Path -LiteralPath (Join-Path $Dir '.git') -PathType Container)) {
        Add-Result 'skip' "Kein Git-Repository für Sicherheitsprüfung / No git repository for safety check: $Label"
        return $true
    }

    $statusOutput = (& git -C $Dir status --porcelain 2>$null)
    if ($statusOutput) {
        Add-Result 'fail' "Uncommittete Änderungen erkannt / Uncommitted changes detected: $Label"
        Set-WarningExit
        return $false
    }

    & git -C $Dir rev-parse '@{u}' *> $null
    if ($LASTEXITCODE -eq 0) {
        $unpushed = (& git -C $Dir log '@{u}..HEAD' --oneline 2>$null)
        if ($unpushed) {
            Add-Result 'fail' "Ungepushte Commits erkannt / Unpushed commits detected: $Label"
            Set-WarningExit
            return $false
        }
    }

    Add-Result 'done' "Sicherheitsprüfung bestanden / Safety check passed: $Label"
    $true
}

function Get-OwnerRepo([string]$RemoteUrl, [string]$HostPattern) {
    $RemoteUrl -replace ".*$HostPattern[:/](.*?)(\.git)?$", '$1'
}

function Invoke-Backup([string]$Label, [string]$Dir, [string]$TargetName) {
    if (-not $Backup) {
        return
    }

    if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
        Add-Result 'fail' "Backup nicht erstellt, tar fehlt / Backup not created, tar missing: $Label"
        Set-WarningExit
        return
    }

    $archivePath = Get-UniqueBackupPath $TargetName
    & tar czf $archivePath -C (Split-Path $Dir -Parent) (Split-Path $Dir -Leaf) *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Result 'done' "Backup erstellt / Backup created: $(Split-Path $archivePath -Leaf)"
    } else {
        Add-Result 'fail' "Backup fehlgeschlagen / Backup failed: $Label"
        Set-WarningExit
    }
}

function Remove-RemoteRepo([string]$Label, [string]$Dir) {
    if ($KeepRemote) {
        Add-Result 'skip' "Remote bewusst behalten / Remote intentionally kept: $Label"
        return $true
    }

    if (-not (Test-Path -LiteralPath (Join-Path $Dir '.git') -PathType Container)) {
        Add-Result 'skip' "Kein Git-Repository, Remote-Schritt übersprungen / No git repository, remote step skipped: $Label"
        return $true
    }

    $remoteUrl = (& git -C $Dir remote get-url origin 2>$null)
    if (-not $remoteUrl) {
        Add-Result 'skip' "Kein Remote konfiguriert / No remote configured: $Label"
        return $true
    }

    $configuredPlatform = ((& git -C $Dir config --local --get home-baseline.remote-platform 2>$null) | Out-String).Trim()
    if ($configuredPlatform -in @('forgejo', 'codeberg')) {
        if (-not (Test-Path $forgejoLib)) {
            Add-Result 'fail' "Forgejo-Bibliothek fehlt, Remote-Löschung abgebrochen / Forgejo library missing, remote deletion aborted: $Label"
            Set-WarningExit
            return $false
        }
        $baseUrl = ((& git -C $Dir config --local --get home-baseline.remote-base-url 2>$null) | Out-String).Trim()
        $owner = ((& git -C $Dir config --local --get home-baseline.remote-owner 2>$null) | Out-String).Trim()
        $repository = ((& git -C $Dir config --local --get home-baseline.remote-repository 2>$null) | Out-String).Trim()
        if (-not $baseUrl -or -not $owner -or -not $repository) {
            Add-Result 'fail' "Forgejo-Metadaten fehlen, bitte -KeepRemote verwenden / Forgejo metadata missing, use -KeepRemote: $Label"
            Set-WarningExit
            return $false
        }
        try {
            Remove-HBForgejoRepository -BaseUrl $baseUrl -Owner $owner -RepositoryName $repository
            Add-Result 'done' "$configuredPlatform-Remote gelöscht / remote deleted: $owner/$repository"
            return $true
        } catch {
            Add-Result 'fail' "$configuredPlatform-Remote konnte nicht gelöscht werden / remote could not be deleted: $owner/$repository"
            Set-WarningExit
            return $false
        }
    }

    if ($remoteUrl -match 'github\.com') {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Add-Result 'fail' "gh fehlt, Remote-Löschung abgebrochen / gh missing, remote deletion aborted: $Label"
            Set-WarningExit
            return $false
        }

        $ownerRepo = Get-OwnerRepo $remoteUrl 'github\.com'
        & gh repo delete $ownerRepo --yes *> $null
        if ($LASTEXITCODE -eq 0) {
            Add-Result 'done' "Remote-Repo gelöscht / Remote repo deleted: $ownerRepo"
            return $true
        }

        Add-Result 'fail' "GitHub-Remote konnte nicht gelöscht werden / GitHub remote could not be deleted: $ownerRepo"
        Set-WarningExit
        return $false
    }

    if ($remoteUrl -match 'gitlab\.com') {
        $ownerRepo = Get-OwnerRepo $remoteUrl 'gitlab\.com'
        if (-not (Get-Command glab -ErrorAction SilentlyContinue)) {
            Add-Result 'skip' "glab fehlt, GitLab-Remote übersprungen / glab missing, GitLab remote skipped: $ownerRepo"
            Set-WarningExit
            return $true
        }

        & glab repo delete $ownerRepo --yes *> $null
        if ($LASTEXITCODE -eq 0) {
            Add-Result 'done' "GitLab-Remote gelöscht / GitLab remote deleted: $ownerRepo"
            return $true
        }

        Add-Result 'fail' "GitLab-Remote konnte nicht gelöscht werden / GitLab remote could not be deleted: $ownerRepo"
        Set-WarningExit
        return $false
    }

    Add-Result 'fail' "Nicht unterstütztes Remote, bitte -KeepRemote verwenden / Unsupported remote, use -KeepRemote: $Label"
    Set-WarningExit
    $false
}

function Remove-LocalDirectory([string]$Label, [string]$Dir) {
    Remove-Item -LiteralPath $Dir -Recurse -Force
    Add-Result 'done' "Verzeichnis gelöscht / Directory deleted: $Label"
}

function Update-TextFile {
    param(
        [string] $Path,
        [scriptblock] $Transform,
        [string] $ChangedMessage,
        [string] $MissingMessage
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Result 'skip' $MissingMessage
        return
    }

    $existing = Get-Content -LiteralPath $Path
    $updated = & $Transform $existing
    if ((@($existing) -join "`n") -eq (@($updated) -join "`n")) {
        Add-Result 'skip' $MissingMessage
        return
    }

    Set-FileLines -Path $Path -Lines @($updated)
    Add-Result 'done' $ChangedMessage
}

function Cleanup-Readme {
    Update-TextFile `
        -Path $script:ReadmePath `
        -Transform {
            param($Lines)
            $Lines | Where-Object { $_ -notmatch [regex]::Escape("~/$WorkspaceName/") }
        } `
        -ChangedMessage 'README.md bereinigt / README.md cleaned up' `
        -MissingMessage 'README.md-Eintrag nicht vorhanden / README.md entry not present'
}

function Cleanup-Gitignore {
    Update-TextFile `
        -Path $script:GitignorePath `
        -Transform {
            param($Lines)
            $Lines | Where-Object { $_ -ne "$WorkspaceName/" }
        } `
        -ChangedMessage '.gitignore bereinigt / .gitignore cleaned up' `
        -MissingMessage '.gitignore-Eintrag nicht vorhanden / .gitignore entry not present'
}

function Cleanup-Gitconfig {
    if (-not (Test-Path -LiteralPath $script:GitconfigPath -PathType Leaf)) {
        Add-Result 'skip' '.gitconfig fehlt / .gitconfig missing'
        return
    }

    $header1 = "[includeIf `"gitdir:~/$WorkspaceName/`"]"
    $header2 = "[includeIf `"gitdir:$script:WorkspaceDir/`"]"
    $lines = Get-Content -LiteralPath $script:GitconfigPath
    $updated = [System.Collections.Generic.List[string]]::new()
    $skip = $false

    foreach ($line in $lines) {
        if ($line -eq $header1 -or $line -eq $header2) {
            $skip = $true
            continue
        }
        if ($skip -and $line -match '^\s') {
            continue
        }
        $skip = $false
        $updated.Add($line)
    }

    if ((@($lines) -join "`n") -eq (@($updated) -join "`n")) {
        Add-Result 'skip' '.gitconfig includeIf-Block nicht vorhanden / .gitconfig includeIf block not present'
        return
    }

    Set-FileLines -Path $script:GitconfigPath -Lines @($updated)
    Add-Result 'done' '.gitconfig bereinigt / .gitconfig cleaned up'
}

function Cleanup-IncludeFile {
    if (-not (Test-Path -LiteralPath $script:GitconfigD -PathType Container)) {
        Add-Result 'skip' '~/.gitconfig.d fehlt / ~/.gitconfig.d missing'
        return
    }

    if (-not (Test-Path -LiteralPath $script:IncFile -PathType Leaf)) {
        Add-Result 'skip' ".inc-Datei nicht vorhanden / .inc file not present: $($script:NormalizedName).inc"
        return
    }

    Remove-Item -LiteralPath $script:IncFile -Force
    Add-Result 'done' ".inc-Datei gelöscht / .inc file deleted: $($script:NormalizedName).inc"
}

function Commit-Artifacts {
    $insideWorkTree = (& git -C $script:HomeDir rev-parse --is-inside-work-tree 2>$null | Out-String).Trim()
    if (-not $insideWorkTree) {
        Add-Result 'skip' 'Artefakt-Commit übersprungen, ~/ ist kein Git-Repo / Artifact commit skipped, ~/ is not a git repo'
        Set-WarningExit
        return
    }

    if (Test-Path -LiteralPath $script:ReadmePath -PathType Leaf) {
        & git -C $script:HomeDir add --update -- README.md *> $null
    }
    if (Test-Path -LiteralPath $script:GitignorePath -PathType Leaf) {
        & git -C $script:HomeDir add --update -- .gitignore *> $null
    }

    & git -C $script:HomeDir diff --cached --quiet -- README.md .gitignore *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Result 'skip' 'Kein Artefakt-Commit nötig / No artifact commit needed'
        return
    }

    $subject = "chore: teardown $WorkspaceName - Artefakte bereinigt / artifacts cleaned up"
    & git -C $script:HomeDir commit -m $subject -m 'Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>' *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Result 'done' 'Artefakte committed / Artifacts committed'
    } else {
        Add-Result 'fail' 'Artefakt-Commit fehlgeschlagen / Artifact commit failed'
        Set-WarningExit
    }
}

function Cleanup-WorkspaceArtifacts {
    Cleanup-Readme
    Cleanup-Gitignore
    Cleanup-Gitconfig
    Cleanup-IncludeFile
    Commit-Artifacts
}

function Invoke-TargetTeardown {
    param(
        [string] $Label,
        [string] $Dir,
        [string] $BackupName,
        [switch] $IncludeArtifacts
    )

    Invoke-Backup -Label $Label -Dir $Dir -TargetName $BackupName

    if (-not (Test-Safety -Label $Label -Dir $Dir)) {
        return $false
    }

    if (-not (Remove-RemoteRepo -Label $Label -Dir $Dir)) {
        return $false
    }

    Remove-LocalDirectory -Label $Label -Dir $Dir

    if ($IncludeArtifacts) {
        Cleanup-WorkspaceArtifacts
    }

    $true
}

function Show-Level2Abort {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('Level-2-Repositories erkannt / Level-2 repositories detected:')
    foreach ($project in $script:Level2Projects) {
        $lines.Add("  - $(Split-Path $project -Leaf)")
    }
    $lines.Add('')
    $lines.Add('-Recursive erforderlich / -Recursive required')
    Show-Box -Title 'Teardown abgebrochen / Teardown aborted' -Lines $lines
}

function Show-CompletionReport {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($result in $script:Results) {
        $symbol = switch ($result.Status) {
            'done' { '✓' }
            'skip' { '→' }
            'fail' { '✗' }
            default { '•' }
        }
        $lines.Add("  $symbol $($result.Message)")
    }
    Show-Box -Title 'Teardown abgeschlossen / Teardown complete' -Lines $lines
}

try {
    Initialize-Context
    Get-Level2Projects

    if ($script:Level2Projects.Count -gt 0 -and -not $Recursive) {
        Show-Level2Abort
        exit 1
    }

    Show-Preamble

    if ($script:DryRun) {
        exit 0
    }

    Confirm-OrAbort

    foreach ($project in $script:Level2Projects) {
        $projectName = Split-Path $project -Leaf
        if (-not (Invoke-TargetTeardown -Label "Level-2 $projectName" -Dir $project -BackupName $projectName)) {
            Show-CompletionReport
            exit $script:ExitCode
        }
    }

    if (-not (Invoke-TargetTeardown -Label "Workspace $WorkspaceName" -Dir $script:WorkspaceDir -BackupName $WorkspaceName -IncludeArtifacts)) {
        Show-CompletionReport
        exit $script:ExitCode
    }

    Show-CompletionReport
    exit $script:ExitCode
}
catch {
    $message = $_.Exception.Message
    if ($message -eq 'Abgebrochen / Aborted.') {
        Write-Host $message
        exit 1
    }
    Write-Error $message
    exit 2
}
