<!-- intake-authoring:begin -->
# Open-Watcom-DOS/DPMI-Machbarkeitspruefung / Open Watcom DOS/DPMI feasibility assessment

**Status:** ReadyForReview  
**Zielgruppe / Audience:** Primaer Maintainer sowie Build- und CI-Verantwortliche; sekundaer Beitragende und Lernende / Primarily maintainers and build/CI owners; secondarily contributors and learners  
**Vorauswissen / Assumed prior knowledge:** Grundlegende Kenntnisse von C++14, Makefiles und CI; keine Spec-Kit- oder Open-Watcom-Erfahrung vorausgesetzt / Basic C++14, makefile, and CI knowledge; no Spec Kit or Open Watcom experience assumed  
**Profil / Profile:** generic-markdown  
**Delivery Authority:** LocalImplementation

## Begriffe / Terms

- **DPMI:** DOS Protected Mode Interface, eine Schnittstelle fuer DOS-Programme im geschuetzten Prozessormodus. / **DPMI:** DOS Protected Mode Interface, an interface for DOS programs running in protected processor mode.
- **Open Watcom:** Offen verfuegbare C/C++-Werkzeugkette mit DOS-Zielplattformen; ihre konkrete Eignung ist Gegenstand dieses Intakes. / **Open Watcom:** An openly available C/C++ toolchain with DOS targets; its concrete suitability is the subject of this intake.
- **WMAKE und WASM:** Make-Werkzeug und Assembler der Open-Watcom-Werkzeugkette. / **WMAKE and WASM:** The make utility and assembler in the Open Watcom toolchain.
- **PoC:** Proof of Concept, ein begrenzter Machbarkeitsnachweis ohne Produktionsfreigabe. / **PoC:** Proof of concept, a bounded feasibility proof without production approval.
- **ABI:** Application Binary Interface, der Binaervertrag zwischen kompilierten Komponenten. / **ABI:** Application Binary Interface, the binary contract between compiled components.
- **Go/No-Go:** Dokumentierte Entscheidung, ob die spaetere Migration beginnen darf oder gesperrt bleibt. / **Go/No-Go:** A documented decision whether the later migration may start or remains blocked.

## Zweck / Purpose

Dieser Intake klaert belastbar, ob Open Watcom den nicht mehr reproduzierbaren BCC32-/TASM32-CI-Pfad fuer den 32-Bit-DOS-/DPMI-Build ersetzen kann. Die Untersuchung trennt technische Machbarkeit, Lieferkettennachweis und Kompatibilitaetsgrenzen von einer spaeteren Produktionsmigration.

*English:* This intake determines whether Open Watcom can replace the no-longer-reproducible BCC32/TASM32 CI path for the 32-bit DOS/DPMI build. It separates technical feasibility, supply-chain evidence, and compatibility boundaries from a later production migration.

## Ausgangslage / Current State

Der Workflow `build-windows-bcc32` laedt `BC45-32.zip` und `tasm4-32.zip` von nicht mehr verfuegbaren GitHub-Anhaengen. Danach fuehrt er den historischen Borland-Build mit `make.exe -DDOS32` aus und erwartet `TV32.LIB`, `tvdemo.EXE`, `tvedit.EXE` und `tvhc.EXE`. Die Bibliotheks- und Beispiel-Makefiles binden BCC32, TASM32, TLIB, TLINK32 sowie Borland-spezifische Konfigurationen ein. Ein Open-Watcom-Buildpfad existiert nicht.

*English:* The `build-windows-bcc32` workflow downloads `BC45-32.zip` and `tasm4-32.zip` from GitHub attachments that are no longer available. It then runs the historic Borland build with `make.exe -DDOS32` and expects `TV32.LIB`, `tvdemo.EXE`, `tvedit.EXE`, and `tvhc.EXE`. Library and example makefiles bind BCC32, TASM32, TLIB, TLINK32, and Borland-specific configuration. No Open Watcom build path exists.

## Zielbild / Target State

Ein versionierter Machbarkeitsbericht und reproduzierbare lokale PoC-Evidence fuehren zu genau einer Entscheidung: `Go`, `No-Go` oder `NeedsFurtherEvidence`. Nur `Go` mit allen Pflichtnachweisen darf den nachgelagerten Migrations-Intake entsperren.

*English:* A versioned feasibility report and reproducible local PoC evidence produce exactly one decision: `Go`, `No-Go`, or `NeedsFurtherEvidence`. Only `Go` with all required evidence may unblock the downstream migration intake.

