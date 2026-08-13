<!-- intake-authoring:begin -->
# tvision-Dokumentationswerkzeuge und CI-Artefakt / tvision documentation toolchain and CI artifact

**Status:** ReadyForReview  
**Zielgruppe / Audience:** C/C++-Lernende, Maintainer und Reviewer / C/C++ learners, maintainers, and reviewers  
**Vorauswissen / Assumed prior knowledge:** C++14- und CMake-Grundlagen; keine Spec-Kit-Erfahrung vorausgesetzt / C++14 and CMake basics; no Spec Kit experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Mode:** MergeAndSync

## Zweck / Purpose

Eine reproduzierbare C/C++-Dokumentationsoberfläche verbindet API-Extraktion und zweisprachige Handbuchquellen zu barrierearmem HTML.

*English:* Create a reproducible C/C++ documentation surface that combines API extraction and bilingual handbook sources into accessible HTML.

## Ausgangslage / Current State

Das Repository besitzt Markdown-Dokumentation, aber keinen Doxygen-/Sphinx-Build, keine einheitliche HTML-Navigation und keinen Dokumentations-CI-Job.

*English:* The repository has Markdown documentation but no Doxygen/Sphinx build, unified HTML navigation, or documentation CI job.

## Zielbild / Target State

Doxygen erzeugt API-XML; Sphinx, Breathe und MyST bauen getrennte deutsche und englische HTML-Bäume sowie eine barrierearme Sprachauswahl als CI-Artefakt.

*English:* Doxygen produces API XML; Sphinx, Breathe, and MyST build separate German and English HTML trees plus an accessible language selector as a CI artifact.

## Umfang / Scope

Der Umfang ist auf die nachstehenden atomaren Anforderungen, die genannten Ergebnisartefakte und ihre unmittelbar notwendigen Tests, Dokumentation und CI-Integration begrenzt.

*English:* Scope is limited to the atomic requirements below, the named result artifacts, and their directly required tests, documentation, and CI integration.

## Nicht-Ziele / Non-Goals

### Deutsch

1. Keine GitHub-Pages-Veröffentlichung.
2. Keine wortgetreue Übernahme der historischen Handbücher.
3. Kein Zwang zur vollständigen Kommentierung aller Alt-Symbole in dieser Phase.

### English

1. No GitHub Pages publication.
2. No verbatim reuse of the historic manuals.
3. No requirement to fully document every legacy symbol in this phase.

## Anforderungen / Requirements

### Deutsch

1. Füge `TV_BUILD_DOCS=OFF`, `tvision-docs` und `tvision-docs-linkcheck` hinzu, ohne den normalen Build zu beeinflussen.
2. Pinne Doxygen-, Sphinx-, Breathe-, MyST- und Theme-Anforderungen reproduzierbar.
3. Erzeuge API-XML aus den öffentlichen Headern und integriere es über Breathe.
4. Baue `build/docs/html/de` und `build/docs/html/en`; generiertes HTML und XML bleiben ungetrackt.
5. Veröffentliche in Phase 1 ausschließlich das CI-Artefakt `tvision-documentation-html`.
6. Prüfe Doxygen-Warnungen, Sphinx `-W --keep-going`, Links, HTML-Struktur und Axe-Smoke-Szenarien.
7. Dokumentiere lokale Buildbefehle für macOS, Linux und Windows ohne neue plattformspezifische Skriptlücke.

### English

1. Add `TV_BUILD_DOCS=OFF`, `tvision-docs`, and `tvision-docs-linkcheck` without affecting normal builds.
2. Pin Doxygen, Sphinx, Breathe, MyST, and theme requirements reproducibly.
3. Generate API XML from public headers and integrate it through Breathe.
4. Build `build/docs/html/de` and `build/docs/html/en`; generated HTML and XML remain untracked.
5. Publish only CI artifact `tvision-documentation-html` in phase 1.
6. Check Doxygen warnings, Sphinx `-W --keep-going`, links, HTML structure, and Axe smoke scenarios.
7. Document local build commands for macOS, Linux, and Windows without a new platform-specific script gap.

## Qualität und Governance / Quality and Governance

