<!-- intake-authoring:begin -->
# Kern-Lernbeispiele für tvision / tvision core learning examples

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

## Datenschutz und Lieferkette / Privacy and Supply Chain

- **Datenschutz — Applicable:** Es werden keine Telemetrie und keine dauerhafte Sammlung von Benutzerinhalten eingeführt. Logs, Test-Fixtures, Screenshots und Review-/CI-Evidenz dürfen keine privaten absoluten Pfade, Zugangsdaten oder echten Benutzerinhalte enthalten; erforderliche Beispiele sind synthetisch oder redigiert und werden nur so lange wie für den Nachweis nötig aufbewahrt. / **Privacy — Applicable:** No telemetry or persistent collection of user content is introduced. Logs, test fixtures, screenshots, and review/CI evidence must not contain private absolute paths, credentials, or real user content; required examples are synthetic or redacted and retained only as long as needed for evidence.
- **Lieferkette — Applicable:** Jede neue Laufzeit-, Build-, Test- oder Dokumentationsabhängigkeit und jede CI-Action benötigt Zweck, vertrauenswürdige Herkunft, Lizenzprüfung, eine reproduzierbar gepinnte Version beziehungsweise einen unveränderlichen Commit oder Prüfsummennachweis sowie minimale Berechtigungen. Werden keine neuen Bestandteile eingeführt, muss die Umsetzung dies mit `NotApplicable` und Begründung dokumentieren. / **Supply chain — Applicable:** Every new runtime, build, test, or documentation dependency and every CI action requires a purpose, trusted origin, license review, a reproducibly pinned version or immutable commit/checksum evidence, and least privilege. If no new component is introduced, implementation evidence must record `NotApplicable` with rationale.

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
Nutze intakes/tvision-core-learning-examples.md als alleinige fachliche Anforderungsquelle. Erfülle vor der Spezifikation das verbindliche Serien- und Start-Gate dieses Intakes vollständig: aktueller nicht supersedierter akzeptierter Series-Review mit passendem Zielhash, driftfrei validiertes Sequencing-Manifest samt Receipt, dieser Intake als `Eligible` aus `speckit-intake-series-next` sowie `Completed` für alle bindenden Vorgänger. Stoppe bei fehlender Evidenz, Drift oder Blocker fail-closed. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-core-learning-examples.md als alleinige fachliche Anforderungsquelle. Erfülle vor dem Start das verbindliche Serien- und Start-Gate dieses Intakes vollständig: aktueller nicht supersedierter akzeptierter Series-Review mit passendem Zielhash, driftfrei validiertes Sequencing-Manifest samt Receipt, dieser Intake als `Eligible` aus `speckit-intake-series-next` sowie `Completed` für alle bindenden Vorgänger. Stoppe bei fehlender Evidenz, Drift oder Blocker fail-closed. Behandle Delivery Mode `MergeAndSync` nur als beabsichtigten Modus; prüfe und protokolliere vor Commit, Push, Pull Request, Merge und Synchronisation jeweils eine aktuelle menschliche Freigabe für Repository, Branch, Scope und Aktion. Hole einen Admin-Bypass erst als getrennte aktuelle Freigabe ein, wenn konkreter PR, Exact Head, Checks, Reviews, betroffene Regel, Blocker, Grund und Restrisiko bekannt sind. Ein Bypass ersetzt keine fehlgeschlagene technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
