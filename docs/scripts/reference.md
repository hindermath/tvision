# Skriptreferenz / Script Reference

> Generiert aus `scripts/config/script-catalog.json` und dem Git-Index. Nicht manuell bearbeiten.
>
> Generated from `scripts/config/script-catalog.json` and the Git index. Do not edit manually.

Stand / Updated: 2026-07-28
Kanonische Skriptdateien / Canonical script files: 127

## Workspace-Lebenszyklus / Workspace lifecycle

Erstellt, migriert, synchronisiert oder entfernt verwaltete Arbeitsumgebungen.  
*Creates, migrates, synchronizes, or removes managed workspaces.*

### `scripts/bootstrap-project.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Initialisiert ein Level-2-Projekt idempotent. / Idempotently initializes a level-2 project.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/bootstrap-project.ps1 -Full
pwsh -NoProfile -File scripts/bootstrap-project.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/bootstrap-project.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** bootstrap-project.sh — Idempotenter Projekt-Bootstrap v1.1
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/bootstrap-project.sh --help
bash scripts/bootstrap-project.sh --dry-run  # falls angeboten / when supported
```

### `scripts/bootstrap-workspace.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Richtet ein neues Projektverzeichnis als privates Remote-Repo ein.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/bootstrap-workspace.ps1 -Full
pwsh -NoProfile -File scripts/bootstrap-workspace.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/bootstrap-workspace.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** bootstrap-workspace.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/bootstrap-workspace.sh --help
bash scripts/bootstrap-workspace.sh --dry-run  # falls angeboten / when supported
```

### `scripts/migrate-workspace.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** migrate-workspace.ps1 — Workspace Homogeneity Migration v1.0 (PowerShell)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/migrate-workspace.ps1 -Full
pwsh -NoProfile -File scripts/migrate-workspace.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/migrate-workspace.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** migrate-workspace.sh — Workspace Homogeneity Migration v1.0
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/migrate-workspace.sh --help
bash scripts/migrate-workspace.sh --dry-run  # falls angeboten / when supported
```

### `scripts/sync-home.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** sync-home.ps1 — Synchronisiert die dauerhafte Level-0-Quelle nach ~/
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/sync-home.ps1 -Full
pwsh -NoProfile -File scripts/sync-home.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/sync-home.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** sync-home.sh — Synchronisiert die dauerhafte Level-0-Quelle nach ~/
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/sync-home.sh --help
bash scripts/sync-home.sh --dry-run  # falls angeboten / when supported
```

### `scripts/teardown-workspace.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/teardown-workspace.ps1 -Full
pwsh -NoProfile -File scripts/teardown-workspace.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/teardown-workspace.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** shellcheck source=scripts/lib/hg-forgejo.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/teardown-workspace.sh --help
bash scripts/teardown-workspace.sh --dry-run  # falls angeboten / when supported
```

## Wartung und Toolchain / Maintenance and toolchain

Prueft und wartet die plattformgerechte Entwicklungs- und Agenten-Toolchain.  
*Checks and maintains the platform-specific development and agent toolchain.*

### `scripts/invoke-psscriptanalyzer.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft getrackte PowerShell-Dateien. / Analyzes tracked PowerShell files.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/invoke-psscriptanalyzer.ps1 -Full
pwsh -NoProfile -File scripts/invoke-psscriptanalyzer.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/maintain-agentic-brew-apps.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Maintain Homebrew packages for agentic development on macOS/Linux.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/maintain-agentic-brew-apps.sh --help
bash scripts/maintain-agentic-brew-apps.sh --dry-run  # falls angeboten / when supported
```

### `scripts/maintain-agentic-winget-apps.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Maintains WinGet packages for agentic development.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/maintain-agentic-winget-apps.ps1 -Full
pwsh -NoProfile -File scripts/maintain-agentic-winget-apps.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/maintain-agentic-workspace.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Orchestrates repository and agentic toolchain maintenance on Windows.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/maintain-agentic-workspace.ps1 -Full
pwsh -NoProfile -File scripts/maintain-agentic-workspace.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/maintain-agentic-workspace.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Orchestrate repository and agentic toolchain maintenance on macOS/Linux.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/maintain-agentic-workspace.sh --help
bash scripts/maintain-agentic-workspace.sh --dry-run  # falls angeboten / when supported
```

### `scripts/maintain-powershell-modules.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Pflegt erforderliche PowerShell-Module. / Maintains required PowerShell modules.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/maintain-powershell-modules.ps1 -Full
pwsh -NoProfile -File scripts/maintain-powershell-modules.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/propagate-agentic-toolchain-maintenance.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Propagiert das kanonische Toolchain-Wartungspaket in Level-1-/Level-2-Repositories.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/propagate-agentic-toolchain-maintenance.ps1 -Full
pwsh -NoProfile -File scripts/propagate-agentic-toolchain-maintenance.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/propagate-agentic-toolchain-maintenance.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Propagate the canonical agentic toolchain maintenance package to Level-1/2 repos.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/propagate-agentic-toolchain-maintenance.sh --help
bash scripts/propagate-agentic-toolchain-maintenance.sh --dry-run  # falls angeboten / when supported
```

## Governance und Spec Kit / Governance and Spec Kit

Installiert und prueft Spec-Kit-, Constitution- und Repository-Governance.  
*Installs and checks Spec Kit, constitution, and repository governance.*

### `scripts/check-gsdb-self-assessment.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft die GSDB-Bereitschaft und bereitet ein Spec-Kit-Intake vor.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/check-gsdb-self-assessment.ps1 -Full
pwsh -NoProfile -File scripts/check-gsdb-self-assessment.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/check-gsdb-self-assessment.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** check-gsdb-self-assessment.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/check-gsdb-self-assessment.sh --help
bash scripts/check-gsdb-self-assessment.sh --dry-run  # falls angeboten / when supported
```

### `scripts/install-spec-kit-governance-presets.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Installiert die zentral konfigurierten GitHub-Spec-Kit-Governance-Presets.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/install-spec-kit-governance-presets.ps1 -Full
pwsh -NoProfile -File scripts/install-spec-kit-governance-presets.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/install-spec-kit-governance-presets.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** install-spec-kit-governance-presets.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/install-spec-kit-governance-presets.sh --help
bash scripts/install-spec-kit-governance-presets.sh --dry-run  # falls angeboten / when supported
```

### `scripts/register-level2-repository.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Registriert Level-1-/Level-2-Repositories in der operativen GSDB-Registry.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/register-level2-repository.ps1 -Full
pwsh -NoProfile -File scripts/register-level2-repository.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/register-level2-repository.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** register-level2-repository.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/register-level2-repository.sh --help
bash scripts/register-level2-repository.sh --dry-run  # falls angeboten / when supported
```

### `scripts/resolve-model-routing.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft oder aktualisiert lokale Spec-Kit-Modellbindungen.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/resolve-model-routing.ps1 -Full
pwsh -NoProfile -File scripts/resolve-model-routing.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/resolve-model-routing.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/resolve-model-routing.sh --help
bash scripts/resolve-model-routing.sh --dry-run  # falls angeboten / when supported
```

### `scripts/sync-constitution.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** sync-constitution.ps1 — constitution.md in alle Level-1-Workspaces synchronisieren
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/sync-constitution.ps1 -Full
pwsh -NoProfile -File scripts/sync-constitution.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/sync-constitution.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** sync-constitution.sh — constitution.md in alle Level-1-Workspaces synchronisieren
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/sync-constitution.sh --help
bash scripts/sync-constitution.sh --dry-run  # falls angeboten / when supported
```

### `scripts/update-spec-kit.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Aktualisiert Spec-Kit-Integrationen in Level-0/Level-1/Level-2-Repos.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/update-spec-kit.ps1 -Full
pwsh -NoProfile -File scripts/update-spec-kit.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/update-spec-kit.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** update-spec-kit.sh — Refresh Spec-Kit integrations across home-baseline repos.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/update-spec-kit.sh --help
bash scripts/update-spec-kit.sh --dry-run  # falls angeboten / when supported
```

## Sicherheit und Audit / Security and audit

Prueft Geheimnisse, Agentenaenderungen und sichere Entwicklungsartefakte.  
*Checks secrets, agent changes, and secure-development artifacts.*

### `scripts/audit-agent-changes.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Erstellt lokale Agent-Audit-Snapshots und korreliert spaetere Aenderungen mit Agent-Logs.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/audit-agent-changes.ps1 -Full
pwsh -NoProfile -File scripts/audit-agent-changes.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/audit-agent-changes.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Tracks changes in agent-managed files and correlates them with local agent logs.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/audit-agent-changes.sh --help
bash scripts/audit-agent-changes.sh --dry-run  # falls angeboten / when supported
```

### `scripts/audit-antigravity-migration.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft die Antigravity-Migration in Level-0/1/2-Repositories.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/audit-antigravity-migration.ps1 -Full
pwsh -NoProfile -File scripts/audit-antigravity-migration.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/audit-antigravity-migration.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Audits the Antigravity migration across Level-0/1/2 repositories.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/audit-antigravity-migration.sh --help
bash scripts/audit-antigravity-migration.sh --dry-run  # falls angeboten / when supported
```

### `scripts/build-secure-development-docs.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Builds and validates the generated secure-development compendium.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/build-secure-development-docs.ps1 -Full
pwsh -NoProfile -File scripts/build-secure-development-docs.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/build-secure-development-docs.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Build and validate generated secure-development documentation.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/build-secure-development-docs.sh --help
bash scripts/build-secure-development-docs.sh --dry-run  # falls angeboten / when supported
```

### `scripts/prepare-secure-development-hardening.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Bereitet MSL-basierte Level-2-Repositories fuer spaetere Secure-Development-Haertung vor.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/prepare-secure-development-hardening.ps1 -Full
pwsh -NoProfile -File scripts/prepare-secure-development-hardening.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/prepare-secure-development-hardening.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** prepare-secure-development-hardening.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/prepare-secure-development-hardening.sh --help
bash scripts/prepare-secure-development-hardening.sh --dry-run  # falls angeboten / when supported
```

### `scripts/propagate-security-guidance.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Propagiert Security-Guidance-Updates aus Level-0 auf Level-1/Level-2-Repos.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/propagate-security-guidance.ps1 -Full
pwsh -NoProfile -File scripts/propagate-security-guidance.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/propagate-security-guidance.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** propagate-security-guidance.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/propagate-security-guidance.sh --help
bash scripts/propagate-security-guidance.sh --dry-run  # falls angeboten / when supported
```

### `scripts/scan-agent-secrets.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prüft git-getrackte Dateien auf Secret-Muster.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/scan-agent-secrets.ps1 -Full
pwsh -NoProfile -File scripts/scan-agent-secrets.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/scan-agent-secrets.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/scan-agent-secrets.sh --help
bash scripts/scan-agent-secrets.sh --dry-run  # falls angeboten / when supported
```

## Qualitaetspruefungen / Quality checks

Fuehrt reproduzierbare Repository-, Paket- und Git-Hook-Pruefungen aus.  
*Runs reproducible repository, package, and Git-hook checks.*

### `scripts/check-homogeneity.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** check-homogeneity.ps1 — Workspace Homogeneity Guardian Compliance Scanner v1.0 (PowerShell)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/check-homogeneity.ps1 -Full
pwsh -NoProfile -File scripts/check-homogeneity.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/check-homogeneity.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** check-homogeneity.sh — Workspace Homogeneity Guardian Compliance Scanner v1.0
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/check-homogeneity.sh --help
bash scripts/check-homogeneity.sh --dry-run  # falls angeboten / when supported
```

### `scripts/check-learning-package.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft ein Lernreihen-ZIP oder fuehrt einen Paket-Selbsttest aus.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/check-learning-package.ps1 -Full
pwsh -NoProfile -File scripts/check-learning-package.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/check-learning-package.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft Struktur, Pruefsumme und Ausschlussregeln eines Lernreihen-ZIPs.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/check-learning-package.sh --help
bash scripts/check-learning-package.sh --dry-run  # falls angeboten / when supported
```

### `scripts/hooks/pre-push`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** pre-push Hook: Blockiert den Push, wenn Secrets in git-getrackten Dateien gefunden werden.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/install-hooks.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Installiert die Git-Hooks aus scripts/hooks/ in .git/hooks/.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/install-hooks.ps1 -Full
pwsh -NoProfile -File scripts/install-hooks.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/install-hooks.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Installiert die Git-Hooks aus scripts/hooks/ in .git/hooks/.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/install-hooks.sh --help
bash scripts/install-hooks.sh --dry-run  # falls angeboten / when supported
```

