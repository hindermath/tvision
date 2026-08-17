# Lastenheft-Abarbeitungsreihenfolge / Requirements Processing Order

Diese Datei haelt die sichtbare Abarbeitungsreihenfolge der vorhandenen Lastenhefte fest. Sie ist eine Vorbereitung fuer spaetere Spec-Kit-Laeufe und startet selbst keinen Lauf.

*This file records the visible processing order of existing requirements documents. It prepares later Spec Kit runs and does not start a run by itself.*

<!-- secure-development-hardening-order:start -->
## Automatisch ermittelte Lastenheft-Reihenfolge / Automatically Detected Requirements Order

Diese Tabelle wird aus `Lastenheft*.md` im Repository-Root erzeugt. Sie ist eine Vorbereitung fuer spaetere Spec-Kit-Laeufe und startet selbst keinen Lauf. Manuelle Projektentscheidungen ausserhalb dieses markierten Abschnitts bleiben erhalten.

*This table is generated from `Lastenheft*.md` in the repository root. It prepares later Spec Kit runs and does not start a run. Manual project decisions outside this marked section remain preserved.*

| Rang | Lastenheft | Gruppe | Status |
|---:|---|---|---|
| 1 | `Lastenheft_RL-SE-Checklist-Selbstpruefung.md` | RL-SE-/Checklist-Selbstpruefung | aktiv / active |
<!-- secure-development-hardening-order:end -->

## Manuelle Intake-Serie: tvision-Beispiele und Dokumentation / Manual Intake Series: tvision Examples and Documentation

Der vorhandene RL-SE-/Checklist-Selbstpruefungs-Intake bleibt in der sichtbaren
Gesamtreihenfolge zuerst. Er ist gemaess Entscheidung `IAD001` kein bindender
Vorgaenger dieser neuen Serie. Die folgenden Ziele stehen auf
`ReadyForReview`; diese Tabelle startet weder Intake Review noch Specify,
Autonomous oder Implementierung.

*The existing RL-SE/checklist self-assessment intake remains first in the
visible overall order. Under decision `IAD001`, it is not a binding predecessor
of this new series. The following targets are `ReadyForReview`; this table does
not start Intake Review, Specify, Autonomous, or implementation.*

| Rang | Intake | Rolle | Status |
|---:|---|---|---|
| 1 | `intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md` | Root / Grundlage | `ReadyForReview` |
| 2 | `intakes/tvision-core-learning-examples.md` | Kernbeispiele | `ReadyForReview` |
| 3 | `intakes/tvision-example-local-controls.md` | Beispieleigene Controls | `ReadyForReview` |
| 4 | `intakes/tvision-dialog-designer-example.md` | Dialogdesigner | `ReadyForReview` |
| 5 | `intakes/tvision-file-manager-sandbox.md` | Sichere Sandbox | `ReadyForReview` |
| 6 | `intakes/tvision-file-manager-user-roots.md` | Benutzerwurzeln | `ReadyForReview` |
| 7 | `intakes/tvision-documentation-toolchain-and-ci-artifact.md` | Dokumentationswerkzeuge | `ReadyForReview` |
| 8 | `intakes/tvision-bilingual-core-handbook.md` | Kernhandbuch | `ReadyForReview` |
| 9 | `intakes/tvision-complete-handbook-and-github-pages.md` | Vollstaendiges Handbuch und Pages | `ReadyForReview` |
| 10 | `intakes/tvision-example-documentation-final-audit.md` | Abschlusspruefung | `ReadyForReview` |

Die maschinenpruefbare Reihenfolge, Quellenabdeckung und der DAG stehen unter
`specs/intake-authoring-series/tvision-examples-and-documentation/`. Ein
operatives Sequencing-Manifest wird erst nach einem separat beauftragten und
erfolgreichen Series Review angelegt.

*The machine-checkable order, source coverage, and DAG live under
`specs/intake-authoring-series/tvision-examples-and-documentation/`. An
operational sequencing manifest is created only after a separately authorized
and successful Series Review.*

## Nachgelagertes Open-Watcom-DOS/DPMI-Portierungsprojekt / Downstream Open Watcom DOS/DPMI Porting Project

Dieses Vorhaben ist als eigene Authoring-Serie am Ende der sichtbaren
Reihenfolge vorgemerkt. Beide Intakes stehen auf `ReadyForReview`; ihre
operative Aktivierung bleibt `Pending`, bis die aktive Serie
`tvision-examples-and-documentation` abgeschlossen ist. Diese Einordnung
aendert deren Manifest, Receipt, Root, Kanten oder `Eligible`-Ziel nicht und
startet weder Review noch Specify, Autonomous oder Implementierung.

*This project is recorded as a separate authoring series at the end of the
visible order. Both intakes are `ReadyForReview`; operational activation stays
`Pending` until the active `tvision-examples-and-documentation` series is
complete. This placement changes none of that series' manifest, receipt, root,
edges, or `Eligible` target and starts no review, Specify, Autonomous, or
implementation.*

| Rang | Intake | Rolle | Authoring-Status | Operativer Status |
|---:|---|---|---|---|
| 1 | `intakes/tvision-open-watcom-dos-dpmi-feasibility.md` | Root / Machbarkeitspruefung | `ReadyForReview` | `Pending` |
| 2 | `intakes/tvision-open-watcom-dos-dpmi-ci-migration.md` | OrderedMember / bedingte Migration | `ReadyForReview` | `Pending`, durch `AssessmentBaseline` und dokumentiertes `Go` blockiert |

Die Authoring-Serie, Quellenabdeckung und bindende Kante stehen unter
`specs/intake-authoring-series/tvision-open-watcom-dos-dpmi-port/`. Ein
spaeteres Sequencing-Manifest darf erst nach Series Review, Abschluss der
aktiven Vorgaengerserie und ausdruecklicher Sequencing-Autoritaet entstehen.

*The authoring series, source coverage, and binding edge live under
`specs/intake-authoring-series/tvision-open-watcom-dos-dpmi-port/`. A later
sequencing manifest requires Series review, completion of the active preceding
series, and explicit sequencing authority.*

**Naechste Aktion / Next action:**
`$speckit-intake-review specs/intake-authoring-series/tvision-open-watcom-dos-dpmi-port/intake-review-request.json`
