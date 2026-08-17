<!-- intake-authoring:begin -->
# Open-Watcom-DOS/DPMI-CI-Migration / Open Watcom DOS/DPMI CI migration

**Status:** ReadyForReview  
**Zielgruppe / Audience:** Primaer Maintainer sowie Build- und CI-Verantwortliche; sekundaer Beitragende und Lernende / Primarily maintainers and build/CI owners; secondarily contributors and learners  
**Vorauswissen / Assumed prior knowledge:** Grundlegende Kenntnisse von C++14, Makefiles und CI; keine Spec-Kit- oder Open-Watcom-Erfahrung vorausgesetzt / Basic C++14, makefile, and CI knowledge; no Spec Kit or Open Watcom experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Authority:** LocalImplementation

## Begriffe / Terms

- **AssessmentBaseline:** Bindendes Serien-Gate: Der Machbarkeits-Intake muss abgeschlossen sein und ein dokumentiertes `Go` enthalten. / **AssessmentBaseline:** Binding series gate: the feasibility intake must be completed and contain a documented `Go`.
- **DPMI:** DOS Protected Mode Interface fuer DOS-Programme im geschuetzten Prozessormodus. / **DPMI:** DOS Protected Mode Interface for DOS programs in protected processor mode.
- **Cutover:** Kontrollierte Umschaltung des CI-Nachweises vom nicht reproduzierbaren Borland-Download auf den geprueften Open-Watcom-Pfad. / **Cutover:** Controlled switch of CI evidence from the non-reproducible Borland download to the validated Open Watcom path.
- **ABI:** Application Binary Interface, der Binaervertrag zwischen kompilierten Komponenten. / **ABI:** Application Binary Interface, the binary contract between compiled components.
- **Fail-closed:** Bei fehlender oder widerspruechlicher Evidence wird abgebrochen, statt unsicher fortzufahren. / **Fail-closed:** Missing or contradictory evidence stops the process instead of allowing unsafe continuation.

## Zweck / Purpose

Dieser Intake setzt eine positiv abgeschlossene Machbarkeitspruefung kontrolliert in einen reproduzierbaren Open-Watcom-DOS/DPMI-CI-Pfad um. Er beseitigt die nicht mehr verfuegbaren BCC32-/TASM32-Downloads, ohne eine nicht belegte Borland-ABI-Kompatibilitaet zu behaupten.

*English:* This intake turns a positively completed feasibility assessment into a reproducible Open Watcom DOS/DPMI CI path. It removes unavailable BCC32/TASM32 downloads without claiming unproven Borland ABI compatibility.

## Ausgangslage / Current State

Der bestehende Job `Windows (BCC32) (DPMI32)` scheitert bereits bei zwei nicht mehr verfuegbaren GitHub-Anhaengen. Der Buildpfad und seine Artefakte sind Borland-spezifisch. Dieser Intake ist noch nicht startfaehig: Der vorgelagerte Machbarkeits-Intake muss `Completed` sein und ein gegen seine Pflichtkriterien belegtes `Go` enthalten.

*English:* The existing `Windows (BCC32) (DPMI32)` job fails at two unavailable GitHub attachments. Its build path and artifacts are Borland-specific. This intake cannot start until the predecessor feasibility intake is `Completed` with an evidenced `Go` against all mandatory criteria.

## Zielbild / Target State

Ein eindeutig als Open Watcom bezeichneter CI-Job bezieht eine unveraenderlich gepinnte Werkzeugkette aus offizieller Quelle, prueft ihre SHA-256-Summe, baut Bibliothek und drei DOS32-Beispiele, fuehrt einen DOS-/DPMI-Smoke-Test aus und veroeffentlicht nachvollziehbare Artefakte. Bestehende moderne Plattformbuilds und historische Borland-Quellen bleiben erhalten.

*English:* A clearly labelled Open Watcom CI job obtains an immutably pinned toolchain from an official source, verifies SHA-256, builds the library and three DOS32 examples, runs a DOS/DPMI smoke test, and publishes traceable artifacts. Existing modern platform builds and historic Borland sources remain preserved.

## Umfang / Scope

- Separater Open-Watcom-Build-Einstieg fuer die bisherige DOS32-Artefaktmenge.
- Reproduzierbarer, pruefsummengebundener Toolchain-Bezug ohne proprietaere Borland-/TASM-Archive.
- CI-Cutover mit ehrlicher Job- und Artefaktkennzeichnung.
- Build- und Laufzeitnachweis fuer Bibliothek, TVDemo, TVEdit und TVHC.
- Dokumentation der lokalen Reproduktion, Kompatibilitaetsgrenzen und Fehlerdiagnose.

