# AGENTS.md — tvision

## Einstieg und Detailregeln / Entry point and detailed rules

DE: Lies die Projektkonstitution und vor der Arbeit die [Detailregeln](docs/agent-guidance.md)
für deine Aufgabe. Sie ergänzen die verbindlichen Arbeits-, Sicherheits-, Prüf- und Freigaberegeln.

EN: Read the project constitution and the relevant [detailed rules](docs/agent-guidance.md)
before working. They supplement the binding work, security, verification and approval rules.

**Workspace**: ~/CLionProjects
**Projekt / Project**: tvision

---

## Überblick / Overview

Dieses Dokument gibt KI-Agenten (OpenAI Codex, GitHub Copilot) Anweisungen für die Arbeit in diesem Projekt.

This document provides AI agents (OpenAI Codex, GitHub Copilot) with instructions for working in this project.

---

## Projektkontext / Project Context

**Projektname / Project Name**: tvision
**Workspace**: ~/CLionProjects
**Primärsprache / Primary Language**: C++14 mit CMake / C++14 with CMake

### Level-0- und Home-Sync-Grenze / Level-0 and Home Sync Boundary

- Der persönliche Fork `~/home-baseline-source` bleibt die versionierte
  Level-0-Quelle und wird nach dem ersten Sync nicht gelöscht.
- `~/` ist nur die manifestgesteuerte lokale Betriebskopie. Vor einem echten
  Home-Sync `--check-only` / `-CheckOnly` verwenden und Konflikte nicht ohne
  Prüfung mit `--force` / `-Force` überschreiben.
- In Containern und insbesondere der ABS-DD-Sandbox die eingebundene
  Level-0-Referenz direkt verwenden; schreibende Home-Sync-Laeufe gehoeren auf
  den Host.

*Keep the personal fork `~/home-baseline-source` as the versioned level-0 source.
`~/` is only the manifest-managed local runtime copy. Check before syncing and
use force only after reviewing conflicts. In containers, especially the
ABS-DD sandbox, use the mounted level-0 reference directly and run writing Home
sync operations on the host.*

---

## Verwendung / Usage

### Für Codex und Copilot / For Codex and Copilot

Dieses Repository folgt dem **Workspace Homogeneity Guardian**-Standard:

- Neue lokale Governance-Dokumentation ist zweisprachig (Deutsch primär, Englisch sekundär); die bestehende englische Upstream-Dokumentation bleibt erhalten
- Skripte liegen als `.sh` (Bash 5+) und `.ps1` (PowerShell Core 7+) vor
- Secrets werden nie eingecheckt
- Neue Projekte werden mit `bootstrap-project.sh` angelegt

This repository follows the **Workspace Homogeneity Guardian** standard:

- New local governance documentation is bilingual (German primary, English secondary); existing English upstream documentation is preserved
- Scripts exist as `.sh` (Bash 5+) and `.ps1` (PowerShell Core 7+)
- Secrets are never committed
- New projects are created with `bootstrap-project.sh`

---

## Für Azubis / For Apprentices

Willkommen! Hier sind deine ersten Schritte:

1. **Voraussetzungen prüfen**: `git`, `bash`, `ripgrep (rg)` installiert?
2. **Compliance-Check ausführen**: `bash ~/scripts/check-homogeneity.sh ~/`
3. **WARNs und FAILs lesen** und beheben
4. **Fragen?** Schau in `~/README.md §Für Azubis` oder frag deinen Senior

Welcome! Here are your first steps:

1. **Check prerequisites**: `git`, `bash`, `ripgrep (rg)` installed?
2. **Run compliance check**: `bash ~/scripts/check-homogeneity.sh ~/`
3. **Read WARNs and FAILs** and fix them
4. **Questions?** See `~/README.md §For Apprentices` or ask your senior

---

## Einrichtung / Setup

### Voraussetzungen / Prerequisites

- `git` ≥ 2.x
- `bash` ≥ 5.x
- `ripgrep` (`rg`)
- CMake ≥ 3.5 und ein C++14-Compiler; GoogleTest für `TV_BUILD_TESTS=ON`
- `node` / `npx` (optional — für Spec-kit / for Spec-kit)

---

## Statistik-Pflege / Statistics Maintenance