### `scripts/test-homogeneity-runtime-closure.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prueft den Fail-closed-Vertrag des Homogeneity-Hilfspakets.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/test-homogeneity-runtime-closure.ps1 -Full
pwsh -NoProfile -File scripts/test-homogeneity-runtime-closure.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/test-homogeneity-runtime-closure.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Validates fail-closed loading and a complete Homogeneity runtime package.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/test-homogeneity-runtime-closure.sh --help
bash scripts/test-homogeneity-runtime-closure.sh --dry-run  # falls angeboten / when supported
```

### `scripts/tests/test_agentic_workspace_maintenance.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_agentic_workspace_maintenance.py --help
```

### `scripts/tests/test_feature_020_documentation_architecture.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_feature_020_documentation_architecture.py --help
```

### `scripts/tests/test_home_sync_files.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_home_sync_files.py --help
```

### `scripts/tests/test_linux_maintenance_hardening.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_linux_maintenance_hardening.py --help
```

### `scripts/tests/test_maintenance_contracts.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_maintenance_contracts.py --help
```

### `scripts/tests/test_maintenance_tui_wrappers.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_maintenance_tui_wrappers.py --help
```

### `scripts/tests/test_spec_kit_agent_surface_parity.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_spec_kit_agent_surface_parity.py --help
```

### `scripts/tests/test_sync_home_cli.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_sync_home_cli.py --help
```

### `scripts/tests/test_windows_maintenance_hardening.py`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
python3 scripts/tests/test_windows_maintenance_hardening.py --help
```

