---
name: speckit-plan
description: Execute the implementation planning workflow using the plan template
  to generate design artifacts.
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:security-governance
---

# Speckit Plan Skill

Before continuing, apply the Security Governance preset:

- plan explicit MSL applicability or non-MSL justification work when relevant
- plan explicit secure-development verification work
- plan dependency and supply-chain evidence updates where relevant
- surface security review checkpoints instead of leaving them implicit

Before continuing, apply the Architecture Governance preset:

- plan explicit architecture evidence work
- plan threat-model and ADR updates when boundaries, integrations, or flows
  change
- surface Zero Trust and SAMM work explicitly when relevant
- surface BSI C3A cloud autonomy work explicitly for cloud services and
  provider-dependent deployments

Before continuing, apply the iSAQB Architecture Governance preset:

- plan explicit architecture work products where the feature changes
  structure, interfaces, quality attributes, runtime behavior, or
  deployment
- plan updates to architecture views under `docs/architecture/`
- plan ADRs for architecturally significant decisions
- plan risk and technical-debt review for trade-offs or unresolved
  constraints
- if security-relevant architecture is affected, also plan the
  secure-architecture evidence from `architecture-governance`

Before continuing, apply the A11Y Governance preset:

- plan accessibility review work explicitly
- plan bilingual content work explicitly
- include CLI accessibility checks where user-facing terminal output is changed

Before continuing, apply the Cross-Platform Governance preset:

- plan paired Bash + PowerShell script work as a single unit
- plan the man-page, the bilingual PowerShell help block, and the
  `Verb-Noun` Cmdlet alongside the script
- plan manual verification on at least one target OS per variant
- plan implementation discipline checks (Bash quoting, `set -euo
  pipefail`, `Set-StrictMode -Version Latest`, `-NoProfile`) and the
  parity-checklist artefact

Before continuing, apply the Agent Parity Governance preset:

- plan an atomic update across all maintained agent surfaces
- plan synchronised updates to project templates and the local
  `.specify/memory/constitution.md`