## Umfang / Scope

- Lizenz-, Herkunfts- und Verteilungspruefung anhand offizieller Open-Watcom-Quellen, ohne Rechtsberatung zu behaupten.
- Auswahl eines unveraenderlichen Release- oder Commit-Kandidaten mit SHA-256-Nachweis.
- Inventar von Compiler-, Linker-, Bibliotheks-, Assembler-, Makefile-, Makro- und Laufzeitunterschieden.
- Isolierter PoC fuer Bibliothek und die drei bisherigen DOS32-CI-Beispiele.
- Deterministischer DOS-/DPMI-Laufzeitsmoke-Test mit einem offen verfuegbaren Runner.
- Dokumentierte Go-/No-Go-Entscheidung mit Rest- und Folgerisiken.

*English:* Scope covers official-source license and provenance review without claiming legal advice, immutable version and checksum selection, toolchain and runtime compatibility inventory, an isolated library and three-example PoC, a deterministic DOS/DPMI runtime smoke test using an openly available runner, and a documented decision with residual risks.

## Nicht-Ziele / Non-Goals

1. Keine Aenderung des produktiven CI-Workflows.
2. Keine Entfernung oder Umschreibung historischer Borland-Makefiles.
3. Keine Verteilung proprietaerer Borland- oder TASM-Binaerdateien.
4. Keine Behauptung einer Borland-ABI- oder Drop-in-Kompatibilitaet.
5. Keine kurzfristige Umstellung des gesamten C++-/CMake-Builds.

*English:* This intake does not change production CI, remove historic Borland makefiles, distribute proprietary binaries, claim Borland ABI or drop-in compatibility, or replace the general C++/CMake build.

## Anforderungen / Requirements

- **FR-001:** Erfasse die aktuelle BCC32-/TASM32-Buildkette, ihre Eingaben, Ausgaben und Borland-spezifischen Annahmen nachvollziehbar.
- **FR-002:** Pruefe offizielle Open-Watcom-Lizenz- und Release-Evidence sowie die Bedingungen fuer CI-Download, Nutzung und Artefaktverteilung; Unsicherheit wird als offener Rechtspruefpunkt ausgewiesen.
- **FR-003:** Waehle fuer den PoC einen unveraenderlichen Release-Tag oder Commit und pruefe jedes heruntergeladene Archiv vor Nutzung mit einer dokumentierten SHA-256-Summe.
- **FR-004:** Ordne BCC32, TASM32, TLIB, TLINK32 und Borland Make ihren moeglichen Open-Watcom-Gegenstuecken zu und dokumentiere inkompatible Optionen und Semantiken.
- **FR-005:** Untersuche alle fuer DOS32 benoetigten Assemblerquellen und belege entweder den WASM-Pfad oder einen fachlich gleichwertigen, begruendeten `NOTASM`-Pfad.
- **FR-006:** Baue in einer isolierten, nicht produktiven Umgebung eine Open-Watcom-DOS32-Bibliothek sowie `tvdemo.EXE`, `tvedit.EXE` und `tvhc.EXE` oder dokumentiere den exakten reproduzierbaren Blocker.
- **FR-007:** Starte mindestens `tvdemo.EXE` in einem offen verfuegbaren DOS-/DPMI-Runner und pruefe einen deterministischen Start- und Beendigungs-Smoke-Test.
- **FR-008:** Pruefe, dass der PoC keine proprietaeren Toolchain-Archive, Zugangsdaten, privaten Pfade oder getrackten Binaerausgaben einfuehrt.
- **FR-009:** Dokumentiere Auswirkungen auf Quell-, Artefakt- und ABI-Kompatibilitaet getrennt; ein Open-Watcom-Erfolg darf nicht als BCC32-Binaerkompatibilitaet bezeichnet werden.
- **FR-010:** Schliesse mit genau `Go`, `No-Go` oder `NeedsFurtherEvidence` und begruende die Entscheidung gegen die Akzeptanzkriterien.

*English:* The assessment must inventory the existing chain, verify official licensing and immutable supply-chain evidence, map compiler/assembler/linker/make semantics, exercise the assembly or justified fallback path, build the library and three examples in isolation, run a deterministic DPMI smoke test, exclude proprietary or private material, distinguish source/artifact/ABI compatibility, and end with one explicit decision.

## Qualitaet und Governance / Quality and Governance