## Statistik / Statistics

Initialisiert, rendert und testet das ASCII-Statistikprofil.  
*Initializes, renders, and tests the ASCII statistics profile.*

### `scripts/init-stats.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** init-stats.ps1 — STATS.md Baseline-Generator v1.0 (PowerShell)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/init-stats.ps1 -Full
pwsh -NoProfile -File scripts/init-stats.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/init-stats.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** init-stats.sh — STATS.md Baseline-Generator v1.0
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/init-stats.sh --help
bash scripts/init-stats.sh --dry-run  # falls angeboten / when supported
```

### `scripts/render-project-statistics.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Renders the generated ASCII Statistics Profile 2 block.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/render-project-statistics.ps1 -Full
pwsh -NoProfile -File scripts/render-project-statistics.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/render-project-statistics.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Render ASCII Statistics Profile 2 through the canonical PowerShell engine.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/render-project-statistics.sh --help
bash scripts/render-project-statistics.sh --dry-run  # falls angeboten / when supported
```

### `scripts/test-render-project-statistics.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Testet den Renderer fuer ASCII-Statistikprofil 2.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/test-render-project-statistics.ps1 -Full
pwsh -NoProfile -File scripts/test-render-project-statistics.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

## Lernreihen / Learning series

Prueft, paketiert und pflegt bilinguale Lernreihenartefakte.  
*Checks, packages, and maintains bilingual learning-series artifacts.*

