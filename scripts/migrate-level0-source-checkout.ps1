#Requires -Version 7
<#
.SYNOPSIS
Migrates the permanent Level 0 checkout to a stable local source path.

.DESCRIPTION
Validates a clean main checkout synchronized with origin/main, moves it to
home-baseline-source, writes local discovery state, updates path-scoped Git and
Codex configuration, and leaves a temporary compatibility link at the legacy
path. Use -Finalize only after all tools have been validated at the new path.

.PARAMETER Source
Existing checkout. Auto-detected when omitted.

.PARAMETER Target
New checkout path. Defaults to ~/home-baseline-source.

.PARAMETER CheckOnly
Runs all non-mutating preflight and discovery checks.

.PARAMETER Finalize
Removes the legacy compatibility link and obsolete Git includeIf block.

.PARAMETER Json
Emits a machine-readable status object without secrets.

.EXAMPLE
pwsh -NoProfile -File scripts/migrate-level0-source-checkout.ps1 -CheckOnly

.EXAMPLE
pwsh -NoProfile -File scripts/migrate-level0-source-checkout.ps1 -WhatIf

.EXAMPLE
pwsh -NoProfile -File scripts/migrate-level0-source-checkout.ps1

.EXAMPLE
pwsh -NoProfile -File scripts/migrate-level0-source-checkout.ps1 -Finalize
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$Source,
    [string]$Target = (Join-Path $HOME 'home-baseline-source'),
    [switch]$CheckOnly,
    [switch]$Finalize,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-HBNative {
    <#
    .SYNOPSIS
    Executes a native process without shell interpolation.
    #>
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )
    $output = & $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "$FilePath failed ($exitCode): $($output -join "`n")"
    }
    [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) }
}

function Get-HBRepositoryFacts {
    <#
    .SYNOPSIS
    Collects the immutable preflight facts for a source checkout.
    #>
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Source checkout not found: $Path"
    }
    $root = (Invoke-HBNative git @('-C', $Path, 'rev-parse', '--show-toplevel')).Output[0]
    $branch = (Invoke-HBNative git @('-C', $root, 'branch', '--show-current')).Output[0]
    $head = (Invoke-HBNative git @('-C', $root, 'rev-parse', 'HEAD')).Output[0]
    $origin = (Invoke-HBNative git @('-C', $root, 'rev-parse', 'origin/main')).Output[0]
    $remote = (Invoke-HBNative git @('-C', $root, 'remote', 'get-url', 'origin')).Output[0]
    $status = @((Invoke-HBNative git @('-C', $root, 'status', '--porcelain=v1')).Output)
    $worktrees = @((Invoke-HBNative git @('-C', $root, 'worktree', 'list', '--porcelain')).Output |
        Where-Object { $_ -like 'worktree *' })
    [pscustomobject]@{
        Root = [IO.Path]::GetFullPath([string]$root)
        Branch = [string]$branch
        Head = [string]$head
        OriginMain = [string]$origin
        Remote = [string]$remote
        DirtyEntries = @($status | Where-Object { $_ })
        WorktreeCount = $worktrees.Count
    }
}

function Set-HBJsonProperty {
    <#
    .SYNOPSIS
    Updates one JSON property while preserving all unrelated properties.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $data = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
    if ($null -eq $data.PSObject.Properties[$Name]) {
        $data | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    } else {
        $data.$Name = $Value
    }
    $text = $data | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($Path, $text + "`n", [Text.UTF8Encoding]::new($false))
}

function Set-HBTextReplacement {
    <#
    .SYNOPSIS
    Replaces a literal local path only when the target file exists.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldValue,
        [Parameter(Mandatory)][string]$NewValue
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($text.Contains($OldValue)) {
        [IO.File]::WriteAllText(
            $Path,
            $text.Replace($OldValue, $NewValue),
            [Text.UTF8Encoding]::new($false)
        )
    }
}