- C++14 und die bestehenden CMake-Plattformbuilds bleiben unveraendert. / C++14 and existing CMake platform builds remain unchanged.
- Open Watcom ist keine speichersichere Sprache beziehungsweise Laufzeit; die bestehende begruendete Nicht-MSL-Ausnahme bleibt sichtbar. / Open Watcom is not a memory-safe language or runtime; the existing justified non-MSL exception remains visible.
- Unsichere C-/C++- und Assemblergrenzen, Dateipfade sowie DOS-/DPMI-Eingaben werden nach den bestehenden Secure-Coding-Regeln geprueft. / Unsafe C/C++ and assembly boundaries, file paths, and DOS/DPMI inputs follow existing secure-coding rules.
- Nutzerseitige Dokumentation und Statusausgaben sind textorientiert, deutsch zuerst/englisch danach, CEFR B2 und nach anwendbaren WCAG-2.2-AA-Kriterien nutzbar. / User-facing documentation and status output are text-first, German-first/English-second, CEFR B2, and usable under applicable WCAG 2.2 AA criteria.
- Documentation Impact ist `UpdateRequired`; der kanonische Machbarkeitsbericht ist versioniert. / Documentation Impact is `UpdateRequired`; the canonical feasibility report is versioned.

## Datenschutz und Lieferkette / Privacy and Supply Chain

Datenschutz ist anwendbar: Logs und Evidence enthalten keine privaten absoluten Pfade oder echten Benutzerinhalte. Lieferkette ist anwendbar: Herkunft, Lizenz, unveraenderliche Version, SHA-256, minimale CI-Berechtigungen und Aufbewahrung jedes neuen Werkzeugs oder Runners werden dokumentiert. Ein beweglicher Alias wie `Current-build` darf nur zur Recherche dienen, nicht als reproduzierbares Pinning.

*English:* Privacy applies: logs and evidence contain no private absolute paths or real user content. Supply-chain controls record origin, license, immutable version, SHA-256, least CI privilege, and retention for every new tool or runner. A moving alias such as `Current-build` may inform research but cannot serve as reproducible pinning.

## Abhaengigkeiten und Risiken / Dependencies and Risks

Dieser Intake ist die einzige Root der nachgelagerten Authoring-Serie. Die bereits aktive Beispiel-/Dokumentationsserie bleibt unveraendert und muss vor einer operativen Aktivierung dieser Serie abgeschlossen sein. Der Migrations-Intake benoetigt zusaetzlich einen abgeschlossenen Machbarkeitslauf mit dokumentiertem `Go`.

Wesentliche Risiken sind Unterschiede der C++-Dialekte, Objekt- und Bibliotheksformate, Assemblersemantik, DOS-Extender, DPMI-Laufzeitverhalten sowie eine nicht hinreichend belegbare Lizenz- oder Verteilungslage.

*English:* This intake is the only root of the downstream authoring series. The active examples/documentation series remains unchanged and must finish before operational activation. Migration additionally requires this assessment to complete with `Go`. Key risks include language, object/library format, assembler, DOS extender, DPMI runtime, and license/distribution differences.

## Erwartete Artefakte und Evidenz / Expected Artifacts and Evidence

- `docs/plans/open-watcom-dos-dpmi-feasibility.md`
- Reproduzierbare PoC-Befehle und redigierte Build-/Laufzeitevidence
- Version-, Herkunfts-, Lizenz- und SHA-256-Nachweis
- Kompatibilitaetsmatrix und abschliessende Go-/No-Go-Entscheidung

Evidence nennt den exakten Git-Head, die Open-Watcom-Version beziehungsweise den Commit, alle Pruefsummen und die tatsaechlich ausgefuehrten Befehle. PoC-Binaerdateien bleiben ungetrackt.

*English:* Evidence names the exact Git head, Open Watcom version or commit, checksums, and commands actually run. PoC binaries remain untracked.

## Akzeptanzkriterien / Acceptance Criteria