### `scripts/package-learning-series.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Erzeugt ein git-freies Lernreihen-ZIP.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/package-learning-series.ps1 -Full
pwsh -NoProfile -File scripts/package-learning-series.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/package-learning-series.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** package-learning-series.sh — erzeugt ein git-freies Lernreihen-ZIP
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/package-learning-series.sh --help
bash scripts/package-learning-series.sh --dry-run  # falls angeboten / when supported
```

### `scripts/prepare-rl-se-checklist-selbstpruefung.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Bereitet Repositories fuer spaetere RL-SE-/Checklist-Selbstpruefung vor.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/prepare-rl-se-checklist-selbstpruefung.ps1 -Full
pwsh -NoProfile -File scripts/prepare-rl-se-checklist-selbstpruefung.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/prepare-rl-se-checklist-selbstpruefung.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** prepare-rl-se-checklist-selbstpruefung.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/prepare-rl-se-checklist-selbstpruefung.sh --help
bash scripts/prepare-rl-se-checklist-selbstpruefung.sh --dry-run  # falls angeboten / when supported
```

### `scripts/propagate-learning-series.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Propagiert Lernreihen-Material aus Level-0 in Level-1/Level-2-Repos.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/propagate-learning-series.ps1 -Full
pwsh -NoProfile -File scripts/propagate-learning-series.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/propagate-learning-series.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** propagate-learning-series.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/propagate-learning-series.sh --help
bash scripts/propagate-learning-series.sh --dry-run  # falls angeboten / when supported
```

### `scripts/rename-lastenheft.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** rename-lastenheft.ps1 — Lastenheft umbenennen / Rename Lastenheft
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/rename-lastenheft.ps1 -Full
pwsh -NoProfile -File scripts/rename-lastenheft.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/rename-lastenheft.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** rename-lastenheft.sh — Lastenheft umbenennen / Rename Lastenheft
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/rename-lastenheft.sh --help
bash scripts/rename-lastenheft.sh --dry-run  # falls angeboten / when supported
```

## Agenten-Einrichtung / Agent setup

Erzeugt sichere, plattformgerechte lokale Einstellungen fuer KI-Agenten.  
*Creates secure, platform-appropriate local settings for AI agents.*

### `scripts/setup-antigravity-settings.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Richtet die gehaertete Antigravity-CLI-Konfiguration ein.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/setup-antigravity-settings.ps1 -Full
pwsh -NoProfile -File scripts/setup-antigravity-settings.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/setup-antigravity-settings.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Applies the hardened Antigravity CLI settings baseline on macOS/Linux.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/setup-antigravity-settings.sh --help
bash scripts/setup-antigravity-settings.sh --dry-run  # falls angeboten / when supported
```

### `scripts/setup-claude-settings.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Richtet die Claude Code statusLine in %APPDATA%\Claude\settings.json ein.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/setup-claude-settings.ps1 -Full
pwsh -NoProfile -File scripts/setup-claude-settings.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/setup-claude-settings.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Richtet die Claude Code statusLine in ~/.claude/settings.json ein.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/setup-claude-settings.sh --help
bash scripts/setup-claude-settings.sh --dry-run  # falls angeboten / when supported
```

### `scripts/setup-codex-settings.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Richtet die Codex CLI status_line in ~/.codex/config.toml ein.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/setup-codex-settings.ps1 -Full
pwsh -NoProfile -File scripts/setup-codex-settings.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/setup-codex-settings.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Richtet die Codex CLI status_line in ~/.codex/config.toml ein.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/setup-codex-settings.sh --help
bash scripts/setup-codex-settings.sh --dry-run  # falls angeboten / when supported
```

### `scripts/setup-copilot-settings.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Überträgt die GitHub Copilot CLI-Einstellungen nach ~/.copilot/config.json.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/setup-copilot-settings.ps1 -Full
pwsh -NoProfile -File scripts/setup-copilot-settings.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/setup-copilot-settings.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** setup-copilot-settings.sh — Überträgt die GitHub Copilot CLI-Einstellungen nach ~/.copilot/config.json
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/setup-copilot-settings.sh --help
bash scripts/setup-copilot-settings.sh --dry-run  # falls angeboten / when supported
```

## Git und Hosting / Git and hosting

Konfiguriert Git-Identitaet und Hosting-spezifische Release-Automation.  
*Configures Git identity and hosting-specific release automation.*

### `scripts/setup-git-identity.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Prüft und richtet die globale Git-Identität ein (Name + E-Mail).
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/setup-git-identity.ps1 -Full
pwsh -NoProfile -File scripts/setup-git-identity.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/setup-git-identity.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** setup-git-identity.sh
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/setup-git-identity.sh --help
bash scripts/setup-git-identity.sh --dry-run  # falls angeboten / when supported
```

### `scripts/setup-gitlab-release.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Installiert die GitLab Release-Automation in ein bestehendes Repository.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/setup-gitlab-release.ps1 -Full
pwsh -NoProfile -File scripts/setup-gitlab-release.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/setup-gitlab-release.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** setup-gitlab-release.sh — Installiert GitLab Release-Automation in ein bestehendes Repo
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/setup-gitlab-release.sh --help
bash scripts/setup-gitlab-release.sh --dry-run  # falls angeboten / when supported
```

## Plattformtests / Platform tests

Fuehrt den dokumentierten Plattformtest aus und publiziert dessen Ergebnis.  
*Runs the documented platform test and publishes its result.*

### `scripts/linux-test.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** linux-test.sh — Sammelt System-Info und Testergebnisse auf Linux
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/linux-test.sh --help
bash scripts/linux-test.sh --dry-run  # falls angeboten / when supported
```

### `scripts/mac-test.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** mac-test.sh - Mac Test Output Collector
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/mac-test.sh --help
bash scripts/mac-test.sh --dry-run  # falls angeboten / when supported
```

### `scripts/windows-test.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** windows-test.ps1 — Sammelt System-Info und Testergebnisse auf Windows
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/windows-test.ps1 -Full
pwsh -NoProfile -File scripts/windows-test.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

