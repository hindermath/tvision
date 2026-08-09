<#
.SYNOPSIS
Installiert die GitLab Release-Automation in ein bestehendes Repository.

.DESCRIPTION
Kopiert die generische Datei `scripts/release-gitlab.sh`, erzeugt bei Bedarf
`CHANGELOG.md`, ergaenzt `.gitlab-ci.yml` um eine manuelle Release-Stage und
aktiviert optional `ci_push_repository_for_job_token_allowed` per GitLab API.

.PARAMETER TargetRepository
Pfad zum Ziel-Repository. Standard ist das aktuelle Verzeichnis.

.PARAMETER GitLabUrl
Optionale GitLab-Basis-URL, zum Beispiel `https://gitlab-ce.gwdg.de`.

.PARAMETER SkipProjectSettings
Ueberspringt die GitLab-Projekteinstellung
`ci_push_repository_for_job_token_allowed`.

.PARAMETER Force
Ueberschreibt `scripts/release-gitlab.sh` und `CHANGELOG.md`, falls vorhanden.

.EXAMPLE
pwsh scripts/setup-gitlab-release.ps1 -TargetRepository ~/RiderProjects/MyGitLabRepo

.EXAMPLE
pwsh scripts/setup-gitlab-release.ps1 -TargetRepository ~/RiderProjects/MyGitLabRepo -GitLabUrl https://gitlab-ce.gwdg.de
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TargetRepository = $PWD.Path,
    [string]$GitLabUrl = '',
    [switch]$SkipProjectSettings,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplatesDir = Join-Path $ScriptDir 'templates'
$TargetRepository = $TargetRepository.TrimEnd([IO.Path]::DirectorySeparatorChar)
if ($TargetRepository.StartsWith('~')) {
    $TargetRepository = Join-Path $HOME $TargetRepository.Substring(1).TrimStart('/','\')
}

function Convert-RemoteToProjectPath([string]$RemoteUrl) {
    if ($RemoteUrl -match '^https://[^/]+/(.+?)(?:\.git)?$') {
        return $Matches[1]
    }
    if ($RemoteUrl -match '^git@[^:]+:(.+?)(?:\.git)?$') {
        return $Matches[1]
    }
    if ($RemoteUrl -match '^ssh://git@[^/]+/(.+?)(?:\.git)?$') {
        return $Matches[1]
    }
    return ''
}

function Convert-RemoteToHost([string]$RemoteUrl) {
    if ($RemoteUrl -match '^https://([^/]+)/') {
        return $Matches[1]
    }
    if ($RemoteUrl -match '^git@([^:]+):') {
        return $Matches[1]
    }
    if ($RemoteUrl -match '^ssh://git@([^/]+)/') {
        return $Matches[1]
    }
    return ''
}

function Ensure-ReleaseStage {
    param([string]$CiFile)

    $content = Get-Content -Path $CiFile -Raw
    if ($content -match '(?m)^\s*-\s*release\s*$' -or $content -match '(?m)^stages:\s*\[[^\]]*\brelease\b[^\]]*\]') {
        return
    }

    if ($content -match '(?m)^stages:\s*\[(?<list>[^\]]*)\]') {
        $list = $Matches['list'].Trim()
        if ($list) {
            $replacement = "stages: [$list, release]"
        } else {
            $replacement = 'stages: [release]'
        }
        $content = [regex]::Replace($content, '(?m)^stages:\s*\[[^\]]*\]', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }, 1)
    } elseif ($content -match '(?m)^stages:\s*$') {
        $lines = [System.Collections.Generic.List[string]](Get-Content -Path $CiFile)
        $index = $lines.FindIndex({ param($line) $line -match '^stages:\s*$' })
        if ($index -ge 0) {
            $insertAt = $index + 1
            while ($insertAt -lt $lines.Count -and $lines[$insertAt] -match '^\s*-\s+') {
                $insertAt++
            }
            $lines.Insert($insertAt, '  - release')
            $content = ($lines -join [Environment]::NewLine)
        }
    } else {
        $content = "stages:`n  - release`n`n$content"
    }

    Set-Content -Path $CiFile -Value $content -Encoding UTF8
}

