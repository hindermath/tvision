<!-- intake-authoring:begin -->
# tvision-Dateimanager für gewählte Benutzerwurzeln / tvision file manager for selected user roots

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

Der abgenommene Sandbox-Dateimanager wird kontrolliert für eine ausdrücklich gewählte reale Benutzerwurzel geöffnet.

*English:* Controlled extension of the accepted sandbox file manager to an explicitly selected real user root.

## Ausgangslage / Current State

Phase 1 ist absichtlich auf eine neu erzeugte temporäre Sandbox begrenzt.

*English:* Phase 1 is intentionally limited to a newly created temporary sandbox.

## Zielbild / Target State

`tvfm --root <directory>` und eine gleichwertige interaktive Auswahl öffnen genau eine Sitzungswurzel; jede Operation bleibt darin und behandelt Unix-Symlinks sowie Windows-Reparse-Points sicher.

*English:* `tvfm --root <directory>` and an equivalent interactive selector open exactly one session root; every operation remains inside it and safely handles Unix symlinks and Windows reparse points.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Kein uneingeschränkter Systembrowser ohne Sitzungswurzel.
2. Keine Privilegienerhöhung.
3. Keine sichere Löschung oder garantierte Papierkorbsemantik.

### English

1. No unrestricted system browser without a session root.
2. No privilege escalation.
3. No secure erasure or guaranteed trash semantics.

## Anforderungen / Requirements

### Deutsch

1. Akzeptiere eine Benutzerwurzel nur nach expliziter CLI- oder Dialogauswahl.
2. Kanonisiere Root, Quelle und Ziel mit getrennten Unix- und Windows-Adaptern.
3. Verweigere Traversal, Rootwechsel, mehrdeutige Symlink-/Reparse-Ziele und Operationen außerhalb der Wurzel.
4. Prüfe die Grenze unmittelbar vor jeder schreibenden Operation erneut, um Time-of-check/Time-of-use-Risiken zu reduzieren.
5. Bestätige Umbenennen und Löschen mit vollständigem relativem Ziel und verständlicher Auswirkung.
6. Dokumentiere Berechtigungsfehler, schreibgeschützte Wurzeln, Netzlaufwerke und Plattformgrenzen.
7. Bewahre den sicheren Sandbox-Modus als Standard ohne `--root`.

### English

1. Accept a user root only after explicit CLI or dialog selection.
2. Canonicalize root, source, and destination with separate Unix and Windows adapters.
3. Reject traversal, root switching, ambiguous symlink/reparse targets, and operations outside the root.
4. Recheck the boundary immediately before every write operation to reduce time-of-check/time-of-use risk.
5. Confirm rename and deletion with the complete relative target and an understandable impact statement.
6. Document permission errors, read-only roots, network drives, and platform limits.
7. Keep the safe sandbox mode as the default without `--root`.

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

Die vollständig abgenommene Sandbox ist ein bindendes `SandboxBaseline`-Gate.

*English:* The fully accepted sandbox is a binding `SandboxBaseline` gate.

**Risiko / Risk:** Plattformunterschiede und Link-Rennen können die Wurzelgrenze gefährden. Nicht belegbare Fälle müssen fail-closed enden.

*English:* Platform differences and link races can threaten root confinement. Unproven cases must fail closed.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `examples/tvfm`
- `examples/tvfm/platform`
- `test/example-fixtures/tvfm-security`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Alle Traversal- und Link-Escape-Fixtures werden auf Unix und Windows abgewiesen.
2. Die Sandbox bleibt unverändert der sichere Standard.
3. Kein fehlgeschlagener Vorgang hinterlässt eine teilweise Dateioperation, soweit die Plattform atomare Mittel bereitstellt.
4. Berechtigungen und Restrisiken sind bilingual dokumentiert.

### English

1. All traversal and link-escape fixtures are rejected on Unix and Windows.
2. The sandbox remains the unchanged safe default.
3. No failed operation leaves a partial file operation where the platform provides atomic means.
4. Permissions and residual risks are documented bilingually.

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
Nutze intakes/tvision-file-manager-user-roots.md als alleinige fachliche Anforderungsquelle. Erfülle vor der Spezifikation das verbindliche Serien- und Start-Gate dieses Intakes vollständig: aktueller nicht supersedierter akzeptierter Series-Review mit passendem Zielhash, driftfrei validiertes Sequencing-Manifest samt Receipt, dieser Intake als `Eligible` aus `speckit-intake-series-next` sowie `Completed` für alle bindenden Vorgänger. Stoppe bei fehlender Evidenz, Drift oder Blocker fail-closed. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-file-manager-user-roots.md als alleinige fachliche Anforderungsquelle. Erfülle vor dem Start das verbindliche Serien- und Start-Gate dieses Intakes vollständig: aktueller nicht supersedierter akzeptierter Series-Review mit passendem Zielhash, driftfrei validiertes Sequencing-Manifest samt Receipt, dieser Intake als `Eligible` aus `speckit-intake-series-next` sowie `Completed` für alle bindenden Vorgänger. Stoppe bei fehlender Evidenz, Drift oder Blocker fail-closed. Behandle Delivery Mode `MergeAndSync` nur als beabsichtigten Modus; prüfe und protokolliere vor Commit, Push, Pull Request, Merge und Synchronisation jeweils eine aktuelle menschliche Freigabe für Repository, Branch, Scope und Aktion. Hole einen Admin-Bypass erst als getrennte aktuelle Freigabe ein, wenn konkreter PR, Exact Head, Checks, Reviews, betroffene Regel, Blocker, Grund und Restrisiko bekannt sind. Ein Bypass ersetzt keine fehlgeschlagene technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
