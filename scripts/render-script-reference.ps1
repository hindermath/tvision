#Requires -Version 7
<#
.SYNOPSIS
Validates the script catalog and renders the central script reference.

.DESCRIPTION
Inventories every Git-tracked canonical script under scripts/ and every
embedded script outside that directory. Category rules must cover each
canonical file exactly once. Generated documentation uses normalized LF.

.PARAMETER Repo
Repository root. Defaults to the current directory.

.PARAMETER CheckOnly
Checks catalog coverage and documentation drift without writing.

.PARAMETER Json
Emits one machine-readable result object.

.EXAMPLE
pwsh -NoProfile -File scripts/render-script-reference.ps1 -Repo . -CheckOnly

.EXAMPLE
pwsh -NoProfile -File scripts/render-script-reference.ps1 -Repo . -WhatIf

.EXAMPLE
pwsh -NoProfile -File scripts/render-script-reference.ps1 -Repo .
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [string]$Repo = '.',
    [switch]$CheckOnly,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-HBGit {
    <#
    .SYNOPSIS
    Runs Git without shell interpolation and returns normalized output lines.
    #>
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $output = & git -C $Repository @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git failed ($LASTEXITCODE): $($output -join "`n")"
    }
    @($output | ForEach-Object { [string]$_ })
}

function ConvertTo-HBRegex {
    <#
    .SYNOPSIS
    Converts the catalog's path glob subset to an anchored regular expression.
    #>
    param([Parameter(Mandatory)][string]$Pattern)
    '^' + [regex]::Escape($Pattern).Replace('\*', '[^/]*').Replace('\?', '[^/]') + '$'
}

function Test-HBScriptPath {
    <#
    .SYNOPSIS
    Determines whether a tracked path is an executable script artifact.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $Path -match '\.(?:ps1|sh|py)$' -or $Path -match '^scripts/hooks/[^/]+$'
}

function Get-HBInvocationExamples {
    <#
    .SYNOPSIS
    Returns safe discovery and preview examples for one canonical script.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][bool]$Internal
    )
    if ($Internal) {
        return @(
            "Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.",
            "Do not invoke directly; it is loaded by public scripts."
        )
    }
    switch -Regex ($Path) {
        '\.ps1$' {
            return @(
                "Get-Help ./$Path -Full",
                "pwsh -NoProfile -File $Path -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported"
            )
        }
        '\.sh$|^scripts/hooks/' {
            return @(
                "bash $Path --help",
                "bash $Path --dry-run  # falls angeboten / when supported"
            )
        }
        '\.py$' {
            return @("python3 $Path --help")
        }
    }
}

function Get-HBSummary {
    <#
    .SYNOPSIS
    Extracts the first useful source comment as a concise inventory hint.
    #>
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Path
    )
    $lines = Get-Content -LiteralPath (Join-Path $Repository $Path) -Encoding UTF8 -TotalCount 50
    foreach ($line in $lines) {
        $candidate = $line.Trim()
        if ($candidate -match '^(?:#|//)\s*(?!Requires|!)(.+)$') {
            return $Matches[1].Trim()
        }
        if ($candidate -eq '.SYNOPSIS') {
            $index = [Array]::IndexOf($lines, $line)
            if ($index -ge 0 -and $index + 1 -lt $lines.Count) {
                return $lines[$index + 1].Trim()
            }
        }
    }
    'Siehe Quelltext und Hilfe. / See source and help.'
}

