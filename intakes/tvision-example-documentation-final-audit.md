<!-- intake-authoring:begin -->
# Abschlussprüfung der tvision-Beispiele und Dokumentation / tvision example and documentation final audit

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Begriffe / Terms

- **Spec Kit und Intake:** Spec Kit ist der Arbeitsablauf für Spezifikation, Planung, Aufgaben und Umsetzung; ein Intake ist die verbindliche Anforderungsquelle eines Arbeitspakets. / **Spec Kit and intake:** Spec Kit is the workflow for specification, planning, tasks, and implementation; an intake is the binding requirements source for one work package.
- **Serie und DAG:** Eine Serie ordnet mehrere Intakes. Ihr DAG ist ein gerichteter, kreisfreier Abhängigkeitsgraph. / **Series and DAG:** A series orders several intakes. Its DAG is a directed acyclic dependency graph.
- **CI:** Continuous Integration führt Build und Prüfungen automatisiert aus. / **CI:** Continuous Integration runs builds and checks automatically.
- **CLI und TUI:** Eine CLI ist eine Kommandozeile; eine TUI ist eine textbasierte Benutzungsoberfläche. / **CLI and TUI:** A CLI is a command line; a TUI is a text-based user interface.
- **A11Y, WCAG und CEFR B2:** A11Y steht für Barrierefreiheit, WCAG 2.2 AA ist die verwendete Prüfbasis und CEFR B2 das angestrebte Sprachniveau. / **A11Y, WCAG, and CEFR B2:** A11Y means accessibility, WCAG 2.2 AA is the validation baseline, and CEFR B2 is the target language level.
- **SHA-256 und Clean Room:** SHA-256 ist eine kryptografische Prüfsumme; Clean Room bedeutet eine unabhängige Neuimplementierung ohne Übernahme geschützter Quellenbestandteile. / **SHA-256 and clean room:** SHA-256 is a cryptographic checksum; clean room means independent reimplementation without reusing protected source material.
- **OCR, PTY und ABI:** OCR ist Texterkennung aus Bild- oder PDF-Inhalten, ein PTY ist ein Pseudoterminal und eine ABI ist die binäre Schnittstelle zwischen Programmteilen. / **OCR, PTY, and ABI:** OCR extracts text from images or PDFs, a PTY is a pseudo-terminal, and an ABI is the binary interface between program components.
- **Exact Head, Ruleset und Admin Bypass:** Exact Head ist der konkret geprüfte Git-Commit; ein Ruleset sind Hosting-Regeln für Branches und Pull Requests; ein Admin Bypass ist eine ausdrücklich freigegebene Ausnahme von genau einer solchen Regel. / **Exact head, ruleset, and Admin Bypass:** Exact head is the specific validated Git commit; a ruleset contains hosting rules for branches and pull requests; an Admin Bypass is an explicitly approved exception to exactly one such rule.

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

## Datenschutz und Lieferkette / Privacy and Supply Chain

- **Datenschutz — Applicable:** Es werden keine Telemetrie und keine dauerhafte Sammlung von Benutzerinhalten eingeführt. Logs, Test-Fixtures, Screenshots und Review-/CI-Evidenz dürfen keine privaten absoluten Pfade, Zugangsdaten oder echten Benutzerinhalte enthalten; erforderliche Beispiele sind synthetisch oder redigiert und werden nur so lange wie für den Nachweis nötig aufbewahrt. / **Privacy — Applicable:** No telemetry or persistent collection of user content is introduced. Logs, test fixtures, screenshots, and review/CI evidence must not contain private absolute paths, credentials, or real user content; required examples are synthetic or redacted and retained only as long as needed for evidence.
- **Lieferkette — Applicable:** Jede neue Laufzeit-, Build-, Test- oder Dokumentationsabhängigkeit und jede CI-Action benötigt Zweck, vertrauenswürdige Herkunft, Lizenzprüfung, eine reproduzierbar gepinnte Version beziehungsweise einen unveränderlichen Commit oder Prüfsummennachweis sowie minimale Berechtigungen. Werden keine neuen Bestandteile eingeführt, muss die Umsetzung dies mit `NotApplicable` und Begründung dokumentieren. / **Supply chain — Applicable:** Every new runtime, build, test, or documentation dependency and every CI action requires a purpose, trusted origin, license review, a reproducibly pinned version or immutable commit/checksum evidence, and least privilege. If no new component is introduced, implementation evidence must record `NotApplicable` with rationale.

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

Die bei der Erstellung genehmigte Angabe `MergeAndSync` beschreibt den beabsichtigten Delivery-Modus und ist historische Autoritätsevidenz, aber keine fortdauernde Ausführungsberechtigung. Vor Commit, Push, Pull Request, Merge und Fast-Forward-Synchronisation muss jeweils eine aktuelle ausdrückliche menschliche Freigabe für Repository, Branch, exakten Intake-Scope und die bevorstehende Aktion geprüft und protokolliert werden. Fehlt sie oder ist ihr Scope unklar, stoppt der Lauf vor der jeweiligen Grenze.

Der gespeicherte Admin-Bypass ist ebenfalls keine aktuelle Bypass-Freigabe. Erst nachdem konkreter Pull Request, exakter Head, technische Checks, erforderliche Reviews, betroffene Branch-Protection- oder Ruleset-Regel, Blocker, Grund und Restrisiko bekannt sind, muss eine davon getrennte aktuelle menschliche Bypass-Autorisierung genau diese Ausnahme benennen. Sie ersetzt niemals fehlgeschlagene technische Prüfungen oder Exact-Head-Evidenz. Provider-Administration, Secret-Änderungen, Check-Abbruch und der Start eines Folge-Intakes bleiben ausgeschlossen.