*English:* Scope covers a separate Open Watcom build entry point, checksum-bound toolchain acquisition without proprietary archives, honest CI cutover, build/runtime evidence for the library and three examples, and reproducibility and compatibility documentation.

## Nicht-Ziele / Non-Goals

1. Kein Start ohne `Completed` plus `Go` des Machbarkeits-Intakes.
2. Keine stillschweigende Umschreibung oder Loeschung historischer Borland-Makefiles.
3. Keine Beibehaltung der Bezeichnung `BCC32`, wenn Open Watcom verwendet wird.
4. Keine Behauptung, Open-Watcom-Bibliotheken seien binaer mit BCC32 kompatibel.
5. Keine Ausweitung auf DOS16, Real Mode, Overlay-Builds oder den allgemeinen CMake-Compilervertrag.
6. Keine Verteilung von Borland C++ 4.5, TASM 4 oder daraus uebernommenen Binaerbestandteilen.

*English:* This intake does not start without the predecessor `Go`, silently rewrite historic files, retain a false BCC32 label, claim binary compatibility, expand to other DOS modes or general CMake policy, or distribute proprietary Borland/TASM material.

## Anforderungen / Requirements

- **FR-001:** Pruefe vor jeder Aenderung den exakten Machbarkeitsbericht, seinen Git-Head, die Abschlussentscheidung `Go`, den untersuchten Open-Watcom-Stand und alle Pflichtnachweise.
- **FR-002:** Stoppe fail-closed bei `No-Go`, `NeedsFurtherEvidence`, Hash-Drift, abweichender Werkzeugversion oder fehlender Lizenz-/Lieferkettenevidence.
- **FR-003:** Fuehre einen von den historischen Borland-Makefiles getrennten Open-Watcom-Build-Einstieg ein; gemeinsame Quellen duerfen genutzt, historische Buildvertraege aber nicht unbemerkt ersetzt werden.
- **FR-004:** Pinne einen unveraenderlichen Open-Watcom-Release-Tag oder Commit und verifiziere das verwendete Archiv vor Ausfuehrung mit der im Projekt dokumentierten SHA-256-Summe.
- **FR-005:** Verwende keine beweglichen Aliase wie `Current-build` als produktives Pinning und keine proprietaeren Borland-/TASM-Downloads.
- **FR-006:** Baue die DOS32-Bibliothek sowie `tvdemo.EXE`, `tvedit.EXE` und `tvhc.EXE` mit dem im Go-Bericht freigegebenen Compiler-, Linker-, Bibliotheks- und Assemblerpfad.
- **FR-007:** Fuehre mindestens fuer `tvdemo.EXE` einen deterministischen Start- und Beendigungs-Smoke-Test in dem freigegebenen DOS-/DPMI-Runner aus.
- **FR-008:** Benenne den CI-Job `Windows (Open Watcom) (DPMI32)`; Ausgaben duerfen nicht als BCC32-ABI-Nachweis beschrieben werden.
- **FR-009:** Bewahre die bestehenden logischen Artefaktnamen `examples-dos32` und `library-dos32`, sofern der Go-Bericht keinen belegten Konflikt zeigt, und fuege Toolchain-, Version- und Checksum-Metadaten hinzu.
- **FR-010:** Fuehre bestehende CMake-/Compilerjobs unveraendert aus und belege, dass der neue DOS32-Pfad sie nicht beeinflusst.
- **FR-011:** Setze minimale GitHub-Actions-Berechtigungen, pinne verwendete Actions nach Repositoryvertrag und verhindere, dass Logs private Pfade, Tokens oder vollstaendige Umgebungsinhalte ausgeben.
- **FR-012:** Dokumentiere lokale Reproduktion, erwartete Artefakte, Runner, Fehlerklassen, Kompatibilitaetsgrenzen und Rueckfallverfahren deutsch zuerst/englisch danach.
- **FR-013:** Entferne den defekten proprietaeren Downloadpfad erst, nachdem der neue Job auf demselben exakten Head alle Build-, Laufzeit-, Sicherheits- und Lieferkettengates bestanden hat.

*English:* Migration must revalidate the exact `Go`, fail closed on drift, add a separate build entry point, pin and checksum an immutable official toolchain, avoid moving aliases and proprietary downloads, build the library and three examples, run the approved DPMI smoke test, label the job honestly, preserve logical artifact names where compatible, protect current builds, minimize CI privilege and data exposure, document reproduction and rollback, and remove the dead path only after all exact-head gates pass.

## Qualitaet und Governance / Quality and Governance