function ConvertTo-HBMarkdown {
    <#
    .SYNOPSIS
    Renders the canonical reference and embedded inventory from validated data.
    #>
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][object[]]$Assignments,
        [Parameter(Mandatory)][string[]]$Embedded,
        [Parameter(Mandatory)][string]$Repository
    )

    $reference = [Text.StringBuilder]::new()
    $null = $reference.AppendLine('# Skriptreferenz / Script Reference')
    $null = $reference.AppendLine()
    $null = $reference.AppendLine('> Generiert aus `scripts/config/script-catalog.json` und dem Git-Index. Nicht manuell bearbeiten.')
    $null = $reference.AppendLine('>')
    $null = $reference.AppendLine('> Generated from `scripts/config/script-catalog.json` and the Git index. Do not edit manually.')
    $null = $reference.AppendLine()
    $null = $reference.AppendLine("Stand / Updated: $($Catalog.updated)")
    $null = $reference.AppendLine("Kanonische Skriptdateien / Canonical script files: $($Assignments.Count)")
    $null = $reference.AppendLine()

    foreach ($category in $Catalog.categories) {
        $items = @($Assignments | Where-Object CategoryId -eq $category.id | Sort-Object Path)
        if ($items.Count -eq 0) { continue }
        $null = $reference.AppendLine("## $($category.titleDe) / $($category.titleEn)")
        $null = $reference.AppendLine()
        $null = $reference.AppendLine("$($category.purposeDe)  ")
        $null = $reference.AppendLine("*$($category.purposeEn)*")
        $null = $reference.AppendLine()
        foreach ($item in $items) {
            $internal = $item.Path -match '^scripts/(?:lib|templates)/' -or
                $item.Path -match '^scripts/hooks/'
            $null = $reference.AppendLine("### ``$($item.Path)``")
            $null = $reference.AppendLine()
            $null = $reference.AppendLine("- **Rolle / Role:** " + $(if ($internal) {
                'intern oder installiert / internal or installed'
            } else {
                'oeffentliches Kommando / public command'
            }))
            $null = $reference.AppendLine("- **Kurzbeschreibung / Summary:** $(Get-HBSummary -Repository $Repository -Path $item.Path)")
            $null = $reference.AppendLine('- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.')
            $null = $reference.AppendLine('- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.')
            $null = $reference.AppendLine()
            $null = $reference.AppendLine('```text')
            foreach ($example in Get-HBInvocationExamples -Path $item.Path -Internal $internal) {
                $null = $reference.AppendLine($example)
            }
            $null = $reference.AppendLine('```')
            $null = $reference.AppendLine()
        }
    }

    $embeddedText = [Text.StringBuilder]::new()
    $null = $embeddedText.AppendLine('# Eingebettete Skripte / Embedded Scripts')
    $null = $embeddedText.AppendLine()
    $null = $embeddedText.AppendLine('> Vollstaendige, generierte Liste der Git-getrackten Skriptkopien ausserhalb von `scripts/`.')
    $null = $embeddedText.AppendLine('>')
    $null = $embeddedText.AppendLine('> Complete generated list of Git-tracked script copies outside `scripts/`.')
    $null = $embeddedText.AppendLine()
    $null = $embeddedText.AppendLine('Diese Dateien gehoeren zu Skills, Spec-Kit-Presets, Fixtures oder Publikationskopien.')
    $null = $embeddedText.AppendLine('Aenderungen erfolgen an der jeweiligen kanonischen Quelle und werden danach propagiert.')
    $null = $embeddedText.AppendLine()
    $null = $embeddedText.AppendLine('*These files belong to skills, Spec Kit presets, fixtures, or publication copies.')
    $null = $embeddedText.AppendLine('Change their respective canonical source first, then propagate the result.*')
    $null = $embeddedText.AppendLine()
    $null = $embeddedText.AppendLine("| Pfad / Path | Bereich / Area |")
    $null = $embeddedText.AppendLine("|---|---|")
    foreach ($path in $Embedded) {
        $area = ($path -split '/')[0]
        $null = $embeddedText.AppendLine("| ``$path`` | ``$area`` |")
    }

    [pscustomobject]@{
        Reference = $reference.ToString().Replace("`r`n", "`n").TrimEnd() + "`n"
        Embedded = $embeddedText.ToString().Replace("`r`n", "`n").TrimEnd() + "`n"
    }
}

