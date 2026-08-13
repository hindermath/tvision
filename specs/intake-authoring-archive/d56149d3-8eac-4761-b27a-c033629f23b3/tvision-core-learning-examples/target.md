<!-- intake-authoring:begin -->
# Kern-Lernbeispiele für tvision / tvision core learning examples

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Fünf fehlende, risikoarme Lernziele werden als aktuelle C++14-Beispiele in die vorhandene Beispiel-Landschaft aufgenommen.

*English:* Add five missing, low-risk learning goals to the existing example landscape as current C++14 examples.

## Ausgangslage / Current State

Die Bibliothek besitzt passende öffentliche APIs für Desktop-Zeichnung, Zwischenablage, Terminaldarstellung und Unicode, aber keine fokussierten Programme für diese Lernziele und kein modernes Stufen-Tutorial.

*English:* The library provides suitable public APIs for desktop drawing, clipboard use, terminal display, and Unicode, but lacks focused programs for these learning goals and a modern staged tutorial.

## Zielbild / Target State

Die Targets `desklogo`, `clipboard`, `terminal`, `tutorial` und `unicode` sind CMake-integriert, tastaturbedienbar, dokumentiert und automatisiert prüfbar.

*English:* Targets `desklogo`, `clipboard`, `terminal`, `tutorial`, and `unicode` are integrated with CMake, keyboard-operable, documented, and automatically testable.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Keine Shell- oder Prozessintegration.
2. Keine Änderung öffentlicher Bibliotheks-APIs.
3. Keine BCC32-Erweiterung.

### English

1. No shell or process integration.
2. No change to public library APIs.
3. No BCC32 extension.

## Anforderungen / Requirements

### Deutsch

1. `desklogo` zeichnet ein neu entworfenes prozedurales Motiv ohne historische Bildressource.
2. `clipboard` demonstriert die aktuelle `TClipboard`-API, Editorkommandos und verständliches Fallback-Verhalten.
3. `terminal` nutzt `TTerminal` nur mit intern erzeugtem Text; es startet keine Shell, Prozesse oder PTYs.
4. `tutorial` bündelt 16 über `--step 1..16` oder interaktiv auswählbare Lernstufen in einem Target.
5. `unicode` demonstriert UTF-8, breite und kombinierende Zeichen und Fallbacks ohne Hostmutation.
6. Jedes Target besitzt einen deterministischen `--smoke`-Modus und eine deutsch-englische Beschreibung.
7. Die Programme bleiben C++14 und erhalten keine neuen Laufzeitabhängigkeiten.

### English

1. `desklogo` draws a newly designed procedural motif without a historic image resource.
2. `clipboard` demonstrates the current `TClipboard` API, editor commands, and understandable fallback behavior.
3. `terminal` uses `TTerminal` with internally generated text only; it starts no shell, process, or PTY.
4. `tutorial` combines 16 learning stages selectable through `--step 1..16` or interactively in one target.
5. `unicode` demonstrates UTF-8, wide and combining characters, and fallbacks without host mutation.
6. Every target has a deterministic `--smoke` mode and a German-English description.
7. The programs remain C++14 and add no runtime dependency.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Bindender Vorgänger ist das abgeschlossene Inventar `intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md`.

*English:* The completed inventory `intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md` is a binding predecessor.

**Risiko / Risk:** Terminal- und Unicode-Verhalten unterscheiden sich nach Plattform und Terminal. Tests müssen relevante Fallbacks statt pixelgleicher Ausgabe prüfen.

*English:* Terminal and Unicode behavior differ by platform and terminal. Tests must verify relevant fallbacks rather than pixel-identical output.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `examples/desklogo`
- `examples/clipboard`
- `examples/terminal`
- `examples/tutorial`
- `examples/unicode`
- `examples/CMakeLists.txt`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Alle fünf Targets bauen mit GCC, Clang, MSVC und MinGW.
2. Alle Smoke- und Logiktests bestehen.
3. Tastaturpfade, Fokus und textuelle Zustände erfüllen die anwendbaren WCAG-2.2-AA-Kriterien.
4. Kein historischer Code oder historische Ressource ist enthalten.

### English

1. All five targets build with GCC, Clang, MSVC, and MinGW.
2. All smoke and logic tests pass.
3. Keyboard paths, focus, and textual states meet applicable WCAG 2.2 AA criteria.
4. No historic code or resource is included.

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
Nutze intakes/tvision-core-learning-examples.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-core-learning-examples.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