- C++14 bleibt die oeffentliche Sprachbasis; bestehende moderne Compiler- und CMake-Vertraege duerfen nicht geschwaecht werden. / C++14 remains the public language baseline; existing modern compiler and CMake contracts must not be weakened.
- Die begruendete Nicht-MSL-Ausnahme fuer das C++-Kompatibilitaetsprojekt bleibt in Plan-, Task- und Review-Evidence sichtbar. / The justified non-MSL exception for this C++ compatibility project remains visible in plan, task, and review evidence.
- C/C++-, Assembler-, Datei- und Prozessgrenzen werden sicherheitsorientiert geprueft; kein `eval`, keine ungeprueften Pfade oder ungebundenen Downloads. / C/C++, assembly, file, and process boundaries receive security-focused review; no `eval`, unchecked paths, or unbound downloads.
- Nutzerseitige Status- und Fehlerausgaben sind textorientiert, ohne Farbe als einziges Signal, DE-first/EN-second, CEFR B2 und nach anwendbaren WCAG-2.2-AA-Kriterien nutzbar. / User-facing status and errors are text-first, do not rely on color, and follow German-first/English-second, CEFR B2, and applicable WCAG 2.2 AA.
- Documentation Impact ist `UpdateRequired`. / Documentation Impact is `UpdateRequired`.

## Datenschutz und Lieferkette / Privacy and Supply Chain

Logs, Artefaktmetadaten und Screenshots verwenden synthetische oder redigierte Daten und enthalten keine privaten absoluten Pfade, Secrets oder echten Benutzerinhalte. Jede Toolchain-, Runner- oder Action-Abhaengigkeit erhaelt Zweck, Owner, offizielle Herkunft, Lizenzstatus, unveraenderliche Version beziehungsweise Commit, SHA-256 oder Commit-Pin, minimale Berechtigungen und Re-Evaluation-Trigger.

*English:* Logs, artifact metadata, and screenshots use synthetic or redacted data and contain no private paths, secrets, or real user content. Every toolchain, runner, or action dependency records purpose, owner, official origin, license status, immutable version or commit, checksum or commit pin, least privilege, and reevaluation trigger.

## Abhaengigkeiten und Risiken / Dependencies and Risks

Die Kante vom Machbarkeits- zum Migrations-Intake ist `AssessmentBaseline` und bindend. `Completed` allein reicht fachlich nicht: Die versionierte Abschlussentscheidung muss `Go` sein. Vor operativer Aktivierung muss ausserdem die bestehende Beispiel-/Dokumentationsserie abgeschlossen sein.

Risiken sind abweichende Objekt- und Bibliotheksformate, Assemblersemantik, DOS-Extender- und DPMI-Verhalten, volatile Upstream-Builds, grosse Toolchain-Downloads und falsche Kompatibilitaetsaussagen. Ein Rueckfall darf den defekten Downloadpfad nicht als erfolgreich darstellen.

*English:* The predecessor edge is a binding `AssessmentBaseline`; `Completed` alone is insufficient without a versioned `Go`. Operational activation also waits for the existing series to finish. Risks include binary formats, assembler and DPMI behavior, volatile upstream builds, large downloads, and misleading compatibility claims.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- Separater Open-Watcom-DOS32-Build-Einstieg und zugehoerige Konfiguration
- Aktualisierter Workflow `.github/workflows/cmake.yml`
- Lokale Build- und Runner-Dokumentation
- CI-Evidence fuer Bibliothek, drei Beispiele, Laufzeitsmoke, Lieferkette und bestehende Plattformmatrix
- Rueckfall- und Kompatibilitaetsnachweis

Jeder Nachweis nennt exakten Git-Head, Toolchain-Version oder Commit, Archiv-SHA-256, Actions-Pins, Runner-Version und ausgefuehrte Befehle. Generierte EXE-, LIB-, OBJ- und Toolchain-Dateien bleiben ungetrackt.

*English:* Evidence names the exact Git head, toolchain version or commit, archive SHA-256, action pins, runner version, and commands actually executed. Generated binaries and toolchain files remain untracked.

## Akzeptanzkriterien / Acceptance Criteria

