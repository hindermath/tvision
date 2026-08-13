<!-- intake-authoring:begin -->
# Abschlussprüfung der tvision-Beispiele und Dokumentation / tvision example and documentation final audit

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Eine unabhängige Abschlussprüfung belegt, dass die Serie vollständig, sicher, barrierearm, portabel und ohne historische Quelltextübernahme geliefert wurde.

*English:* An independent final audit proves that the series was delivered completely, safely, accessibly, portably, and without historic source-code reuse.

## Ausgangslage / Current State

Einzelne Intake-Abnahmen belegen ihre Teilziele, aber noch nicht die vollständige historische Abdeckung und das Zusammenspiel aller Beispiele, Dokumente und Lieferpfade.

*English:* Individual intake acceptance proves partial goals but not yet complete historic coverage and interaction across all examples, documents, and delivery paths.

## Zielbild / Target State

Ein bilingualer Abschlussbericht bindet Inventar, Code, Tests, CI, HTML, Pages, Lizenzgrenze, A11Y, Plattformmatrix, Merge-/Sync-Evidenz und offene Restrisiken.

*English:* A bilingual final report binds inventory, code, tests, CI, HTML, Pages, licensing boundary, accessibility, platform matrix, merge/sync evidence, and remaining residual risks.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Keine neue Feature-Implementierung während des Audits.
2. Kein Bypass als Ersatz für technische Evidenz.
3. Kein Start weiterer Intakes.

### English

1. No new feature implementation during the audit.
2. No bypass as a substitute for technical evidence.
3. No start of additional intakes.

## Anforderungen / Requirements

### Deutsch

1. Prüfe, dass jeder historische Programmeintrag genau eine aktuelle Disposition besitzt und keine funktionale Dublette entstanden ist.
2. Suche nach übernommenen historischen Text-, Code- und Ressourcensequenzen und dokumentiere Methode sowie Grenzen des Nachweises.
3. Baue alle bisherigen und neuen Beispiele mit GCC, Clang, MSVC und MinGW und führe relevante Tests aus.
4. Prüfe Dateimanager-Trust-Boundaries und Dialogdesigner-Codeexport erneut gegen die freigegebenen Sicherheitsfälle.
5. Baue beide Dokumentationssprachen, prüfe Links, HTML, Sprache, Heading-Hierarchie, Tastaturpfade und Axe-Ergebnisse.
6. Ordne jeden Acceptance-Gate dem tatsächlich ausgeführten Workflow, Job, Runner und Befehl zu.
7. Prüfe Documentation Impact, Projektstatistik, Repository-Status, Merge, Default-Branch-Sync und deklarierte Post-Merge-Aktionen.
8. Erfasse jede Ausnahme mit Owner, Risiko, Frist, Trigger, Evidenz und Scope-Grund; Critical oder High blockiert den Abschluss.

### English

1. Verify that every historic program entry has exactly one current disposition and no functional duplicate was created.
2. Search for reused historic text, code, and resource sequences and document the method and proof limits.
3. Build all existing and new examples with GCC, Clang, MSVC, and MinGW and run relevant tests.
4. Recheck file-manager trust boundaries and dialog-designer code export against approved security cases.
5. Build both documentation languages and check links, HTML, language, heading hierarchy, keyboard paths, and Axe results.
6. Map every acceptance gate to the workflow, job, runner, and command that actually executed it.
7. Check Documentation Impact, project statistics, repository state, merge, default-branch synchronization, and declared post-merge actions.
8. Record every exception with owner, risk, due date, trigger, evidence, and scope reason; Critical or High blocks completion.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Das vollständige Handbuch und GitHub Pages sind bindender `FinalAuditInput`; alle übrigen Ergebnisse werden über dessen Vorgänger eingebracht.

*English:* The complete handbook and GitHub Pages are binding `FinalAuditInput`; all other results arrive through its predecessors.

**Risiko / Risk:** Ein Audit im selben Änderungskontext kann Bestätigungsfehler erzeugen. Der Lauf muss Evidenz neu erheben und darf grüne Namen oder Bypass nicht als technischen Nachweis behandeln.

*English:* An audit in the same change context can create confirmation bias. The run must gather evidence anew and must not treat green names or bypass as technical proof.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `docs/audits/tvision-examples-and-documentation-final-audit.md`
- `docs/project-statistics.md`
- `docs/documentation-impact`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Keine offene Critical-/High-Feststellung und keine unbegründete Inventarlücke verbleibt.
2. Alle technischen Gates besitzen Exact-Head-Evidenz.
3. Dokumentations- und A11Y-Ergebnisse sind reproduzierbar.
4. Der Default-Branch ist nach Merge sauber synchronisiert; fremde Arbeitsbaumänderungen bleiben unberührt.

### English

1. No open Critical/High finding or unjustified inventory gap remains.
2. All technical gates have exact-head evidence.
3. Documentation and accessibility results are reproducible.
4. The default branch is cleanly synchronized after merge; unrelated worktree changes remain untouched.

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
Nutze intakes/tvision-example-documentation-final-audit.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-example-documentation-final-audit.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