## Interne Bibliotheken / Internal libraries

Stellt wiederverwendbare interne Funktionen fuer die oeffentlichen Skripte bereit.  
*Provides reusable internal functions for public scripts.*

### `scripts/lib/agentic_workspace_fleet.py`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-a11y.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-a11y.ps1 — Accessibility-Prüfung Markdown (FR-005/006) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-a11y.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-a11y.sh — Accessibility-Prüfung Markdown (FR-005/006, R-02)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-bilingual.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-bilingual.ps1 — Bilingualitätsprüfung Markdown (FR-004) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-bilingual.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-bilingual.sh — Bilingualitätsprüfung Markdown (FR-004, R-01)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-deps.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-deps.ps1 — Bezahlte NuGet-Paket-Erkennung (FR-016) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-deps.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-deps.sh — Bezahlte NuGet-Paket-Erkennung (FR-016, R-06)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-forgejo.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-forgejo.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Shared Forgejo/Codeberg API support. Tokens are obtained through Git's
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-git-scope.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-git-scope.sh — Git Scope Isolation Check (FR-009, SC-005)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-hook.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-hook.ps1 — SHA-256-Vergleich pre-push Hook (FR-002) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-hook.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-hook.sh — SHA-256-Vergleich pre-push Hook (FR-002, R-03)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-patch.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-patch.ps1 — memory-patch.md Generator (FR-020/021) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-patch.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-patch.sh — memory-patch.md Generator (FR-020/021)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-scan.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-scan.ps1 — 3-Ebenen-Traversal Engine (FR-001) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-scan.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-scan.sh — 3-Ebenen-Traversal Engine (FR-001)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-secrets.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-secrets.ps1 — Secret-Pattern-Erkennung (FR-003) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-secrets.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-secrets.sh — Secret-Pattern-Erkennung (FR-003, R-01)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-speckit.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-speckit.ps1 — Spec-kit Template-Versionserkennung (FR-018) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-speckit.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-speckit.sh — Spec-kit Template-Versionserkennung (FR-018, R-05)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-stats.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-stats.ps1 — STATS.md Append-Only Schreiber (FR-007/008) — PowerShell
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/hg-stats.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** hg-stats.sh — STATS.md Append-Only Schreiber (FR-007/008, R-04)
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/home-sync-files.py`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/linux-maintenance-hardening.py`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/resolve-home-baseline-source.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/resolve-home-baseline-source.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/secure-development-hardening.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Shared helpers for secure-development hardening intake preparation.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/lib/secure-development-hardening.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Shared helpers for secure-development hardening intake preparation.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

