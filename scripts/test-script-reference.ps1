#Requires -Version 7
<#
.SYNOPSIS
Runs deterministic checks for the generated script reference.

.EXAMPLE
pwsh -NoProfile -File scripts/test-script-reference.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$renderer = Join-Path $PSScriptRoot 'render-script-reference.ps1'

& $renderer -Repo $repo
if ($LASTEXITCODE -ne 0) { throw 'Initial script reference render failed.' }
$first = Get-FileHash (Join-Path $repo 'docs/scripts/reference.md') -Algorithm SHA256
$embeddedFirst = Get-FileHash (Join-Path $repo 'docs/scripts/embedded-scripts.md') -Algorithm SHA256
& $renderer -Repo $repo -CheckOnly
if ($LASTEXITCODE -ne 0) { throw 'Generated script reference is not current.' }
$second = Get-FileHash (Join-Path $repo 'docs/scripts/reference.md') -Algorithm SHA256
$embeddedSecond = Get-FileHash (Join-Path $repo 'docs/scripts/embedded-scripts.md') -Algorithm SHA256
if ($first.Hash -ne $second.Hash -or $embeddedFirst.Hash -ne $embeddedSecond.Hash) {
    throw 'Repeated rendering changed generated documentation.'
}
Write-Host 'Script reference tests passed.'