- plan a parity-verification artefact for the change


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before planning)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_plan` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_plan`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_plan` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue to the Completion Report.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Mandatory hook** (`optional: false`) — **You MUST emit `EXECUTE_COMMAND:` for each mandatory hook**:
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Completion Report

Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)

3. **Create quickstart validation guide** → `quickstart.md`:
   - Document runnable validation scenarios that prove the feature works end-to-end
   - Include prerequisites, setup commands, test/run commands, and expected outcomes
   - Use links or references to contracts and data model details instead of duplicating them
   - Do not include full implementation code, model/service/controller bodies, migrations, or complete test suites
   - Keep this artifact as a validation/run guide; implementation details belong in `tasks.md` and the implementation phase

**Output**: data-model.md, /contracts/*, quickstart.md

## Key rules

- Use absolute paths for filesystem operations; use project-relative paths for references in documentation
- ERROR on gate failures or unresolved clarifications

## Done When

- [ ] Plan workflow executed and design artifacts generated
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with branch, plan path, and generated artifacts


Audit-ready evidence requirement:

- Ensure this plan wrapper requires concrete Markdown evidence/checklist updates for every applicable checkpoint.
- If a checkpoint does not apply in the current Spec-Kit run, require `N/A` with a short rationale instead of omitting it.
- If a checkpoint is undecided, require `Open` with owner, follow-up, and re-evaluation trigger.

## Nutzungshilfe / Reader help

DE: Gemeinsame Regeln auf tatsächlich gepflegten Agentenflächen inhaltlich gleich halten. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-agent-parity-governance/blob/main/docs/user-guide.md).

EN: Keep shared rules semantically equivalent across actually maintained agent surfaces. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-agent-parity-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.


Audit-ready evidence requirement:

- Ensure this plan wrapper requires concrete Markdown evidence/checklist updates for every applicable checkpoint.
- If a checkpoint does not apply in the current Spec-Kit run, require `N/A` with a short rationale instead of omitting it.
- If a checkpoint is undecided, require `Open` with owner, follow-up, and re-evaluation trigger.

## Nutzungshilfe / Reader help

DE: Dieselbe fachliche Funktion auf benannten Plattformen prüfen, ohne nicht ausgeführte Tests zu behaupten. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-cross-platform-governance/blob/main/docs/user-guide.md).

EN: Check the same functional behaviour on named platforms without claiming unperformed tests. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-cross-platform-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.


Audit-ready evidence requirement:

- Ensure this plan wrapper requires concrete Markdown evidence/checklist updates for every applicable checkpoint.
- If a checkpoint does not apply in the current Spec-Kit run, require `N/A` with a short rationale instead of omitting it.
- If a checkpoint is undecided, require `Open` with owner, follow-up, and re-evaluation trigger.

## Nutzungshilfe / Reader help

DE: Nutzbare Oberflächen und verständliche zweisprachige Dokumentation von Anfang an einplanen. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-a11y-governance/blob/main/docs/user-guide.md).

EN: Plan usable interfaces and understandable bilingual documentation from the start. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-a11y-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.


Audit-ready evidence requirement:

- Ensure this plan wrapper requires concrete Markdown evidence/checklist updates for every applicable checkpoint.
- If a checkpoint does not apply in the current Spec-Kit run, require `N/A` with a short rationale instead of omitting it.
- If a checkpoint is undecided, require `Open` with owner, follow-up, and re-evaluation trigger.

## Nutzungshilfe / Reader help

DE: Systemaufbau und Architekturentscheidungen mit wenigen passenden Vorlagen erklären. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-isaqb-architecture-governance/blob/main/docs/user-guide.md).

EN: Explain system structure and architecture decisions with a few suitable templates. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-isaqb-architecture-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.


Audit-ready evidence requirement:

- Ensure this plan wrapper requires concrete Markdown evidence/checklist updates for every applicable checkpoint.
- If a checkpoint does not apply in the current Spec-Kit run, require `N/A` with a short rationale instead of omitting it.
- If a checkpoint is undecided, require `Open` with owner, follow-up, and re-evaluation trigger.

## C3A-/C5-Evidence-Vertrag / C3A/C5 evidence contract

DE: Bei anwendbarem C3A alle 30 Gruppen aus `c3a-criteria-catalog` v1.0
sichtbar halten; je ausgewaehltem C-/AC-Identifier Evidence und Variante mit
Begruendung erfassen. SI ist Erlaeuterung, kein bestandener Kontrollpunkt.
N/A braucht Begruendung; Open braucht Grund, Owner, Aktion und Wiedervorlage.
Providerbehauptungen von unabhaengiger Pruefung und Kundenpflichten trennen.
C5 Typ 1 ist zeitpunktbezogen und kein Wirksamkeitsnachweis ueber einen
Zeitraum. Typ 2 braucht Pruefzeitraum und Wirksamkeitsbewertung; Unknown bleibt
eine offene Luecke. C5 erfuellt C3A nicht automatisch. Keine Evidence erfinden,
kein Audit oder Zertifikat behaupten und historische Nachweise nicht umschreiben.

EN: For applicable C3A, retain all 30 groups from `c3a-criteria-catalog` v1.0;
record exact selected C/AC IDs, variant rationale and attributable evidence.
SI informs interpretation, not another passed control. N/A requires rationale;
Open requires reason, owner, action and reevaluation. Distinguish provider
claims, independent review and customer responsibilities. C5 Type 1 is
point-in-time assurance, not sustained operating effectiveness. Type 2 requires
audit period and effectiveness assessment; Unknown remains an open gap.
C5 does not automatically satisfy C3A. Do not fabricate evidence, claim an
audit/certification or rewrite historical records.

## Datenschutz und regulatorische Architektur / Privacy and regulatory architecture

DE: Die projektspezifische Anwendbarkeit von DS-GVO, KI-VO, CRA, NIS2 und
DORA wird durch Security-Evidence gefuehrt; hier keine zweite Rechtsentscheidung
erfinden. Bei installiertem Security-Preset dessen Detailvorlagen nutzen,
sonst gleichwertige projektgefuehrte Nachweise verlinken. Beispielprogramm,
Entwicklungswerkzeuge und Organisation getrennt betrachten; AI-SBOM: N/A
und Ausbildungszweck sind keine allgemeine regulatorische Ausnahme.
Privacy by Design/Default: Datenminimierung, Zweck, Empfaenger, Regionen,
Speicherbegrenzung, Loeschung und Betroffenenrechte in Datenfluessen abbilden.
KI-Tool-/Produktgrenzen, Prompt-, Logging- und Telemetriepfade pruefen.
NIS2-/DORA-relevante Dienstleisterabhaengigkeit, getestete Wiederherstellung,
Verfuegbarkeit, Konzentrationsrisiko und Exit-Faehigkeit rollenbezogen planen.
C3A/C5-Nachweise ersetzen keinen Datenschutz-, NIS2- oder DORA-Nachweis.
EN: Project Security evidence owns GDPR, AI Act, CRA, NIS2 and DORA
applicability; do not create a competing legal decision. Use Security detail
templates when installed, otherwise equivalent project-owned records.
Assess sample product, development tools and organisation separately;
AI-SBOM: N/A and education are not blanket regulatory exemptions.
Map privacy by design/default, minimisation, purpose, recipients, regions,
retention, deletion and subject rights to data flows. Review AI/tool boundaries
and prompt/log/telemetry paths. Plan role-specific supplier dependencies,
tested recovery, availability, concentration risk and exit capability for
NIS2/DORA-related scope. C3A/C5 evidence does not replace regulatory evidence.

- Applicability record / exact scope / owner / review date:
- Personal-data inventory / synthetic-data decision:
- Data flow / purpose / trust boundary / receiver / region:
- Retention / deletion / defaults / subject-rights interface:
- AI/tool usage boundary / prompt and logging safeguards:
- Supplier dependency / tested recovery / exit / concentration risk:
- Legal Open finding / qualified reviewer / next action / due date:

## Nutzungshilfe / Reader help

DE: Sicherheitsentscheidungen zur Systemstruktur nachvollziehbar machen, getrennt von der codebezogenen Security-Prüfung. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-architecture-governance/blob/main/docs/user-guide.md).

EN: Make system-structure security decisions traceable, separately from code-level security verification. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-architecture-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.


Audit-ready evidence requirement:

- Ensure this plan wrapper requires concrete Markdown evidence/checklist updates for every applicable checkpoint.
- If a checkpoint does not apply in the current Spec-Kit run, require `N/A` with a short rationale instead of omitting it.
- If a checkpoint is undecided, require `Open` with owner, follow-up, and re-evaluation trigger.

## Regulatorischer Evidence-Vertrag / Regulatory evidence contract

DE: DS-GVO, KI-VO, CRA, NIS2 und DORA getrennt fuer Beispielprogramm,
Entwicklungswerkzeuge und nutzende Organisation pruefen. Rechtliche Rollen,
Land, datierte Rechtsquelle und Anwendungszeitpunkt nennen; direkte Pflichten
von vertraglichen Kunden-/Lieferkettenanforderungen trennen. Unbekannt bleibt
Open mit Owner, Aktion und Frist. N/A braucht Begruendung und Trigger.
AI-SBOM: N/A entscheidet nicht ueber DS-GVO oder KI-VO. Ausbildung ist keine
allgemeine Ausnahme. Security fuehrt die Anwendbarkeit; Architecture
referenziert diese Entscheidung fuer Datenfluesse, Schutz und Resilienz.
Technische Pruefung ist keine Rechtsfreigabe. Historische Evidence erhalten.
EN: Assess GDPR, AI Act, CRA, NIS2 and DORA separately for the sample product,
development tooling and operating organisation. Record roles, jurisdiction,
dated legal source and application date; separate direct and contractual
duties. Unknown remains Open with owner, action and due date; N/A needs
rationale and trigger. AI-SBOM: N/A does not decide GDPR/AI Act applicability.
Education is not a blanket exemption. Security owns applicability;
Architecture links decisions to data flows, safeguards and resilience.
Technical validation grants no legal approval; preserve historical evidence.

Use regulatory-applicability-template as the index and link
gdpr-applicability-template, ai-act-applicability-template,
cra-applicability-template, nis2-applicability-template and
dora-applicability-template where relevant. An unfilled record is not evidence.

## Nutzungshilfe / Reader help

DE: Sichere Entwicklung planen und begründen, ohne eine bestandene Sicherheitsprüfung vorzutäuschen. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-security-governance/blob/main/docs/user-guide.md).

EN: Plan and explain secure development without claiming a passed security assessment. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-security-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.