- Führe `docs/project-statistics.md` als lebendes Statistik-Ledger dieses Projekts.
- Aktualisiere die Datei nach jeder abgeschlossenen Spec-Kit-Implementierungsphase, nach jedem abgeschlossenen Feature oder wenn explizit angefordert.
- Im `## Fortschreibungsprotokoll`-Abschnitt gilt: ältester Eintrag oben, neuester Eintrag unten; Einträge mit gleichem Datum behalten ihre Einfügereihenfolge.
- Halte den `## Gesamtstatistik`-Abschnitt immer als letzten Top-Level-Abschnitt; hänge danach keine weiteren Top-Level-Abschnitte an.
- `docs/project-statistics.config.json` und der markierte Profil-2-Block sind der verbindliche Vertrag; mit `render-project-statistics.*` aktualisieren.
- Profil 2 zeigt KPI, Artefaktmix, 52-Wochen-Tagesaktivität, Wochen- und kumulatives Volumen, Phasen- oder Monatsvolumen, Speedup-Gauges und den manuellen Vergleich.
- Nur ASCII verwenden: Heatmap `0..4`, `-` für noch nicht abgelaufene Tage und Gauges `#`/`.`; keine Unicode-Blöcke, Farbcodierung oder `\ | /` als Intensitätsskala.
- Phasenslots stabil halten, ab 17 Einträgen in 16er-Blöcke teilen und ohne belastbare Phasenwerte Monatsvolumen statt erfundener Phasen zeigen.
- Jedes Diagramm bleibt höchstens 100 Zeichen breit und erhält genaue Werte sowie eine CEFR-B2-Textalternative in Deutsch zuerst und Englisch danach.
- Methodik v2 nutzt Git-getrackten Text und Bruttoänderungen aus Nicht-Merge-Commits; Ledger, `STATS.md` und Binärdaten bleiben ausgeschlossen.
- Manuelle Referenz-Basiswerte: `80` Zeilen/Arbeitstag (konservative Untergrenze) sowie ein projektspezifischer Thorsten-Solo-Wert, konsistent dokumentiert in `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` und `.github/copilot-instructions.md`.
- Für diesen C++-Kompatibilitätsfork gilt konservativ `80` Zeilen/Arbeitstag auch als Thorsten-Solo-Referenz; ein eigener C++-Speedup wird erst nach einer begründeten Neufestlegung behauptet.
- Beim Umrechnen in Stunden: `7.8` Stunden (`7h 48m`) pro Arbeitstag (TVöD-Basis).
- Beim Umrechnen in Monate: `21.5` Arbeitstage/Monat; Urlaubstage 30 Tage bis Ende 2026, ab 2027 dann 31 Tage (TVöD, 5-Tage-Woche).
- Beschleunigungsfaktoren vergleichen die manuelle Referenz gegen sichtbare Git-Aktivtage — blended repository speedup, keine Stoppuhrmessung.
- Wenn gemeinsame Agenten-Guidance oder Statistikmethodik geändert wird: alle fünf Agentenflächen einschließlich `.github/agents/copilot-instructions.md` zusammen aktualisieren.

*Maintain `docs/project-statistics.md` as the living ledger and render Profile 2 from its JSON configuration. Use ASCII `0..4`, `-`, and `#`/`.` gauges, exact values, bilingual text alternatives, stable phase slots in blocks of 16, and a 100-character chart limit. Methodology v2 excludes the ledger, `STATS.md`, and binaries. Acceleration remains delivery density, not stopwatch time.*

## Hinweise / Notes

- Keine ANSI-Farbcodes in Skript-Output
- Keine leeren Alt-Texte in Bildern
- Heading-Hierarchie ohne Lücken einhalten
- `Programmierung #include<everyone>` gilt für alle nutzerseitigen Artefakte: CLI-Ausgaben, Doku, HTML, UI und generierte Templates.
- WCAG 2.2 Level AA ist die Standard-Basis, sobald die Kriterien auf das Artefakt anwendbar sind.
- Nach vollständig beendeten Python-Testläufen dürfen regenerierbare `__pycache__/`-Verzeichnisse und `*.pyc`-, `*.pyo`- und `*.pyd`-Dateien entfernt werden; niemals löschen, solange ein zugehöriger Python-Prozess noch läuft.
- Shared guidance wird immer gemeinsam in `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` und `.github/agents/copilot-instructions.md` gepflegt.

