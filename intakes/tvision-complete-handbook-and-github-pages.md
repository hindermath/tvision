<!-- intake-authoring:begin -->
# Vollständiges tvision-Handbuch und GitHub Pages / tvision complete handbook and GitHub Pages

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Das Kernhandbuch wird zu einer vollständigen aktuellen Produktdokumentation ausgebaut und nach bestandenen Gates öffentlich bereitgestellt.

*English:* Expand the core handbook into complete current product documentation and publish it after all gates pass.

## Ausgangslage / Current State

Das Kernhandbuch deckt den Einstiegspfad ab; Spezialthemen, vollständige API-Navigation und die öffentliche Pages-Auslieferung fehlen noch.

*English:* The core handbook covers the entry path; specialist topics, complete API navigation, and public Pages delivery are still missing.

## Zielbild / Target State

Das bilinguale Handbuch deckt alle aktuellen Hauptoberflächen ab und wird reproduzierbar über GitHub Pages aus exakt dem geprüften Build-Artefakt veröffentlicht.

*English:* The bilingual handbook covers all current major surfaces and is reproducibly published through GitHub Pages from the exact validated build artifact.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Keine historische Faksimile-Dokumentation.
2. Keine Veröffentlichung bei fehlender Review- oder Gate-Evidenz.
3. Keine Provider-Administration außerhalb des konkreten Pages-Workflows.

### English

1. No historic facsimile documentation.
2. No publication with missing review or gate evidence.
3. No provider administration outside the concrete Pages workflow.

## Anforderungen / Requirements

### Deutsch

1. Ergänze Streams, Ressourcen, Collections, Hilfe, Farben, Terminal, Plattformverhalten, Kompatibilität, Fehlerdiagnose und die fertigen Designer-/Dateimanager-Beispiele.
2. Verknüpfe öffentliche API-Referenz, Konzepte und Beispiele ohne tote oder doppelte Navigationsziele.
3. Dokumentiere unterstützte Plattformen und Compiler evidenzbasiert; behandle BCC32 für neue Beispiele begründet als `N/A`.
4. Erzeuge Pages ausschließlich aus dem zuvor validierten Dokumentationsjob und deploie keinen ungeprüften zweiten Build.
5. Setze Least-Privilege-Workflowrechte, gepinnte Actions und eine eindeutige Concurrency-Regel.
6. Veröffentliche erst nach erfolgreichen Build-, Link-, HTML-, Sprachpartner- und A11Y-Gates.
7. Synchronisiere nach Merge den lokalen Default-Branch per Fast-Forward und validiere die veröffentlichte Startseite.

### English

1. Add streams, resources, collections, help, colors, terminal, platform behavior, compatibility, troubleshooting, and the completed designer/file-manager examples.
2. Connect public API reference, concepts, and examples without dead or duplicate navigation targets.
3. Document supported platforms and compilers from evidence; treat BCC32 for new examples as justified `N/A`.
4. Generate Pages only from the previously validated documentation job and do not deploy an unchecked second build.
5. Use least-privilege workflow permissions, pinned actions, and an unambiguous concurrency rule.
6. Publish only after successful build, link, HTML, language-partner, and accessibility gates.
7. After merge, fast-forward the local default branch and validate the published landing page.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Bindend sind Kernhandbuch, Dialogdesigner und `tvfm` mit Benutzerwurzeln.

*English:* The core handbook, dialog designer, and user-root `tvfm` are binding.

**Risiko / Risk:** Pages-Berechtigungen und Build-Drift können ungeprüfte Inhalte veröffentlichen. Artifact-Promotion und Exact-Head-Evidenz sind harte Gates.

*English:* Pages permissions and build drift can publish unchecked content. Artifact promotion and exact-head evidence are hard gates.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `docs/manual/de`
- `docs/manual/en`
- `.github/workflows/docs.yml`
- `README.md`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Die Themenabdeckungsmatrix weist keine unbegründete Lücke auf.
2. Pages verwendet bytegleich das validierte HTML-Artefakt.
3. Öffentliche Navigation, Sprachwechsel und Tastaturbedienung bestehen WCAG-Prüfungen.
4. Merge-, Sync- und veröffentlichte URL-Evidenz beziehen sich auf denselben geprüften Head.

### English

1. The topic coverage matrix has no unjustified gap.
2. Pages uses the byte-identical validated HTML artifact.
3. Public navigation, language switching, and keyboard operation pass WCAG checks.
4. Merge, synchronization, and published URL evidence refer to the same validated head.

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
Nutze intakes/tvision-complete-handbook-and-github-pages.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-complete-handbook-and-github-pages.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
