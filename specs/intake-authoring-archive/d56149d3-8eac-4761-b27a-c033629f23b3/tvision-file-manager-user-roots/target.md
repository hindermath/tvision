<!-- intake-authoring:begin -->
# tvision-Dateimanager für gewählte Benutzerwurzeln / tvision file manager for selected user roots

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

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
Nutze intakes/tvision-file-manager-user-roots.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-file-manager-user-roots.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