- No ANSI color codes in script output
- No empty alt texts in images
- Maintain heading hierarchy without gaps
- `Programmierung #include<everyone>` applies to all user-facing artefacts: CLI output, docs, HTML, UI, and generated templates.
- WCAG 2.2 Level AA is the default baseline wherever the criteria apply.
- After Python test runs have fully finished, regenerable `__pycache__/` directories and `*.pyc`, `*.pyo`, and `*.pyd` files may be removed; never delete them while a related Python process is still running.
- Keep shared guidance synchronized across `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, and `.github/agents/copilot-instructions.md`.

## GitHub/GitLab CLI First / GitHub/GitLab CLI zuerst

Für GitHub-Repositories zuerst die authentifizierte `gh` CLI für mögliche Schreibaktionen und Live-Repository-Operationen verwenden, einschließlich PR-/Issue-Kommentaren, PR-Statusprüfungen, Review-Follow-up, Workflow-Prüfung und Merge-/Statusabfragen. GitHub-Connector-Tools hauptsächlich für strukturierte Read-only-Inspektion oder Fälle nutzen, in denen die CLI nicht geeignet ist.

Für GitLab-Repositories die authentifizierte `glab` CLI zuerst für gleichwertige Aktionen verwenden. Bekanntermaßen fehlschlagende Connector-Schreibwege nicht wiederholt versuchen, wenn `gh`/`glab` die Aufgabe direkt erledigen kann.

For GitHub repositories, use the authenticated `gh` CLI first for feasible write actions and live repository operations, including PR/issue comments, PR status checks, review follow-up, workflow inspection, and merge/status queries. Use GitHub connector tools mainly for structured read-only inspection or when the CLI is not suitable.

For GitLab repositories, use the authenticated `glab` CLI first for equivalent actions. Do not repeatedly try connector write paths that are known to fail when `gh`/`glab` can perform the task directly.

## Skriptreferenz und Quellpfad / Script Reference and Source Path

Die Skriptinventur steht unter `docs/scripts/`. Vor schreibenden Laeufen Hilfe
und Preview verwenden. Die Level-0-Quelle ueber den gemeinsamen Resolver
ermitteln und nicht als absoluten Pfad fest eincodieren.

*The script inventory lives under `docs/scripts/`. Read help and preview before
writing. Resolve Level 0 through the shared contract; do not hard-code it.*

## Dokumentationsauswirkung / Documentation Impact

Jede Änderung erhält genau eine Entscheidung: `UpdateRequired`,
`NoUpdateRequired`, `GeneratedUpdate` oder `FollowUp`. Quelle, Owner,
Dokumente und Evidence richten sich nach `docs/documentation-governance.md`.
`FollowUp` benötigt Owner, Risiko, Frist, Trigger, Evidence und Scope-Grund.

*Every change records exactly one Documentation Impact decision. Follow the
source, ownership, generated-output, and evidence contract in
`docs/documentation-governance.md`.*

## Lernreihen-Governance / Learning Series Governance

Neue Lernreihen fuer Fachinformatiker*innen und weitere IT-Ausbildungsberufe werden zuerst in `docs/learning-units/` als Level-0-Quelle vorbereitet. Der `Lernreihen-Blueprint`, das `Lernreihen-Register`, das IT-Berufe-Mapping und die Vorlagen unter `docs/learning-units/templates/` sind verbindlich, bevor eine konkrete Level-1-/Level-2-Struktur gespiegelt wird. KI-Agenten duerfen Lernreihen, Lastenhefte, Berufsbild-Mappings, Reihenfolgen und ZIP-Paketierung vorbereiten, starten aber keine Spec-Kit-Laeufe fuer Lernende ohne ausdruecklichen Auftrag. Spec-Kit-Laeufe sind begleitende SDD-Aufgaben und ersetzen nicht Berufsschule, betriebliche Ausbildung, Rahmenlehrplan, Ausbilderentscheidung oder Pruefungsvorbereitung.

*New learning series for IT specialist apprentices and additional IT training occupations are prepared first in `docs/learning-units/` as the level-0 source. The Learning Series Blueprint, Learning Series Register, IT occupation mapping, and templates under `docs/learning-units/templates/` are binding before a concrete level-1/level-2 structure is mirrored. AI agents may prepare learning series, intake files, occupation mappings, ordering, and ZIP packaging, but must not start learner Spec Kit runs without an explicit instruction. Spec Kit runs are companion SDD tasks and do not replace vocational school, workplace training, the curriculum, instructor decisions, or exam preparation.*

## Spec-Kit-Modell-Routing / Spec Kit Model Routing

- Modellwahl ist operative Agenten-Routing-Guidance, keine Feature-Anforderung. Modellnamen nicht in `spec.md`, `plan.md`, `tasks.md` oder einzelne Feature-Specs schreiben; diese Artefakte muessen reproduzierbar bleiben, auch wenn Modellnamen wechseln oder ein anderer KI-Agent verwendet wird.
- Der jeweilige Agent soll diese Empfehlungen auf seine aktuell verfuegbaren Modelle abbilden; keine feste Anbieter- oder Modellbindung ableiten.
- Fuer Spec-Kit-Spezifikation, Klaerung, Planung, Tasks und Analyse (`/speckit-specify`, `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-analyze`; je nach Agent auch `/speckit.specify` usw.) das staerkste verfuegbare Frontier-Reasoning-/Coding-Modell bevorzugen.
- Fuer vollstaendige, lang laufende `/speckit-implement`-Laeufe das staerkste verfuegbare Long-Running-Agent-Modell bevorzugen; das Frontier-Modell nutzen, wenn maximale Urteilsguete wichtiger ist als Laufzeitstabilitaet.
- Fuer fokussierte Reviews oder CI-Fixes ein coding-optimiertes Modell bevorzugen.
- Fuer triviale Bereinigung, Formatierung oder risikoarme mechanische Edits ist ein schnelles kleines Coding-Modell akzeptabel.
- Die stabilen operativen Rollen heissen `frontier-reasoning`, `long-running-implementation`, `coding-review`, `fast-mechanical` und `script-only`. Installierte Presets deklarieren ihre Kommandos in `model-routing.json`; bei mehreren Wrappern gewinnt die staerkste Rolle.
- Intake-Create/Update/Delete, Intake-Review/Repair, Sequencing-Create/Update/Delete sowie Specify/Clarify/Plan/Tasks/Analyze verwenden `frontier-reasoning`. Read/Status/Next duerfen `fast-mechanical` verwenden; Stop und deterministische Validatoren bleiben `script-only`.
- Ein nicht-paralleler autonomer Lauf darf Modelle nur an einer validierten Phasengrenze wechseln. Jede Phase startet einen neuen Prozess, bindet ihr Handoff per SHA-256 und schreibt Profil, Modell und Reasoning-Aufwand in den Run-State.
- Lokale Runner-Profile muessen `fail-closed` arbeiten. Fehlendes Profil, Modell, Reasoning oder erfolgreicher Preflight fuehrt zu `Blocked`; kein stiller Fallback.

*Model choice is operational agent-routing guidance, not a feature requirement. Do not pin model names in `spec.md`, `plan.md`, `tasks.md`, or individual feature specs. Stable roles are `frontier-reasoning`, `long-running-implementation`, `coding-review`, `fast-mechanical`, and `script-only`. Installed presets declare command roles in `model-routing.json`; the strongest applicable wrapper role wins. Semantic intake and Spec-Kit decisions use frontier reasoning, read/status/next may use fast mechanical routing, and stop plus deterministic validators remain script-only. A non-parallel autonomous run changes models only at a validated phase boundary through a new process and SHA-256-bound handoff. Local profiles fail closed: missing profile, model, effort, or successful preflight results in `Blocked`, never a silent fallback.*

<!-- learner-a11y-baseline:start -->
## Hinweise zur Lernenden- und A11Y-Basis / Notes on the Learner and A11Y Baseline

- Inhalte richten sich ab dem ersten Ausbildungsjahr an Fachinformatiker*innen,
  Kaufleute für IT-System-Management und Kaufleute für
  Digitalisierungsmanagement.
- Sie müssen Deutsch zuerst und Englisch danach, ohne Spec-Kit-Vorkenntnisse,
  auf CEFR-B2-Niveau und ohne ausschließlich visuelle
  Abhängigkeitsdarstellung verständlich sein. Fachbegriffe werden beim ersten
  Auftreten erklärt; WCAG 2.2 Level AA ist die anwendbare Prüfbasis.

*Content targets IT specialist apprentices and both IT management occupations
from their first training year. It is German-first/English-second at CEFR B2,
explains technical terms at first use, assumes no prior Spec Kit experience,
never relies on visual-only dependency information, and uses WCAG 2.2 Level AA
as the applicable review baseline.*
<!-- learner-a11y-baseline:end -->

<!-- EN: AGENTS.md contains bilingual agent guidance for this level-2 project. -->

<!-- BEGIN spec-kit-diagrams-completion -->
## Mermaid und Spec-Kit-Abschlussbericht / Mermaid and Spec Kit completion report

Neue Lastenhefte enthalten bei hilfreichen Abläufen, Zuständen oder Abhängigkeiten
lesbaren Mermaid-Quelltext im Markdown und eine gleichwertige Textalternative.
Bei einfachen Inhalten die Nichtanwendung kurz begründen. Diagramme bilden die
verbindlichen Text-/Manifestquellen ab; Farbe allein trägt keine Bedeutung.
Nach jedem vollständig abgeschlossenen Spec-Kit-Feature-Lauf den vollständigen
Ergebnisbericht im Chat anzeigen und im Feature-Verzeichnis als
`completion-report.md` versionieren. Einzelne Planungs-/Status-/Review-Kommandos
lösen keinen solchen Bericht aus; blockierte oder pausierte Läufe als
Zwischenbericht kennzeichnen. Vorlage: `.specify/templates/completion-report-template.md`;
Regel: `docs/spec-kit-diagrams-and-completion-reports.md`.
Ergebnis, Tests, Dokumentation, Git-gebundene Umfangszahlen, Verlauf und Restpunkte
belegen. Programmlogik von generierter Evidence, Git-Wandzeit von aktiver
Arbeitszeit und bestandene von ausgefallenen Prüfungen unterscheiden. Finale
Merge-/Sync-Evidence im Chat und bestehenden Closeout-Nachweis ergänzen; keine
zusätzlichen Commits allein für selbstreferenzielle Berichts-/Statistikwerte.
Diese Projektregel und lokale Vorlagen bei Spec-Kit-Updates erhalten.

*New intakes use readable Mermaid Markdown and equivalent text alternatives for
useful workflows, states or dependencies; justify omission for simple content.
Diagrams reflect authoritative text/manifests and never rely on color alone.
After each completed feature run, show the full outcome report in chat and
version completion-report.md in the feature directory using the shared template
and rule above. Individual planning/status/review commands do not trigger it;
paused/blocked runs receive interim reports. Evidence outcomes, tests, docs,
Git-bound counts, delivery history and remaining work. Distinguish code from
volume generated as evidence, elapsed from active time, and passed from failed
checks. Add final merge/sync proof in chat and existing closeout evidence, without
commits solely for self-referential counts or IDs. Preserve local rules/templates
across Spec Kit updates.*
<!-- END spec-kit-diagrams-completion -->

<!-- project-statistics-rollout:begin -->
## Statistik-Preset und Pflege / Statistics preset and maintenance

Das aktuelle Projektprofil ist `project-statistics-fourteen-governance-presets`:
bestehende 12er-Basis plus Assurance v0.1.3 bei Prioritaet 15 und Statistik
v0.1.0 bei Prioritaet 90. Dieser Projektvertrag hat Vorrang vor alten Profilangaben. Globale Defaults
bleiben erhalten; die operative lokale Zuordnung folgt erst nach Lieferung.
`docs/project-statistics/config.json` steuert den getrennten UTC-/52-Wochen-Kontext.
Profil 2 bleibt kanonisch; Referenzmodelle im neuen Kontext bleiben aus.
Nach abgeschlossenem Feature/Implementierungsabschnitt Inhalte zuerst committen,
Update ausdruecklich beauftragen und vorab im Dry-Run pruefen. Beide Statistiken
aus derselben Inhaltsrevision pflegen, Ausgaben committen und lesend verifizieren.
Keine Personen-, Lernleistungs-, Qualitaets-, Sicherheits- oder KI-Produktivitaetsbewertung.
Bedienung: `docs/project-statistics/README.md`; Quellen und Abnahme:
`docs/maintenance/project-statistics-rollout-v010.md`. Kein automatischer
Spec-Kit-Lauf und keine Commit-/Push-/Merge- oder menschliche Freigabe durch das Preset.

The current profile adds assurance v0.1.3 at priority 15 and statistics v0.1.0
at priority 90 to the unchanged twelve-preset base. This overrides older profile guidance. Preserve global defaults and defer operational assignment
until delivery. Keep legacy Profile 2 authoritative; use the separate UTC context
with reference models disabled. After feature/implementation completion, commit
content first, preview an expressly authorized update, render both contexts,
commit outputs and verify read-only status. Statistics do not rate people,
learning, quality, security or AI productivity. See the repository-relative
usage and rollout records. Installation grants no feature or delivery authority.
<!-- project-statistics-rollout:end -->