- **AC-001:** Ein aktueller, hashpassender Machbarkeitsbericht steht auf `Go`; alle dortigen Pflichtbedingungen sind weiterhin erfuellt.
- **AC-002:** Ein sauberer Runner bezieht ausschliesslich den gepinnten offiziellen Open-Watcom-Kandidaten und stoppt bei falscher SHA-256-Summe vor Ausfuehrung.
- **AC-003:** Bibliothek, `tvdemo.EXE`, `tvedit.EXE` und `tvhc.EXE` werden reproduzierbar gebaut und als Open-Watcom-Ausgaben gekennzeichnet.
- **AC-004:** Der DOS-/DPMI-Smoke-Test besteht auf demselben exakten Head.
- **AC-005:** Der CI-Job heisst `Windows (Open Watcom) (DPMI32)`; `examples-dos32` und `library-dos32` enthalten Toolchain- und Checksum-Metadaten.
- **AC-006:** Kein Workflow-Schritt laedt oder verteilt Borland C++ 4.5 oder TASM 4; keine solche Binaerdatei ist getrackt.
- **AC-007:** Die bestehende Plattformmatrix und ihre Tests bestehen unveraendert.
- **AC-008:** Sicherheits-, Lizenz-, Lieferketten-, Dokumentations- und A11Y-Nachweise sind vollstaendig und enthalten keine privaten Daten.
- **AC-009:** Der defekte BCC32-Downloadpfad ist erst nach erfolgreichem Exact-Head-Nachweis entfernt; historische Quell- und Makefile-Evidence bleibt erhalten.
- **AC-010:** Dokumentation bezeichnet den neuen Pfad nicht als Borland-ABI- oder Drop-in-kompatibel.

*English:* Acceptance requires a current matching `Go`, checksum-verified official acquisition, reproducible library and example builds, DPMI runtime success, honest Open Watcom job and artifact metadata, no proprietary downloads, unchanged existing platform tests, complete security/supply-chain/documentation/A11Y evidence, controlled cutover, preserved historic evidence, and no unsupported ABI claim.

## Verbindliches Serien- und Start-Gate / Binding Series and Start Gate

`ReadyForReview` beschreibt nur die Qualitaet dieses Authoring-Artefakts. Vor Specify oder Umsetzung muessen ein aktueller akzeptierter Series Review mit passendem Zielhash, ein driftfrei validiertes spaeteres Sequencing-Manifest, dieser Intake als `Eligible`, der Machbarkeits-Intake als `Completed` und dessen Abschlussentscheidung als `Go` belegt sein. Bis zum Abschluss der bestehenden aktiven Serie wird keine operative Serie fuer dieses Vorhaben angelegt. Eligibility erteilt keine Implementierungs- oder Remote-Berechtigung.

*English:* `ReadyForReview` describes authoring quality only. Specify or implementation requires a current accepted Series review, matching target hash, a drift-free future sequencing manifest, this intake as `Eligible`, the feasibility predecessor as `Completed`, and its decision as `Go`. No operational series is created before the existing active series finishes. Eligibility grants no implementation or remote authority.

## Annahmen und offene Fragen / Assumptions and Open Questions

Die Entscheidungen `IAD001` und `IAD002` sind beantwortet. Es bestehen keine offenen Authoring-Entscheidungen. Technische Auswahlentscheidungen duerfen nur aus dem spaeteren `Go` uebernommen und muessen bei Drift erneut geprueft werden.

*English:* Decisions `IAD001` and `IAD002` are answered. No authoring decisions remain open. Technical selections may only be inherited from the later `Go` and must be revalidated on drift.

<!-- intake-authoring:prompts -->
## Kopierfertige Spec-Kit-Prompts / Copy-Ready Spec Kit Prompts

<!-- spec-kit-command-id: speckit.specify -->
### Specify

```text
$speckit-specify
Nutze intakes/tvision-open-watcom-dos-dpmi-ci-migration.md als alleinige fachliche Anforderungsquelle. Pruefe vor dem Start den aktuellen akzeptierten Series Review, den passenden Zielhash, ein driftfrei validiertes operatives Sequencing-Manifest, diesen Intake als Eligible, den Machbarkeits-Intake als Completed und dessen Abschlussentscheidung als Go. Stoppe bei fehlender Evidence, Drift oder Blocker fail-closed. Erstelle ausschliesslich die Feature-Spezifikation; implementiere nichts und fuehre keine Remote-Schreibaktion aus. Bewahre C++14, historische Borland-Dateien, ehrliche Kompatibilitaetsgrenzen, die Nicht-MSL-Begruendung, Lieferkettenkontrollen, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-open-watcom-dos-dpmi-ci-migration.md als alleinige fachliche Anforderungsquelle. Pruefe vor dem Start den aktuellen akzeptierten Series Review, den passenden Zielhash, ein driftfrei validiertes operatives Sequencing-Manifest, diesen Intake als Eligible, den Machbarkeits-Intake als Completed und dessen Abschlussentscheidung als Go. Stoppe bei fehlender Evidence, Drift oder Blocker fail-closed. Arbeite ausschliesslich mit Delivery Authority LocalImplementation: kein Commit, Push, Pull Request, Merge, Admin-Bypass, Home-Sync oder Start eines Folge-Intakes. Bewahre C++14, historische Borland-Dateien, ehrliche Kompatibilitaetsgrenzen, die Nicht-MSL-Begruendung, Lieferkettenkontrollen, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- intake-authoring:end -->