## Ausfuehrbare Vorlagen / Executable templates

Dient als ausfuehrbare Vorlage, die durch Setup-Werkzeuge installiert wird.  
*Acts as an executable template installed by setup tools.*

### `scripts/templates/antigravity-statusline.ps1`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

### `scripts/templates/antigravity-statusline.sh`

- **Rolle / Role:** intern oder installiert / internal or installed
- **Kurzbeschreibung / Summary:** Siehe Quelltext und Hilfe. / See source and help.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Nicht direkt aufrufen; wird von oeffentlichen Skripten geladen.
Do not invoke directly; it is loaded by public scripts.
```

## Level-0-Quellmigration / Level 0 source migration

Prueft und migriert den dauerhaften Level-0-Checkout ohne Verlust lokaler Konfiguration.  
*Checks and migrates the permanent Level 0 checkout without losing local configuration.*

### `scripts/migrate-level0-source-checkout.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Migrates the permanent Level 0 checkout to a stable local source path.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/migrate-level0-source-checkout.ps1 -Full
pwsh -NoProfile -File scripts/migrate-level0-source-checkout.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/migrate-level0-source-checkout.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Migrate the permanent Level-0 checkout through the canonical PowerShell engine.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/migrate-level0-source-checkout.sh --help
bash scripts/migrate-level0-source-checkout.sh --dry-run  # falls angeboten / when supported
```

## Skriptdokumentation / Script documentation

Validiert den Skriptbestand und erzeugt die zentrale Referenz.  
*Validates the script inventory and renders the central reference.*

### `scripts/render-script-reference.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Validates the script catalog and renders the central script reference.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/render-script-reference.ps1 -Full
pwsh -NoProfile -File scripts/render-script-reference.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/render-script-reference.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Validate the script inventory and render its central bilingual reference.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/render-script-reference.sh --help
bash scripts/render-script-reference.sh --dry-run  # falls angeboten / when supported
```

### `scripts/test-documentation-impact.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Runs deterministic Documentation Impact contract fixtures.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/test-documentation-impact.ps1 -Full
pwsh -NoProfile -File scripts/test-documentation-impact.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/test-documentation-impact.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Run Documentation Impact fixtures through the Bash entry point.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/test-documentation-impact.sh --help
bash scripts/test-documentation-impact.sh --dry-run  # falls angeboten / when supported
```

### `scripts/test-script-reference.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Runs deterministic checks for the generated script reference.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/test-script-reference.ps1 -Full
pwsh -NoProfile -File scripts/test-script-reference.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/validate-documentation-impact.ps1`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Validates Documentation Impact evidence.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
Get-Help ./scripts/validate-documentation-impact.ps1 -Full
pwsh -NoProfile -File scripts/validate-documentation-impact.ps1 -WhatIf  # falls SupportsShouldProcess angeboten wird / when supported
```

### `scripts/validate-documentation-impact.sh`

- **Rolle / Role:** oeffentliches Kommando / public command
- **Kurzbeschreibung / Summary:** Validate Documentation Impact evidence through the portable PowerShell core.
- **Voraussetzungen / Prerequisites:** passende Shell; weitere Anforderungen stehen in `--help` oder `Get-Help`.
- **Nebenwirkungen / Side effects:** zuerst Check-, Dry-Run- oder WhatIf-Modus verwenden, sofern angeboten.

```text
bash scripts/validate-documentation-impact.sh --help
bash scripts/validate-documentation-impact.sh --dry-run  # falls angeboten / when supported
```