function Enable-JobTokenPush {
    param([string]$RepositoryPath)

    if ($SkipProjectSettings) {
        Write-Host '  INFO: GitLab project settings skipped'
        return
    }

    if (-not (Get-Command glab -ErrorAction SilentlyContinue)) {
        Write-Host '  WARN: glab not installed — project setting not changed'
        return
    }

    $remoteUrl = ((git -C $RepositoryPath remote get-url origin 2>$null) | Out-String).Trim()
    if (-not $remoteUrl) {
        Write-Host '  WARN: origin remote missing — project setting not changed'
        return
    }

    $projectPath = Convert-RemoteToProjectPath $remoteUrl
    if (-not $projectPath) {
        Write-Host '  WARN: could not derive GitLab project path from origin remote'
        return
    }

    $gitlabHost = if ($GitLabUrl) { ($GitLabUrl -replace '^https://', '').TrimEnd('/') } else { Convert-RemoteToHost $remoteUrl }
    if (-not $gitlabHost) {
        Write-Host '  WARN: could not derive GitLab host from origin remote'
        return
    }

    $env:GITLAB_HOST = $gitlabHost
    & glab auth status 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  WARN: not authenticated for GitLab host $gitlabHost"
        $env:GITLAB_HOST = $null
        return
    }

    $encodedProject = $projectPath -replace '/', '%2F'
    & glab api --method PUT "projects/$encodedProject?ci_push_repository_for_job_token_allowed=true" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: enabled ci_push_repository_for_job_token_allowed for $projectPath"
    } else {
        Write-Host "  WARN: could not enable ci_push_repository_for_job_token_allowed for $projectPath"
    }
    $env:GITLAB_HOST = $null
}

foreach ($required in @(
    (Join-Path $TemplatesDir 'release-gitlab.sh.tmpl'),
    (Join-Path $TemplatesDir 'gitlab-release-job.yml.tmpl'),
    (Join-Path $TemplatesDir 'changelog-template.md')
)) {
    if (-not (Test-Path $required)) {
        throw "Missing template: $required"
    }
}

if (-not (Test-Path (Join-Path $TargetRepository '.git'))) {
    throw "Target is not a git repository: $TargetRepository"
}

Write-Host 'GitLab release automation'
Write-Host "Target: $TargetRepository"

$scriptsDir = Join-Path $TargetRepository 'scripts'
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

$releaseScriptTarget = Join-Path $scriptsDir 'release-gitlab.sh'
if ($PSCmdlet.ShouldProcess($releaseScriptTarget, 'Write release-gitlab.sh')) {
    Copy-Item (Join-Path $TemplatesDir 'release-gitlab.sh.tmpl') $releaseScriptTarget -Force
    if (-not $IsWindows) {
        & chmod +x $releaseScriptTarget 2>$null | Out-Null
    }
    Write-Host '  OK: wrote scripts/release-gitlab.sh'
}

$changelogTarget = Join-Path $TargetRepository 'CHANGELOG.md'
if ($Force -or -not (Test-Path $changelogTarget)) {
    if ($PSCmdlet.ShouldProcess($changelogTarget, 'Write CHANGELOG.md')) {
        Copy-Item (Join-Path $TemplatesDir 'changelog-template.md') $changelogTarget -Force
        Write-Host '  OK: wrote CHANGELOG.md'
    }
} else {
    Write-Host '  INFO: CHANGELOG.md already present'
}

$ciFile = Join-Path $TargetRepository '.gitlab-ci.yml'
$jobTemplate = (Get-Content (Join-Path $TemplatesDir 'gitlab-release-job.yml.tmpl') -Raw).TrimEnd()
if (-not (Test-Path $ciFile)) {
    if ($PSCmdlet.ShouldProcess($ciFile, 'Create .gitlab-ci.yml')) {
        "stages:`n  - release`n`n$jobTemplate`n" | Set-Content -Path $ciFile -Encoding UTF8
        Write-Host '  OK: created .gitlab-ci.yml'
    }
} else {
    if ($PSCmdlet.ShouldProcess($ciFile, 'Ensure release stage')) {
        Ensure-ReleaseStage -CiFile $ciFile
        $content = Get-Content -Path $ciFile -Raw
        if ($content -match 'home-baseline gitlab release automation') {
            Write-Host '  INFO: release job already present in .gitlab-ci.yml'
        } else {
            $suffix = if ($content.EndsWith([Environment]::NewLine)) { '' } else { [Environment]::NewLine }
            Set-Content -Path $ciFile -Value ($content + $suffix + [Environment]::NewLine + $jobTemplate + [Environment]::NewLine) -Encoding UTF8
            Write-Host '  OK: appended release job to .gitlab-ci.yml'
        }
    }
}

Enable-JobTokenPush -RepositoryPath $TargetRepository
Write-Host 'Done.'
