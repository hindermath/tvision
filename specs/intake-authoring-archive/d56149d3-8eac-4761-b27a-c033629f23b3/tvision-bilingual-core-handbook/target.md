<!-- intake-authoring:begin -->
# Zweisprachiges tvision-Kernhandbuch / tvision bilingual core handbook

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Ein deutsch-englischer Kernpfad führt Lernende vom ersten Build über das Stufen-Tutorial zu den zentralen tvision-Konzepten und vorhandenen Beispielen.

*English:* A German-English core path leads learners from the first build through the staged tutorial to central tvision concepts and existing examples.

## Ausgangslage / Current State

Die vorhandene Upstream-Dokumentation ist wertvoll, aber überwiegend englisch, verteilt und nicht als zusammenhängendes aktuelles Handbuch aufgebaut.

*English:* The existing upstream documentation is valuable but mostly English, distributed, and not structured as a coherent current handbook.

## Zielbild / Target State

Paarige MyST-Markdown-Quellen erklären Einstieg, Build, Tutorial, Kernkonzepte, Beispielkatalog, Portierung und API-Navigation auf CEFR-B2-Niveau.

*English:* Paired MyST Markdown sources explain getting started, build, tutorial, core concepts, example catalog, porting, and API navigation at CEFR B2 level.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Noch keine vollständige Referenz aller Spezialthemen.
2. Keine GitHub-Pages-Veröffentlichung.
3. Keine Übersetzung unveränderter historischer oder Upstream-Texte durch bloße Paraphrase.

### English

1. No complete reference for all specialist topics yet.
2. No GitHub Pages publication.
3. No translation of unchanged historic or upstream text through mere paraphrase.

## Anforderungen / Requirements

### Deutsch

1. Erstelle paarige Kapitel unter `docs/manual/de/` und `docs/manual/en/` mit stabiler Navigation.
2. Dokumentiere Installation und Build, ohne lokale Homebrew- oder Benutzerpfade als portable Vorgabe zu behaupten.
3. Führe durch die 16 Tutorial-Stufen und verlinke jeweils aktuellen Code und erwartetes Verhalten.
4. Erkläre Anwendung, Views, Gruppen, Ereignisse, Kommandos, Menüs, Statuszeilen, Fenster, Dialoge, Streams, Ressourcen, Text, Unicode und Zwischenablage.
5. Dokumentiere jedes bestehende und bis dahin abgenommene neue Beispiel einmal nach Lernziel.
6. Erstelle einen verhaltensorientierten Portierungsleitfaden von Turbo Pascal und historischem Turbo-Vision-C++ zu aktuellem tvision.
7. Kennzeichne OCR und historische Handbücher nur als Gliederungsinspiration; schreibe alle Inhalte aus aktuellem Code und Tests neu.
8. Erkläre Fach- und Spec-Kit-Begriffe beim ersten Auftreten und halte Navigation, Sprache und Textalternativen WCAG-konform.

### English

1. Create paired chapters under `docs/manual/de/` and `docs/manual/en/` with stable navigation.
2. Document installation and build without presenting local Homebrew or user paths as portable requirements.
3. Guide readers through all 16 tutorial stages and link each to current code and expected behavior.
4. Explain application, views, groups, events, commands, menus, status lines, windows, dialogs, streams, resources, text, Unicode, and clipboard.
5. Document every existing and then-accepted new example once by learning intent.
6. Create a behavior-oriented porting guide from Turbo Pascal and historic Turbo Vision C++ to current tvision.
7. Identify OCR and historic manuals only as outline inspiration; rewrite all content from current code and tests.
8. Explain technical and Spec Kit terms on first use and keep navigation, language, and text alternatives WCAG-conformant.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Bindend sind Dokumentationswerkzeuge sowie die Kern-, lokalen Steuerungs- und Sandbox-Beispiele, die das Handbuch beschreibt.

*English:* Documentation tooling plus the core, local-control, and sandbox examples described by the handbook are binding.

**Risiko / Risk:** Eine scheinbar vollständige Dokumentation könnte veraltetes Verhalten behaupten. Jeder technische Anspruch braucht einen aktuellen Code-, Test- oder Buildnachweis.

*English:* Apparently complete documentation could claim obsolete behavior. Every technical claim needs current code, test, or build evidence.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `docs/manual/de`
- `docs/manual/en`
- `docs/manual/index.html`
- `docs/examples/README.md`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Alle Kernkapitel existieren paarig und bestehen die Sprachpartnerprüfung.
2. Codebeispiele bauen oder verweisen auf gebaute Repository-Targets.
3. Axe, Linkcheck und Heading-Prüfung bestehen.
4. Ein neuer Lernender kann Build, Tutorial und Beispielauswahl ohne vorausgesetzte Spec-Kit-Kenntnis nachvollziehen.

### English

1. All core chapters exist as pairs and pass the language-partner check.
2. Code examples build or refer to built repository targets.
3. Axe, link check, and heading checks pass.
4. A new learner can follow build, tutorial, and example selection without assumed Spec Kit knowledge.

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
Nutze intakes/tvision-bilingual-core-handbook.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-bilingual-core-handbook.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
