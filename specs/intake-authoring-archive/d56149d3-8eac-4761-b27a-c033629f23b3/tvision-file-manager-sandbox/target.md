<!-- intake-authoring:begin -->
# tvision-Dateimanager in einer Sandbox / tvision file manager sandbox

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Das wesentliche Lernziel des Pascal-Programms `TVFM` wird zuerst in einer kontrollierten temporären Dateisystemgrenze neu umgesetzt.

*English:* Reimplement the essential learning intent of the Pascal `TVFM` program first within a controlled temporary filesystem boundary.

## Ausgangslage / Current State

`tvdir` demonstriert Navigation, aber keinen zusammenhängenden sicheren Dateimanager mit schreibenden Operationen.

*English:* `tvdir` demonstrates navigation but not a coherent safe file manager with write operations.

## Zielbild / Target State

Das Target `tvfm` erzeugt bei jedem Start eine neue temporäre Sandbox aus eigenen Fixtures und erlaubt ausschließlich darin Navigation, Anzeige, Suche, Kopieren, Umbenennen und bestätigtes Löschen.

*English:* Target `tvfm` creates a new temporary sandbox from original fixtures on every start and allows navigation, viewing, search, copy, rename, and confirmed deletion only within it.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Keine beliebige Benutzerwurzel.
2. Keine Shell, Dateizuordnung, Drag-and-drop oder Hostpapierkorb-Integration.
3. Keine Wiederverwendung historischer Ressourcen.

### English

1. No arbitrary user root.
2. No shell, file association, drag-and-drop, or host-trash integration.
3. No reuse of historic resources.

## Anforderungen / Requirements

### Deutsch

1. Erzeuge die Sandbox bei jedem normalen Start neu und zeige ihren Pfad verständlich an.
2. Biete Verzeichnisliste, Metadaten, Text-/Hex-Vorschau und begrenzte Suche.
3. Kopieren, Umbenennen und Löschen dürfen die kanonische Sandbox-Wurzel nicht verlassen.
4. Umbenennen und Löschen benötigen eine eindeutige Bestätigung; Abbruch verändert nichts.
5. Behandle Namenskollisionen, nicht lesbare Dateien, fehlerhafte Kodierung und verschwindende Dateien ohne Absturz.
6. Verwende C++14 und getrennte, testbare Pfadlogik statt `std::filesystem`.
7. Der `--smoke`-Modus arbeitet ausschließlich mit einem temporären Test-Fixture.

### English

1. Create a fresh sandbox for every normal start and display its path understandably.
2. Provide directory listing, metadata, text/hex preview, and bounded search.
3. Copy, rename, and delete must not leave the canonical sandbox root.
4. Rename and delete require unambiguous confirmation; cancellation changes nothing.
5. Handle name collisions, unreadable files, invalid encoding, and disappearing files without crashing.
6. Use C++14 and separate testable path logic instead of `std::filesystem`.
7. The `--smoke` mode operates only on a temporary test fixture.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Die Kern-Lernbeispiele sind bindend. Der Dialogdesigner serialisiert nur gemeinsame Schreibflächen und ist keine fachliche Voraussetzung.

*English:* Core learning examples are binding. The dialog designer only serializes shared write surfaces and is not a functional prerequisite.

**Risiko / Risk:** Dateioperationen sind destruktiv. Die temporäre Wurzel, kanonische Prüfung und Negativtests sind harte Gates.

*English:* File operations are destructive. The temporary root, canonical validation, and negative tests are hard gates.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `examples/tvfm`
- `test/example-fixtures/tvfm`
- `examples/CMakeLists.txt`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Kein Test und keine UI-Operation schreibt außerhalb der temporären Wurzel.
2. Traversal-, Symlink-, Kollisions-, Abbruch- und Bestätigungsfälle bestehen.
3. Die Sandbox wird reproduzierbar aufgebaut und nach kontrolliertem Ende bereinigt.
4. Linux, macOS und Windows bauen und testen die Pfadlogik.

### English

1. No test or UI operation writes outside the temporary root.
2. Traversal, symlink, collision, cancellation, and confirmation cases pass.
3. The sandbox is built reproducibly and cleaned after controlled termination.
4. Linux, macOS, and Windows build and test the path logic.

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
Nutze intakes/tvision-file-manager-sandbox.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-file-manager-sandbox.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