try {
    $legacy = Join-Path $HOME 'home-baseline-tmp'
    $targetPath = [IO.Path]::GetFullPath($Target)
    if ($Finalize) {
        if (-not (Test-Path -LiteralPath (Join-Path $targetPath '.git'))) {
            throw "Validated target checkout not found: $targetPath"
        }
        if (Test-Path -LiteralPath $legacy) {
            $item = Get-Item -LiteralPath $legacy -Force
            if ($null -eq $item.LinkType) {
                throw "Legacy path is not a compatibility link: $legacy"
            }
            if ($PSCmdlet.ShouldProcess($legacy, 'Remove legacy compatibility link')) {
                Remove-Item -LiteralPath $legacy -Force
            }
        }
        $legacyIncludeKey = 'includeIf.gitdir:~/home-baseline-tmp/.path'
        $legacyInclude = Invoke-HBNative git @(
            'config', '--global', '--get-all', $legacyIncludeKey
        ) -AllowFailure
        if ($legacyInclude.ExitCode -notin @(0, 1)) {
            throw 'Could not inspect legacy Git includeIf section.'
        }
        # A missing key is the intended state after finalization. Probe first because
        # current Git versions return exit code 128 when removing an absent section.
        if ($legacyInclude.ExitCode -eq 0 -and
            $PSCmdlet.ShouldProcess('global Git configuration', 'Remove legacy includeIf')) {
            & git config --global --remove-section 'includeIf.gitdir:~/home-baseline-tmp/' 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw 'Could not remove legacy Git includeIf section.'
            }
        }
        $result = [ordered]@{ status = 'FINALIZED'; target = $targetPath }
        if ($Json) { $result | ConvertTo-Json -Compress } else {
            Write-Host "Level-0 source migration finalized: $targetPath"
        }
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($Source)) {
        $resolver = Join-Path $PSScriptRoot 'lib/resolve-home-baseline-source.ps1'
        . $resolver
        $Source = Resolve-HBSourceRepository -StartPath $PSScriptRoot -AllowLegacy
    }
    $facts = Get-HBRepositoryFacts -Path $Source
    $problems = [Collections.Generic.List[string]]::new()
    if ($facts.Branch -ne 'main') { $problems.Add("branch is '$($facts.Branch)', expected main") }
    if ($facts.Head -ne $facts.OriginMain) { $problems.Add('HEAD differs from origin/main') }
    if ($facts.DirtyEntries.Count -gt 0) { $problems.Add('working tree is not clean') }
    if ($facts.WorktreeCount -ne 1) { $problems.Add("worktree count is $($facts.WorktreeCount), expected 1") }
    if ($facts.Remote -notmatch 'hindermath/home-baseline(?:\.git)?$') {
        $problems.Add("unexpected origin remote: $($facts.Remote)")
    }
    if ($facts.Root -ne $targetPath -and (Test-Path -LiteralPath $targetPath)) {
        $problems.Add("target already exists: $targetPath")
    }
    if ($problems.Count -gt 0) {
        throw "Migration preflight failed:`n- $($problems -join "`n- ")"
    }

    $preview = [ordered]@{
        status = if ($CheckOnly) { 'READY' } elseif ($WhatIfPreference) { 'PREVIEW' } else { 'MIGRATED' }
        source = $facts.Root
        target = $targetPath
        head = $facts.Head
        remote = $facts.Remote
        compatibilityPath = $legacy
    }
    if ($CheckOnly -or $WhatIfPreference) {
        if ($Json) { $preview | ConvertTo-Json -Compress } else {
            Write-Host "Level-0 source migration: $($preview.status)"
            Write-Host "  Source: $($facts.Root)"
            Write-Host "  Target: $targetPath"
            Write-Host "  HEAD:   $($facts.Head)"
        }
        exit 0
    }

    if ($facts.Root -ne $targetPath -and
        $PSCmdlet.ShouldProcess($facts.Root, "Move checkout to $targetPath")) {
        Move-Item -LiteralPath $facts.Root -Destination $targetPath
    }
    if ($facts.Root -eq $legacy -and
        $PSCmdlet.ShouldProcess($legacy, 'Create temporary compatibility link')) {
        if ($IsWindows) {
            $null = New-Item -ItemType Junction -Path $legacy -Target $targetPath
        } else {
            $null = New-Item -ItemType SymbolicLink -Path $legacy -Target $targetPath
        }
    }

    $stateDirectory = Join-Path $HOME '.home-baseline'
    $statePath = Join-Path $stateDirectory 'source-repository.json'
    $state = [ordered]@{
        schemaVersion = 1
        sourcePath = $targetPath
        migratedFrom = $facts.Root
        repository = $facts.Remote
        validatedCommit = $facts.Head
        updatedAt = [DateTimeOffset]::Now.ToString('o')
    }
    $null = New-Item -ItemType Directory -Path $stateDirectory -Force
    [IO.File]::WriteAllText(
        $statePath,
        (($state | ConvertTo-Json -Depth 5) + "`n"),
        [Text.UTF8Encoding]::new($false)
    )

    & git config --global "includeIf.gitdir:~/home-baseline-source/.path" `
        '~/.gitconfig.d/home-baseline.inc'
    if ($LASTEXITCODE -ne 0) { throw 'Could not configure new path-scoped Git identity.' }

    Set-HBTextReplacement -Path (Join-Path $HOME '.codex/config.toml') `
        -OldValue $facts.Root -NewValue $targetPath
    Set-HBTextReplacement -Path (Join-Path $HOME '.codex/rules/default.rules') `
        -OldValue $facts.Root -NewValue $targetPath
    Set-HBJsonProperty -Path (Join-Path $stateDirectory 'home-sync-state.json') `
        -Name 'sourcePath' -Value $targetPath

    if ($Json) { $preview | ConvertTo-Json -Compress } else {
        Write-Host "Level-0 source checkout migrated: $targetPath"
        Write-Host "Compatibility link retained until -Finalize: $legacy"
    }
    exit 0
} catch {
    if ($Json) {
        [ordered]@{ status = 'ERROR'; message = $_.Exception.Message } |
            ConvertTo-Json -Compress
    } else {
        [Console]::Error.WriteLine("Level-0 source migration error: $($_.Exception.Message)")
    }
    exit 2
}