*English:* The `MergeAndSync` value approved during authoring records the intended delivery mode and historical authority evidence, but it is not continuing execution authority. Before commit, push, pull request, merge, and fast-forward synchronization, a current explicit human grant covering the repository, branch, exact intake scope, and next action must be verified and recorded. If it is missing or ambiguous, the run stops before that boundary. The stored Admin Bypass is likewise not a current bypass grant. Only after the concrete pull request, exact head, technical checks, required reviews, affected branch-protection or ruleset rule, blocker, rationale, and residual risk are known may a separate current human bypass authorization name that exact exception. It never replaces failed technical checks or exact-head evidence. Provider administration, secret changes, check cancellation, and starting a successor intake remain excluded.

## Verbindliches Serien- und Start-Gate / Binding Series and Start Gate

Dieser Intake bleibt die alleinige fachliche Anforderungsquelle seines Arbeitspakets; die Series-Nachweise regeln ausschließlich Startberechtigung und Reihenfolge. Vor `Specify` oder einem autonomen Lauf müssen alle folgenden Punkte aktuell belegt sein:

1. Ein nicht supersedierter vollständiger Series-Review hat den Status `Ready` oder menschlich akzeptiertes `ReadyWithAcceptedRisks`, und sein Zielhash stimmt mit diesem Intake überein.
2. Das aktuelle Sequencing-Manifest und sein Receipt bestehen die installierten Validatoren ohne Drift.
3. Der read-only Aufruf `speckit-intake-series-next` meldet genau diesen Intake als `Eligible`; für die Root muss zusätzlich ihre Root-Rolle bestätigt sein.
4. Alle bindenden Vorgänger stehen auf `Completed`. Nicht bindende Serialisierungskanten werden für gemeinsame Schreibflächen eingehalten, ersetzen aber kein bindendes Gate.

Fehlt ein Nachweis, besteht Drift oder meldet `series-next` einen Blocker, endet der Lauf vor Spezifikation beziehungsweise Umsetzung fail-closed. `Eligible` ist nur Reihenfolgenevidenz und erteilt keine Implementierungs- oder Remote-Berechtigung.

*English:* This intake remains the sole functional requirements source for its work package; series evidence governs start eligibility and order only. Before `Specify` or an autonomous run, a current non-superseded full Series review must be `Ready` or human-accepted `ReadyWithAcceptedRisks` with this target hash; the current sequencing manifest and receipt must validate without drift; read-only `speckit-intake-series-next` must report exactly this intake as `Eligible` and confirm the root role where applicable; and every binding predecessor must be `Completed`. Non-binding serialization edges are observed for shared write surfaces but do not replace a binding gate. Missing evidence, drift, or a blocker stops the run fail-closed before specification or implementation. `Eligible` is ordering evidence only and grants no implementation or remote authority.

## Annahmen und offene Fragen / Assumptions and Open Questions

Alle materiellen Entscheidungen `IAD001` bis `IAD008` sind beantwortet. Es bestehen keine offenen Intake-Authoring-Fragen. Die Serienreihenfolge erteilt keine automatische Berechtigung zum Start dieses oder eines nachfolgenden Spec-Kit-Laufs.

*English:* All material decisions `IAD001` through `IAD008` are answered. No intake-authoring question remains open. Series order does not automatically authorize starting this or a successor Spec Kit run.

<!-- intake-authoring:prompts -->
## Kopierfertige Spec-Kit-Prompts / Copy-Ready Spec Kit Prompts

<!-- spec-kit-command-id: speckit.specify -->
### Specify

```text
$speckit-specify
Nutze intakes/tvision-example-documentation-final-audit.md als alleinige fachliche Anforderungsquelle. Erfülle vor der Spezifikation das verbindliche Serien- und Start-Gate dieses Intakes vollständig: aktueller nicht supersedierter akzeptierter Series-Review mit passendem Zielhash, driftfrei validiertes Sequencing-Manifest samt Receipt, dieser Intake als `Eligible` aus `speckit-intake-series-next` sowie `Completed` für alle bindenden Vorgänger. Stoppe bei fehlender Evidenz, Drift oder Blocker fail-closed. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-example-documentation-final-audit.md als alleinige fachliche Anforderungsquelle. Erfülle vor dem Start das verbindliche Serien- und Start-Gate dieses Intakes vollständig: aktueller nicht supersedierter akzeptierter Series-Review mit passendem Zielhash, driftfrei validiertes Sequencing-Manifest samt Receipt, dieser Intake als `Eligible` aus `speckit-intake-series-next` sowie `Completed` für alle bindenden Vorgänger. Stoppe bei fehlender Evidenz, Drift oder Blocker fail-closed. Behandle Delivery Mode `MergeAndSync` nur als beabsichtigten Modus; prüfe und protokolliere vor Commit, Push, Pull Request, Merge und Synchronisation jeweils eine aktuelle menschliche Freigabe für Repository, Branch, Scope und Aktion. Hole einen Admin-Bypass erst als getrennte aktuelle Freigabe ein, wenn konkreter PR, Exact Head, Checks, Reviews, betroffene Regel, Blocker, Grund und Restrisiko bekannt sind. Ein Bypass ersetzt keine fehlgeschlagene technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
