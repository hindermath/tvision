# Intake-Abarbeitungsreihenfolge / Intake Processing Order

## Zielgruppe und Voraussetzungen / Audience and Prior Knowledge

Diese Reihenfolge richtet sich an C/C++-Lernende, Maintainer und Reviewer mit C++14- und CMake-Grundlagen. Spec-Kit-Erfahrung wird nicht vorausgesetzt. Deutsch steht zuerst, Englisch folgt; die Formulierungen zielen auf CEFR B2.

This order is for C/C++ learners, maintainers, and reviewers with C++14 and CMake basics. No Spec Kit experience is assumed. German comes first, followed by English, at CEFR B2 readability.

## Begriffe / Terms

- **Intake:** verbindliche Anforderungsquelle für ein Arbeitspaket. / Binding requirements source for one work package.
- **Serie:** geordnete Gruppe vorhandener Intakes. / Ordered group of existing intakes.
- **DAG:** gerichteter, kreisfreier Abhängigkeitsgraph. / Directed acyclic dependency graph.
- **Root:** Intake ohne eingehende Kante. / Intake without an incoming edge.
- **Bindende Kante:** Der Vorgänger muss `Completed` sein. / The predecessor must be `Completed`.
- **Serialisierung:** Eine nicht bindende Kante koordiniert gemeinsame Schreibflächen oder die bevorzugte Reihenfolge. / A non-binding edge coordinates shared write surfaces or preferred order.
- **Eligible:** Reihenfolgenevidenz für einen aktuell auswählbaren Intake; keine Start-, Implementierungs- oder Remote-Berechtigung. / Ordering evidence for a currently selectable intake; not start, implementation, or remote authority.

## Status und Entscheidungen / Status and Decisions

- Serienstatus / Series status: `Active`
- Einzige Root / Only root: `intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md`
- Aktuell einziger Kandidat / Current sole candidate: dieselbe Root mit `Eligible` / the same root with `Eligible`
- Alle anderen Ziele sind `Blocked`, bis ihre bindenden Vorgänger `Completed` sind.
- Der Graph, die Kantenarten und Bindungsflags werden unverändert aus der genehmigten Authoring-Serie übernommen.
- Die Erstellung dieser Serie startet keinen Review, keine Spezifikation, keine Implementierung und keine Remote-Aktion.

- Every other target is `Blocked` until its binding predecessors are `Completed`.
- The graph, edge types, and binding flags are reused unchanged from the approved authoring series.
- Creating this series starts no review, specification, implementation, or remote action.

## Reihenfolge / Order

| Position | Intake | Rolle / Role | Status | Zweck / Purpose |
|---:|---|---|---|---|
| 1 | `intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md` | Primary/Root | Eligible | Inventar, Dublettengrenze und Clean-Room-Basis / Inventory, duplicate boundary, and clean-room baseline |
| 2 | `intakes/tvision-core-learning-examples.md` | OrderedMember | Blocked | Zentrale Lernbeispiele / Core learning examples |
| 3 | `intakes/tvision-example-local-controls.md` | OrderedMember | Blocked | Beispieleigene Steuerelemente / Example-local controls |
| 4 | `intakes/tvision-dialog-designer-example.md` | OrderedMember | Blocked | Dialogdesigner / Dialog designer |
| 5 | `intakes/tvision-file-manager-sandbox.md` | OrderedMember | Blocked | Sicherer Sandbox-Dateimanager / Safe sandbox file manager |
| 6 | `intakes/tvision-file-manager-user-roots.md` | OrderedMember | Blocked | Gewählte Benutzerwurzel / Selected user root |
| 7 | `intakes/tvision-documentation-toolchain-and-ci-artifact.md` | OrderedMember | Blocked | HTML-Dokumentationswerkzeuge und CI-Artefakt / HTML documentation tooling and CI artifact |
| 8 | `intakes/tvision-bilingual-core-handbook.md` | OrderedMember | Blocked | Zweisprachiges Kernhandbuch / Bilingual core handbook |
| 9 | `intakes/tvision-complete-handbook-and-github-pages.md` | OrderedMember | Blocked | Vollständiges Handbuch und Veröffentlichung / Complete handbook and publication |
| 10 | `intakes/tvision-example-documentation-final-audit.md` | OrderedMember | Blocked | Abschlussaudit / Final audit |

## Abhängigkeiten / Dependencies

Die folgende Textliste ist normativ. `binding=true` verlangt den Abschluss des Vorgängers; `binding=false` serialisiert nur.

The following text list is normative. `binding=true` requires predecessor completion; `binding=false` only serializes work.

1. Position 1 → 2: `HardCompletionGate`, `binding=true`.
2. Position 2 → 3: `HardCompletionGate`, `binding=true`.
3. Position 3 → 4: `HardCompletionGate`, `binding=true`.
4. Position 2 → 5: `HardCompletionGate`, `binding=true`.
5. Position 4 → 5: `SharedWriterSerialization`, `binding=false`.
6. Position 5 → 6: `SandboxBaseline`, `binding=true`.
7. Position 1 → 7: `DocumentationSurfaceBaseline`, `binding=true`.
8. Position 6 → 7: `PreferredSerialOrder`, `binding=false`.
9. Position 2 → 8: `HardCompletionGate`, `binding=true`.
10. Position 3 → 8: `HardCompletionGate`, `binding=true`.
11. Position 5 → 8: `HardCompletionGate`, `binding=true`.
12. Position 7 → 8: `DocumentationSurfaceBaseline`, `binding=true`.
13. Position 4 → 9: `HardCompletionGate`, `binding=true`.
14. Position 6 → 9: `HardCompletionGate`, `binding=true`.
15. Position 8 → 9: `DocumentationSurfaceBaseline`, `binding=true`.
16. Position 9 → 10: `FinalAuditInput`, `binding=true`.

## Blocker / Blockers

| Position | Bindende, noch nicht abgeschlossene Vorgänger / Binding incomplete predecessors |
|---:|---|
| 1 | Keine / None |
| 2 | 1 |
| 3 | 2 |
| 4 | 3 |
| 5 | 2; Position 4 ist nur Serialisierung / position 4 is serialization only |
| 6 | 5 |
| 7 | 1; Position 6 ist nur bevorzugte Reihenfolge / position 6 is preferred order only |
| 8 | 2, 3, 5, 7 |
| 9 | 4, 6, 8 |
| 10 | 9 |

## Evidenz / Evidence

- Genehmigter Ausgangsgraph / Approved source graph: `specs/intake-authoring-series/tvision-examples-and-documentation/series.json`
- Aktueller vollständiger Review / Current full review: `specs/intake-review-results/tvision-examples-and-documentation/2026-08-13-series-review-result-v2.json` (`Ready`)
- Reparaturnachweis / Repair evidence: `specs/intake-review-repairs/tvision-examples-and-documentation/2026-08-13-repair-record.json`
- Zielhash-Provenienz / Target-hash provenance: zehn Dateien unter / ten files under `specs/intake-authoring-receipts/`

## Nächste Aktion / Next Action

`$speckit-intake-series-status specs/intake-series/tvision-examples-and-documentation/manifest.json`

Dieser read-only Statuslauf prüft die Serie, startet aber keinen Intake. / This read-only status run validates the series but starts no intake.
