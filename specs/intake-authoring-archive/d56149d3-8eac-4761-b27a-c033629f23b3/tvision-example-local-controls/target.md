<!-- intake-authoring:begin -->
# Beispieleigene tvision-Steuerelemente / tvision example-local controls

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Die Lernziele Fortschrittsanzeige, scrollbarer Dialog und Combo-Box werden ohne vorschnelle Erweiterung der öffentlichen Bibliotheks-API demonstriert.

*English:* Demonstrate progress indicator, scrollable dialog, and combo-box learning goals without prematurely extending the public library API.

## Ausgangslage / Current State

Aktuelle öffentliche Header enthalten keine passenden `TProgressBar`-, `TScrollGroup`- oder `TComboBox`-Typen.

*English:* Current public headers do not provide corresponding `TProgressBar`, `TScrollGroup`, or `TComboBox` types.

## Zielbild / Target State

Die Targets `progress`, `scrolldlg` und `combobox` verwenden ausschließlich examplespezifische Hilfstypen und etablierte tvision-Basisklassen.

*English:* Targets `progress`, `scrolldlg`, and `combobox` use example-specific helper types and established tvision base classes only.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Keine öffentliche API-Erweiterung.
2. Kein generisches Widget-Framework.
3. Keine historische Quelltextübernahme.

### English

1. No public API extension.
2. No generic widget framework.
3. No historic source-code reuse.

## Anforderungen / Requirements

### Deutsch

1. `progress` führt `progba` und `tprogb` zu einer bestimmten und abbrechbaren Fortschrittsdarstellung zusammen.
2. `scrolldlg` führt `sdlg` und `sdlg2` zusammen und zeigt ein- sowie zweiachsiges Scrollen und Größenänderung.
3. `combobox` zeigt Auswahl, Texteingabe, Tastaturnavigation, Fokus und leere Ergebnislisten.
4. Alle neuen Hilfsklassen bleiben unter `examples/` und werden nicht aus öffentlichen Headern exportiert.
5. Jedes Target erhält `--smoke`, isolierte Zustandslogiktests und bilinguale Dokumentation.

### English

1. `progress` consolidates `progba` and `tprogb` into determinate and cancellable progress behavior.
2. `scrolldlg` consolidates `sdlg` and `sdlg2` and demonstrates one- and two-axis scrolling plus resizing.
3. `combobox` demonstrates selection, text input, keyboard navigation, focus, and empty result lists.
4. All new helper classes remain under `examples/` and are not exported from public headers.
5. Every target receives `--smoke`, isolated state-logic tests, and bilingual documentation.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Bindender Vorgänger sind die abgenommenen Kern-Lernbeispiele.

*English:* The accepted core learning examples are a binding predecessor.

**Risiko / Risk:** Beispielhilfen könnten versehentlich zu produktionsreifen öffentlichen Komponenten erklärt werden. Dokumentation und Namespaces müssen ihren lokalen Lehrzweck klar begrenzen.

*English:* Example helpers could accidentally be presented as production-ready public components. Documentation and namespaces must clearly bound their local teaching purpose.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `examples/progress`
- `examples/scrolldlg`
- `examples/combobox`
- `examples/CMakeLists.txt`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Drei Targets und ihre Tests bauen in der modernen Plattformmatrix.
2. Mauslose Bedienung und sichtbarer Fokus sind nachgewiesen.
3. Öffentliche Header und ABI bleiben unverändert.
4. Historische Doppelvarianten erzeugen keine zusätzlichen Programme.

### English

1. Three targets and their tests build in the modern platform matrix.
2. Mouse-free operation and visible focus are evidenced.
3. Public headers and ABI remain unchanged.
4. Historic duplicate variants do not create extra programs.

## Berechtigung und Admin-Bypass / Authority and Admin Bypass

Thorsten hat für diesen Intake `MergeAndSync` ausdrücklich autorisiert. Dies umfasst den beabsichtigten Commit, Push, Pull Request, die Konvergenz von Reviews und technischen Checks, den Merge sowie die Fast-Forward-Synchronisation des lokalen Default-Branches.

Der Admin-Bypass ist ausschließlich für den konkreten, aus diesem Intake entstehenden Pull Request und nur für die Branch-Protection- oder Ruleset-Sperre erlaubt, die einen ansonsten technisch belegten Merge verhindert. Er ersetzt niemals fehlgeschlagene Tests, fehlende Pflichtreviews oder Exact-Head-Evidenz. Vor dem Bypass müssen Autorisierer, konkreter PR, Policy, Grund und Restrisiko erneut erfasst werden. Provider-Administration, Secret-Änderungen, Check-Abbruch und der Start eines Folge-Intakes sind nicht umfasst.

*English:* Thorsten explicitly authorized `MergeAndSync` for this intake. The Admin Bypass is limited to the concrete pull request produced by this intake and only to a branch-protection or ruleset restriction blocking an otherwise technically proven merge. It never replaces failed tests, required reviews, or exact-head evidence. Authorizer, concrete PR, policy, rationale, and residual risk must be recorded again immediately before bypass. Provider administration, secret changes, check cancellation, and starting a successor intake are excluded.

## Annahmen und offene Fragen / Assumptions and Open Questions

Alle materiellen Entscheidungen `IAD001` bis `IAD008` sind beantwortet. Es bestehen keine offenen Intake-Authoring-Fragen. Die Serienreihenfolge erteilt keine automatische Berechtigung zum Start dieses oder eines nachfolgenden Spec-Kit-Laufs.

*English:* All material decisions `IAD001` through `IAD008` are answered. No intake-authoring question remains open. Series order does not automatically authorize starting this or a successor Spec Kit run.

<!-- intake-authoring:prompts -->
## Kopierfertige Spec-Kit-Prompts / Copy-Ready Spec Kit Prompts

<!-- spec-kit-command-id: speckit.specify -->
### Specify

```text
$speckit-specify
Nutze intakes/tvision-example-local-controls.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-example-local-controls.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