try {
    $repository = (Resolve-Path -LiteralPath $Repo -ErrorAction Stop).Path
    $root = @(Invoke-HBGit -Repository $repository -Arguments @(
        'rev-parse',
        '--show-toplevel'
    ))[0]
    $catalogPath = Join-Path $root 'scripts/config/script-catalog.json'
    $schemaPath = Join-Path $root 'scripts/config/script-catalog.schema.json'
    $catalogJson = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8
    if (-not (Test-Json -Json $catalogJson -SchemaFile $schemaPath -ErrorAction Stop)) {
        throw 'Script catalog does not match its schema.'
    }
    $catalog = $catalogJson | ConvertFrom-Json -Depth 20

    # Include new, non-ignored files so pre-commit validation cannot omit the
    # renderer or another script introduced by the current change.
    $tracked = @(Invoke-HBGit -Repository $root -Arguments @(
        'ls-files',
        '--cached',
        '--others',
        '--exclude-standard'
    ))
    $canonical = @($tracked | Where-Object {
        $_ -like 'scripts/*' -and (Test-HBScriptPath -Path $_)
    } | Sort-Object)
    $embedded = @($tracked | Where-Object {
        $_ -notlike 'scripts/*' -and
        $_ -match '\.(?:ps1|sh|py)$'
    } | Sort-Object)

    $assignments = [Collections.Generic.List[object]]::new()
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($path in $canonical) {
        $relative = $path.Substring('scripts/'.Length)
        $categoryMatches = @($catalog.categories | Where-Object {
            $category = $_
            @($category.patterns | Where-Object {
                $relative -match (ConvertTo-HBRegex -Pattern $_)
            }).Count -gt 0
        })
        if ($path -in @($catalog.excluded)) { continue }
        if ($categoryMatches.Count -ne 1) {
            $errors.Add("$path must match exactly one category; matched $($categoryMatches.Count).")
            continue
        }
        $assignments.Add([pscustomobject]@{
            Path = $path
            CategoryId = $categoryMatches[0].id
        })
    }
    foreach ($excluded in @($catalog.excluded)) {
        if ($excluded -notin $canonical) {
            $errors.Add("Excluded path is not a canonical tracked script: $excluded")
        }
    }
    if ($errors.Count -gt 0) {
        throw ($errors -join "`n")
    }

    $rendered = ConvertTo-HBMarkdown -Catalog $catalog -Assignments $assignments `
        -Embedded $embedded -Repository $root
    $targets = [ordered]@{
        (Join-Path $root 'docs/scripts/reference.md') = $rendered.Reference
        (Join-Path $root 'docs/scripts/embedded-scripts.md') = $rendered.Embedded
    }
    $drift = [Collections.Generic.List[string]]::new()
    foreach ($target in $targets.Keys) {
        $current = if (Test-Path -LiteralPath $target) {
            (Get-Content -LiteralPath $target -Raw -Encoding UTF8).Replace("`r`n", "`n")
        } else { '' }
        if ($current -ne $targets[$target]) {
            $drift.Add([IO.Path]::GetRelativePath($root, $target))
        }
    }

    if ($CheckOnly) {
        $status = if ($drift.Count -eq 0) { 'CURRENT' } else { 'DRIFT' }
        $exitCode = if ($drift.Count -eq 0) { 0 } else { 1 }
    } elseif ($WhatIfPreference) {
        $status = 'PREVIEW'
        $exitCode = 0
        foreach ($target in $targets.Keys) {
            Write-Host "=== $([IO.Path]::GetRelativePath($root, $target)) ==="
            Write-Host $targets[$target]
        }
    } else {
        foreach ($target in $targets.Keys) {
            $directory = Split-Path -Parent $target
            $null = New-Item -ItemType Directory -Path $directory -Force
            if ($PSCmdlet.ShouldProcess($target, 'Write generated script documentation')) {
                [IO.File]::WriteAllText($target, $targets[$target], [Text.UTF8Encoding]::new($false))
            }
        }
        $status = 'WRITTEN'
        $exitCode = 0
    }

    $result = [ordered]@{
        status = $status
        canonicalScripts = $canonical.Count
        embeddedScripts = $embedded.Count
        drift = @($drift)
    }
    if ($Json) {
        $result | ConvertTo-Json -Depth 5 -Compress
    } elseif (-not $WhatIfPreference) {
        Write-Host "Script reference: $status; canonical=$($canonical.Count); embedded=$($embedded.Count)"
        foreach ($path in $drift) { Write-Host "  $path" }
    }
    exit $exitCode
} catch {
    if ($Json) {
        [ordered]@{ status = 'ERROR'; message = $_.Exception.Message } |
            ConvertTo-Json -Compress
    } else {
        [Console]::Error.WriteLine("Script reference error: $($_.Exception.Message)")
    }
    exit 2
}
