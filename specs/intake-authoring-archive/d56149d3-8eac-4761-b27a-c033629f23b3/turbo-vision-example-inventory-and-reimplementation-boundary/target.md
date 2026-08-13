<!-- intake-authoring:begin -->
# Turbo-Vision-Beispielinventar und Neuimplementierungsgrenze / Turbo Vision example inventory and reimplementation boundary

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Alle historischen Turbo-Pascal-Programme und alle vom tv203s-Beispiel-Makefile gebauten C/C++-Programme erhalten eine nachvollziehbare Funktionszuordnung. Das Ergebnis verhindert Dubletten und setzt vor jeder späteren Implementierung eine klare Clean-Room-Grenze.

*English:* Assign every historic Turbo Pascal program and every C/C++ program built by the tv203s example Makefile to a traceable functional disposition. The result prevents duplicates and establishes a clean-room boundary before later implementation.

## Ausgangslage / Current State

Das aktuelle Repository enthält bereits `tvdemo`, `tvedit`, `tvhc`, `tvforms`, `tvdir`, `mmenu`, `palette`, `avscolor` und `hello`. Die historische Quelle hat gemischte Lizenzlagen und enthält teilweise überholte Plattformannahmen.

*English:* The current repository already contains `tvdemo`, `tvedit`, `tvhc`, `tvforms`, `tvdir`, `mmenu`, `palette`, `avscolor`, and `hello`. The historic source has mixed licensing and partially obsolete platform assumptions.

## Zielbild / Target State

Eine bilinguale, hashgebundene Inventarmatrix weist jedem Programm genau `Covered`, `NewExample`, `AdaptedSuccessor` oder `ExcludedWithReason` zu und beschreibt ausschließlich beobachtbares Lernziel und Verhalten.

*English:* A bilingual, hash-bound inventory matrix assigns exactly one of `Covered`, `NewExample`, `AdaptedSuccessor`, or `ExcludedWithReason` to every program and records observable learning intent and behavior only.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Kein historischer Quelltext wird kopiert oder kompiliert.
2. Keine Beispielimplementierung und kein Dokumentationswerkzeug wird in diesem Intake gebaut.

### English

1. No historic source code is copied or compiled.
2. No example implementation or documentation toolchain is built in this intake.

## Anforderungen / Requirements

### Deutsch

1. Erfasse die sieben Pascal-Programme `TVDemo`, `TVEdit`, `TVHC`, `TVRDemo`, `GenRDemo`, `TVFM` und `MakeRes` sowie alle vom historischen Beispiel-Makefile gebauten Programme.
2. Dedupliziere nach Lernziel und Verhalten; gleiche oder ähnliche Namen allein entscheiden nicht.
3. Ordne `demo`/`TVDemo`, `TVEdit`, `TVHC`, `helpdemo`, `videomode`, `TVRDemo`, `GenRDemo`, `MakeRes`, `dyntxt`, `inplis`, `listvi` und `msgcls` vorhandenen aktuellen Beispielen zu.
4. Plane eigenständige Neuimplementierungen für `desklogo`, `clipboard`, `terminal`, Tutorial 01-16, `tcombo`, `dlgdsn` und `TVFM`; fasse die beiden Fortschritts- und Scroll-Dialog-Varianten jeweils zusammen.
5. Behandle `unicode` als sicheren Nachfolger des heutigen Lernziels von `cyrillic` und Font-Anzeige, ohne Host-Font-, Keymap- oder Gerätemanipulation.
6. Schließe `bhelp`, `fonts/genraw`, `i18n`, `eterm` und `xterm` mit technischer und lizenzbezogener Begründung aus.
7. Speichere sichere Quellenlabels, normalisierte SHA-256-Werte und eine Lizenznotiz, aber keine privaten absoluten Pfade.
8. Implementiere einen Validator, der fehlende Dispositionen, Mehrfachzuordnungen und funktionale Dubletten erkennt.

### English

1. Inventory the seven Pascal programs `TVDemo`, `TVEdit`, `TVHC`, `TVRDemo`, `GenRDemo`, `TVFM`, and `MakeRes`, plus every program built by the historic example Makefile.
2. Deduplicate by learning intent and behavior; equal or similar names alone are not decisive.
3. Map `demo`/`TVDemo`, `TVEdit`, `TVHC`, `helpdemo`, `videomode`, `TVRDemo`, `GenRDemo`, `MakeRes`, `dyntxt`, `inplis`, `listvi`, and `msgcls` to existing current examples.
4. Plan independent reimplementations for `desklogo`, `clipboard`, `terminal`, tutorial 01-16, `tcombo`, `dlgdsn`, and `TVFM`; consolidate the two progress and scroll-dialog variants respectively.
5. Treat `unicode` as the safe successor to the current learning intent of `cyrillic` and font display, without host-font, keymap, or device mutation.
6. Exclude `bhelp`, `fonts/genraw`, `i18n`, `eterm`, and `xterm` with technical and licensing rationale.
7. Store safe source labels, normalized SHA-256 values, and a licensing note, but no private absolute paths.
8. Implement a validator that detects missing dispositions, multiple assignments, and functional duplicates.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Dieser Intake ist die einzige Root der Serie. Der vorhandene RL-SE-Selbstprüfungs-Intake bleibt sichtbar zuerst, ist aber kein bindender Vorgänger.

*English:* This intake is the series' only root. The existing RL-SE self-assessment remains visibly first but is not a binding predecessor.

**Risiko / Risk:** OCR-Fehler, Aliasnamen und gemischte Lizenzen können Fehlzuordnungen verursachen. Deshalb gelten Makefile-Programmeinträge, Pascal-`program`-Deklarationen und aktuelle Repository-Funktionen als getrennte Evidenz.

*English:* OCR errors, aliases, and mixed licensing can cause incorrect mappings. Therefore Makefile program entries, Pascal `program` declarations, and current repository functions are treated as separate evidence.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `docs/examples/legacy-example-inventory.md`
- `scripts/tests/test_legacy_example_inventory.py`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Jeder Programmeintrag besitzt genau eine gültige Disposition.
2. Alle Quellenhashes und sicheren Labels sind prüfbar.
3. Der Validator schlägt bei fehlenden oder doppelten Zuordnungen fehl.
4. Die Clean-Room- und Lizenzgrenze ist deutsch und englisch verständlich.

### English

1. Every program entry has exactly one valid disposition.
2. All source hashes and safe labels are verifiable.
3. The validator fails on missing or duplicate assignments.
4. The clean-room and licensing boundary is understandable in German and English.

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
Nutze intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/turbo-vision-example-inventory-and-reimplementation-boundary.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