- **AC-001:** Offizielle Herkunft, Lizenztext und ein unveraenderlicher Kandidat mit SHA-256 sind belegt; eine notwendige Rechtspruefung ist klar abgegrenzt.
- **AC-002:** Bibliothek und alle drei bisherigen CI-Beispiele werden reproduzierbar gebaut oder jeder Blocker ist mit minimaler Reproduktion dokumentiert.
- **AC-003:** Mindestens `tvdemo.EXE` besteht einen deterministischen DOS-/DPMI-Start- und Beendigungs-Smoke-Test.
- **AC-004:** Assemblerpfad oder fachlich gleichwertiger Fallback ist nachgewiesen; keine proprietaeren Toolchain-Binaerdateien werden gespeichert oder verteilt.
- **AC-005:** Bestehende CMake-Builds und getrackte historische Borland-Dateien bleiben unveraendert.
- **AC-006:** Der Bericht trennt Source-, Artefakt- und ABI-Kompatibilitaet und enthaelt genau eine begruendete Abschlussentscheidung.
- **AC-007:** Nur bei `Go` sind Aufwand, notwendige Aenderungen, Sicherheits-/Lieferkettenkontrollen und Rest-Risiken hinreichend begrenzt, um den Migrations-Intake freizugeben.

*English:* Acceptance requires official and immutable supply-chain evidence, reproducible library and example builds or exact blockers, a DPMI runtime smoke test, a proven assembler or equivalent fallback path, no proprietary redistribution, unchanged existing builds and historic files, explicit compatibility boundaries, and exactly one justified decision.

## Verbindliches Serien- und Start-Gate / Binding Series and Start Gate

`ReadyForReview` beschreibt nur die Qualitaet dieses Authoring-Artefakts. Vor Specify oder Umsetzung muessen ein aktueller akzeptierter Series Review mit passendem Zielhash, ein driftfrei validiertes spaeteres Sequencing-Manifest, dieser Intake als `Eligible` und alle bindenden Vorgaenger als `Completed` belegt sein. Bis zum Abschluss der bestehenden aktiven Serie wird keine operative Serie fuer dieses Vorhaben angelegt. Eligibility erteilt keine Implementierungs- oder Remote-Berechtigung.

*English:* `ReadyForReview` describes authoring quality only. Specify or implementation requires a current accepted Series review with matching target hash, a drift-free future sequencing manifest, this intake as `Eligible`, and all binding predecessors `Completed`. No operational series is created until the existing active series completes. Eligibility grants no implementation or remote authority.

## Annahmen und offene Fragen / Assumptions and Open Questions

Die Entscheidungen `IAD001` und `IAD002` sind beantwortet. Es bestehen keine offenen Authoring-Entscheidungen. Die Machbarkeitspruefung darf `No-Go` ergeben; sie nimmt die technische oder rechtliche Eignung von Open Watcom nicht vorweg.

*English:* Decisions `IAD001` and `IAD002` are answered. No authoring decisions remain open. The assessment may conclude `No-Go`; it does not presume technical or legal suitability.

<!-- intake-authoring:prompts -->
## Kopierfertige Spec-Kit-Prompts / Copy-Ready Spec Kit Prompts

<!-- spec-kit-command-id: speckit.specify -->
### Specify

```text
$speckit-specify
Nutze intakes/tvision-open-watcom-dos-dpmi-feasibility.md als alleinige fachliche Anforderungsquelle. Pruefe vor dem Start den aktuellen akzeptierten Series Review, den passenden Zielhash, ein driftfrei validiertes operatives Sequencing-Manifest, diesen Intake als Eligible und alle bindenden Vorgaenger als Completed. Stoppe bei fehlender Evidence, Drift oder Blocker fail-closed. Erstelle ausschliesslich die Feature-Spezifikation; implementiere nichts und fuehre keine Remote-Schreibaktion aus. Bewahre C++14, historische Borland-Dateien, die Nicht-MSL-Begruendung, Lieferkettenkontrollen, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- spec-kit-command-id: speckit.autonomous -->
### Autonomous

```text
$speckit-autonomous
Nutze intakes/tvision-open-watcom-dos-dpmi-feasibility.md als alleinige fachliche Anforderungsquelle. Pruefe vor dem Start den aktuellen akzeptierten Series Review, den passenden Zielhash, ein driftfrei validiertes operatives Sequencing-Manifest, diesen Intake als Eligible und alle bindenden Vorgaenger als Completed. Stoppe bei fehlender Evidence, Drift oder Blocker fail-closed. Arbeite ausschliesslich mit Delivery Authority LocalImplementation: kein Commit, Push, Pull Request, Merge, Admin-Bypass, Home-Sync oder Start des Folge-Intakes. Bewahre C++14, historische Borland-Dateien, die Nicht-MSL-Begruendung, Lieferkettenkontrollen, DE-first/EN-second, CEFR B2, WCAG 2.2 AA und die dokumentierten Nicht-Ziele.
```

<!-- intake-authoring:end -->
