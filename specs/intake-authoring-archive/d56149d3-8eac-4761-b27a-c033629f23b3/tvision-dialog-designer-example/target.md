<!-- intake-authoring:begin -->
# tvision-Dialogdesigner-Beispiel / tvision dialog designer example

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Ein begrenzter, sicherer Dialogdesigner überträgt das Lernziel von `dlgdsn` auf aktuelle tvision-APIs.

*English:* A bounded, safe dialog designer transfers the learning intent of `dlgdsn` to current tvision APIs.

## Ausgangslage / Current State

Das historische Werkzeug steht unter einer inkompatiblen beziehungsweise zu prüfenden Lizenz und erzeugt alten C++-Stil. Eine aktuelle Alternative fehlt.

*English:* The historic tool uses an incompatible or review-required license and generates old-style C++. A current alternative is missing.

## Zielbild / Target State

Das Target `dlgdsn` entwirft begrenzte Dialoge, zeigt eine Vorschau und exportiert reproduzierbaren C++14-Quelltext, ohne ihn auszuführen.

*English:* Target `dlgdsn` designs bounded dialogs, previews them, and exports reproducible C++14 source without executing it.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Kein allgemeiner Formulardesigner.
2. Kein Import oder Ausführen beliebigen Codes.
3. Keine binäre Kompatibilität mit historischen Designerdateien.

### English

1. No general-purpose form designer.
2. No import or execution of arbitrary code.
3. No binary compatibility with historic designer files.

## Anforderungen / Requirements

### Deutsch

1. Unterstütze Dialog, statischen Text, Eingabezeile, Schaltfläche, Kontrollkästchen, Optionsfelder und Beschriftung mit erlaubten Eigenschaften.
2. Validiere Grenzen, Bezeichner, Kommandowerte, Tastenkürzel und Fokusreihenfolge vor Vorschau und Export.
3. Exportiere nur in einen ausdrücklich gewählten Pfad und bestätige das Überschreiben.
4. Führe generierten Code weder direkt noch über Shell oder Compiler aus.
5. Kompiliere ein deterministisches Export-Fixture in CI als technische Evidenz.
6. Halte Designer-Hilfen beispieleigen und C++14-kompatibel.

### English

1. Support dialog, static text, input line, button, check box, radio buttons, and label with allowed properties.
2. Validate bounds, identifiers, command values, shortcuts, and focus order before preview and export.
3. Export only to an explicitly selected path and confirm overwrite.
4. Do not execute generated code directly or through a shell or compiler.
5. Compile a deterministic export fixture in CI as technical evidence.
6. Keep designer helpers example-local and C++14-compatible.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Bindender Vorgänger sind die examplespezifischen Steuerelemente. Gemeinsame CMake- und Katalogflächen werden vor `tvfm` serialisiert.

*English:* The example-local controls are a binding predecessor. Shared CMake and catalog surfaces are serialized before `tvfm`.

**Risiko / Risk:** Quelltextexport kann als Codeausführung missverstanden werden. UI, Dokumentation und Tests müssen die reine Textausgabe deutlich benennen.

*English:* Source export can be mistaken for code execution. UI, documentation, and tests must clearly identify text-only output.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `examples/dlgdsn`
- `test/example-fixtures/dlgdsn`
- `examples/CMakeLists.txt`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Vorschau und Export sind ausschließlich mit gültigem Modell möglich.
2. Ungültige Eigenschaften und Pfade werden erklärbar abgewiesen.
3. Das generierte Fixture kompiliert mit den unterstützten modernen Compilern.
4. Keine Codeausführung oder Shellgrenze ist vorhanden.

### English

1. Preview and export are possible only with a valid model.
2. Invalid properties and paths are rejected with understandable messages.
3. The generated fixture compiles with supported modern compilers.
4. No code-execution or shell boundary exists.

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
Nutze intakes/tvision-dialog-designer-example.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-dialog-designer-example.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