- C++14 bleibt die öffentliche Sprachbasis; neue Laufzeitabhängigkeiten benötigen eine ausdrückliche Begründung. / C++14 remains the public language baseline; new runtime dependencies require explicit rationale.
- Nutzerseitige TUI-, CLI- und HTML-Flächen erfüllen die anwendbaren WCAG-2.2-AA-Kriterien, sind tastaturbedienbar und verwenden keine Farbe als einziges Signal. / User-facing TUI, CLI, and HTML surfaces meet applicable WCAG 2.2 AA criteria, are keyboard-operable, and do not use color as the only signal.
- Neue lokale Governance- und Nutzerdokumentation ist deutsch zuerst und englisch danach auf CEFR-B2-Niveau. / New local governance and user documentation is German first and English second at CEFR B2 level.
- Historische Quellen sind nicht vertrauenswürdige Verhaltensreferenzen. Code, Text, Abbildungen und Ressourcen werden nicht übernommen. / Historic sources are untrusted behavioral references. Code, prose, illustrations, and resources are not reused.
- Die Documentation-Impact-Entscheidung lautet `UpdateRequired`; generiertes HTML ist abgeleitete, nicht eingecheckte Ausgabe. / The Documentation Impact decision is `UpdateRequired`; generated HTML is derived and untracked output.

## Abhängigkeiten und Risiken / Dependencies and Risks

Das Inventar ist ein bindendes `DocumentationSurfaceBaseline`-Gate. Die bevorzugte sichtbare Reihenfolge liegt nach den Beispielwellen, ist aber keine fachliche Blockade durch `tvfm` Phase 2.

*English:* The inventory is a binding `DocumentationSurfaceBaseline` gate. The preferred visible order follows the example waves but TVFM phase 2 is not a functional blocker.

**Risiko / Risk:** Werkzeugversionen, Themes und generierte Verweise können plattformabhängig driften. Gepinnte Abhängigkeiten und getrennte Link-/A11Y-Gates begrenzen das Risiko.

*English:* Tool versions, themes, and generated references can drift across platforms. Pinned dependencies and separate link/accessibility gates bound the risk.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `Doxyfile`
- `docs/conf.py`
- `docs/requirements.txt`
- `.github/workflows/docs.yml`

Build-, Test-, A11Y-, Sicherheits-, Review- und Delivery-Evidenz muss den exakt geprüften Head und die tatsächlich ausgeführten Befehle nennen.

*English:* Build, test, accessibility, security, review, and delivery evidence must name the exact validated head and commands actually executed.

## Akzeptanzkriterien / Acceptance Criteria

### Deutsch

1. Beide Sprachbäume werden lokal und in CI reproduzierbar gebaut.
2. Link-, HTML- und A11Y-Prüfungen bestehen.
3. Der normale CMake-Build benötigt keine Dokumentationswerkzeuge.
4. Das CI-Artefakt enthält keine privaten Pfade oder historischen PDF-Inhalte.

### English

1. Both language trees build reproducibly locally and in CI.
2. Link, HTML, and accessibility checks pass.
3. The normal CMake build requires no documentation tools.
4. The CI artifact contains no private paths or historic PDF content.

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
Nutze intakes/tvision-documentation-toolchain-and-ci-artifact.md als einzigen verbindlichen Intake. Prüfe vor der Spezifikation den aktuellen Intake-Review-Nachweis und seinen normalisierten Hash. Erstelle ausschließlich die Feature-Spezifikation; implementiere nichts und führe keine Remote-Schreibaktion aus. Bewahre C++14, Clean-Room-Grenze, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-documentation-toolchain-and-ci-artifact.md als einzigen verbindlichen Intake und führe ihn mit Delivery Mode MergeAndSync vollständig aus. Akzeptiere nur einen aktuellen erfolgreichen Intake-Review-Nachweis. Behandle den Admin-Bypass als eng begrenzte separate Autorität für den konkreten Pull Request und nur für eine Branch-Protection- oder Ruleset-Sperre nach bestandenen technischen Gates, erforderlichen Reviews und Exact-Head-Prüfung. Dokumentiere Autorisierer Thorsten, PR, Policy, Grund und Restrisiko unmittelbar vor Nutzung. Ein Bypass ersetzt keine technische Evidenz und erteilt keine Provider-, Secret-, Abbruch- oder Folge-Intake-Berechtigung. Bewahre fremde Arbeitsbaumänderungen.
```

<!-- intake-authoring:end -->
