# Projektstatistik / Project Statistics — tvision

> **Lebendiges Dokument / Living document** — nach jedem abgeschlossenen Feature,
> jeder Spec-Kit-Phase und auf explizite Anfrage aktualisieren.
>
> *Update after every completed feature, Spec-Kit phase, or on explicit request.*

---

## Fortschreibungsprotokoll / Update Log

Ältester Eintrag oben, neuester Eintrag unten.
*Oldest entry at top, newest entry at bottom.*

| Datum / Date | Phase / Branch | Aktivtage ges. | Zeilen ges. | Commits ges. | Hauptarbeitspakete / Main Work Packages |
|---|---|---:|---:|---:|---|
| 2026-08-09 | 0 — Bootstrap | 1 | — | 1 | Documentation Impact `UpdateRequired`: Level-2-Governance, C++14/CMake-Kontext, begruendete Nicht-MSL-Ausnahme, Zwölfer-Presetprofil und Wartungspaket via `bootstrap-project`; bestehende Upstream-README und Produktquellen bleiben unverändert. |
| 2026-08-11 | Cross-platform development guide | 26 | 202979 | 53 | Documentation Impact `UpdateRequired`: ausfuehrliche bilinguale Anleitung fuer CLion, CMake-Kommandozeile und VS Code Light unter macOS, Windows und Linux; macOS Develop-First, reproduzierbares FetchContent-Pinning und 8-GB-/Small-Disk-Profil. |

---

## Gesamtstand des Repositories / Repository Snapshot

Stand / As of: 2026-08-09 — *Erste Einträge nach dem initialen Arbeitspaket eintragen.*

| Kategorie / Category | Dateien / Files | Zeilen / Lines | Anteil / Share |
|---|---:|---:|---:|
| Produktionscode / Production code | — | — | — |
| Tests / Tests | — | — | — |
| Dokumentation / Documentation (.md) | — | — | — |
| **Gesamt / Total** | — | — | — |

---

## Statistikprofil-1-Archiv / Statistics Profile 1 Archive
*Wird nach dem ersten dokumentierten Arbeitspaket befüllt.*
*To be filled after the first documented work package.*

| Kennzahl / Metric | Verdichteter Gesamtblick / Condensed Overview |
|---|---:|
| Artefaktbasis gesamt | — |
| Beobachtbarer Projektzeitraum | 2026-08-09 bis — |
| Sichtbare Git-Aktivtage | — |
| Repo-weiter Speedup gg. 80-Zeilen-Referenz | — |
| Repo-weiter Speedup gg. Thorsten-Referenz | — |

## Dokumentationsauswirkung / Documentation Impact

Die im Fortschreibungsprotokoll erfasste Entscheidung `UpdateRequired` gilt
für das jeweilige Arbeitspaket.

*The `UpdateRequired` decision recorded in each update-log entry applies to
that work package.*

- Quelle und Owner / Source and owner: Benutzerauftrag und Level-0-Flottenmanifest; Owner Thorsten Hindermann.
- Betroffene Dokumente / Affected documents: erhaltene Upstream-`README.md`, `constitution.md`, gemeinsame Agenten-Guidance, Skriptreferenz, Wartungs- und Preset-Dokumentation.
- Zielgruppen und Leserpfad / Audiences and reader path: C++-/CLion-Nutzende und KI-Agenten starten in `README.md`, wechseln zu `constitution.md` und folgen für Automationen `docs/scripts/`.
- Kanonische Quelle, Navigation und Dokumentklasse / Canonical source, navigation, and document class: `home-baseline-source` für Governance, `hindermath/tvision` für den Fork; verteilte Level-2-Governance mit bilingualer DE/EN-Führung.
- Plattform- und Beispielnachweis / Platform and example evidence: macOS/Darwin, Bash-Vorschau und produktiver Lauf, C++14/CMake-Kontext sowie zwölf Presets exakt gegen die Matrix geprüft.
- Distribution und Home-Sync / Distribution and home sync: repository distribution; kein zusätzlicher Home-Sync erforderlich.
- Re-Evaluation / Re-evaluation: bei Änderung von C++-ABI-/Plattformzielen, Nicht-MSL-Begründung, Presetprofil oder Wartungspaket.

### Cross-platform development guide 2026-08-11

- Quelle und Owner / Source and owner: Benutzerauftrag, lokale CMake-Zieldefinitionen und native macOS-Validierung; Owner Thorsten Hindermann.
- Betroffene Dokumente / Affected documents: `docs/clion-cross-platform-tvision-development.md` und dieses Statistik-Ledger.
- Zielgruppen und Leserpfad / Audiences and reader path: Entwickler waehlen CLion, CMake-Kommandozeile oder VS Code Light und bauen danach denselben gepinnten Fork-Stand nativ auf macOS, Windows und Linux.
- Kanonische Quelle, Navigation und Dokumentklasse / Canonical source, navigation, and document class: Level-2-CMake-Code als technische Quelle; bilingualer Entwicklerguide unter `docs/`.
- Plattform- und Beispielnachweis / Platform and example evidence: CMake-Preset-Schema, AppleClang-FetchContent-Build und interaktiver TUI-Start auf dem 8-GB-Develop-First-Mac; Windows und Linux bleiben native Kontrollschritte.
- Distribution und Home-Sync / Distribution and home sync: repository-spezifische Quellcode-Abhaengigkeit ueber FetchContent; kein Home-Sync.
- Re-Evaluation / Re-evaluation: bei Aenderung von tvision-CMake-Zielen, Plattformen, CMake Presets, CLion oder den Microsoft-Erweiterungen C/C++ und CMake Tools.

## Gesamtstatistik / Overall Statistics

<!-- project-statistics-v2:begin -->

Profil 2 verwendet Git-getrackte Textdateien und sichtbare Git-Aktivitaet. Die Werte beschreiben Lieferdichte, keine persoenliche Arbeitszeit.

*Profile 2 uses Git-tracked text files and visible Git activity. The values describe delivery density, not personal working time.*

| Kennzahl / Metric | Wert / Value |
|---|---:|
| Textbasis / Text base | 202979 lines |
| Textdateien / Text files | 1202 |
| Beobachtbarer Zeitraum / Observable period | 2025-08-17..2026-08-11 |
| Aktivtage / Active days | 26 |
| Relevante Commits / Relevant commits | 53 |
| Zeilen je Aktivtag / Lines per active day | 7806.9 |
| Peak-Tag im Fenster / Peak day in window | 2026-08-09 / 133528 |
| Peak-Woche im Fenster / Peak week in window | 2026-08-09 / 136395 |
| Laengste Serie / Longest streak | 3 days |
| Speedup vs. 80 lines/day | 97.6x |
| Speedup vs. 80 lines/day | 97.6x |
| Methodik / Methodology | v2; source `2a8f2be64129` |

### Artefaktmix / Artifact Mix

```text
Produktiv / Production          [######..............]  29.7% | 60218
Tests                           [#...................]   4.4% | 8951
Dokumentation / Documentation   [#########...........]  45.1% | 91492
Skripte / Scripts               [####................]  19.6% | 39863
Konfiguration / Configuration   [#...................]   0.2% | 376
Daten und Medien / Data and media [....................]   0.0% | 0
Sonstiger Text / Other text     [#...................]   1.0% | 2079
```

Die Balken teilen die aktuelle getrackte Textbasis in stabile Kategorien. Prozent und Zeilenwert sind die genaue, textorientierte Aussage.

*The bars split the current tracked text base into stable categories. Percentages and line counts provide the exact text-first result.*

### Tagesaktivitaet / Daily Activity

```text
Wochen / Weeks 01..26 | 2025-08-17..2026-02-14
So/Su  0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 3 0 2 0 0 1 0 0 0 0
Mo/Mo  0 0 0 1 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0
Di/Tu  0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
Mi/We  0 0 0 0 0 0 0 1 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0
Do/Th  0 0 0 0 0 0 0 1 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0
Fr/Fr  3 0 0 0 0 0 2 0 0 0 2 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0
Sa/Sa  1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0
```

```text
Wochen / Weeks 27..52 | 2026-02-15..2026-08-15
So/Su  0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 4
Mo/Mo  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2
Di/Tu  0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 4
Mi/We  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -
Do/Th  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -
Fr/Fr  0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -
Sa/Sa  0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -
```

DE: 0 = keine Aenderung; 1 = 1..79; 2 = 80..399; 3 = 400..1599; 4 = 1600+ geaenderte Textzeilen; - = noch nicht abgelaufen.

*EN: 0 = no change; 1 = 1..79; 2 = 80..399; 3 = 400..1599; 4 = 1600+ changed text lines; - = not elapsed.*

### Wochenvolumen / Weekly Volume

```text
Wochen / Weeks 01..26 | 2025-08-17..2026-02-14
    cap 2000 | . . . . . . . . . . . . . . . . . . . . . . . . . .
        1667 | . . . . . . . . . . . . . . . . . . . . . . . . . .
        1333 | . . . . . . . . . . # . . . . . . . . . . . . . . .
        1000 | . . . . . . . . . . # . . . . . . . . . . . . . . .
         667 | . . . . . . . . . . # . . . . . . . # . . . . . . .
         333 | # . . . . . . . . . # . . . . . # . # # . . . . . .
           0 +-----------------------------------------------------
```

```text
Wochen / Weeks 27..52 | 2026-02-15..2026-08-15
  cap 200000 | . . . . . . . . . . . . . . . . . . . . . . . . . .
      166667 | . . . . . . . . . . . . . . . . . . . . . . . . . .
      133333 | . . . . . . . . . . . . . . . . . . . . . . . . . #
      100000 | . . . . . . . . . . . . . . . . . . . . . . . . . #
       66667 | . . . . . . . . . . . . . . . . . . . . . . . . . #
       33333 | . . . . . . . . . . . . . . . . . . . . . . . . . #
           0 +-----------------------------------------------------
```

Das Wochenvolumen zeigt Additionen plus Loeschungen. Es ist Aenderungsaktivitaet, nicht die aktuelle Groesse des Repositories.

*Weekly volume shows additions plus deletions. It represents change activity, not the current repository size.*

### Kumulative Entwicklung / Cumulative Development

```text
Wochen / Weeks 01..26 | 2025-08-17..2026-02-14
    cap 5000 | . . . . . . . . . . . . . . . . . . . . . . . . . .
        4167 | . . . . . . . . . . . . . . . . . . # # # # # # # #
        3333 | . . . . . . . . . . . . . . . . . . # # # # # # # #
        2500 | . . . . . . . . . . . # # # # # # # # # # # # # # #
        1667 | . . . . . . . . . . # # # # # # # # # # # # # # # #
         833 | . . . . . . . # # # # # # # # # # # # # # # # # # #
           0 +-----------------------------------------------------
```

```text
Wochen / Weeks 27..52 | 2026-02-15..2026-08-15
  cap 200000 | . . . . . . . . . . . . . . . . . . . . . . . . . .
      166667 | . . . . . . . . . . . . . . . . . . . . . . . . . .
      133333 | . . . . . . . . . . . . . . . . . . . . . . . . . #
      100000 | . . . . . . . . . . . . . . . . . . . . . . . . . #
       66667 | . . . . . . . . . . . . . . . . . . . . . . . . . #
       33333 | . . . . . . . . . . . . . . . . . . . . . . . . . #
           0 +-----------------------------------------------------
```

Die kumulative Kurve summiert nur das Brutto-Aenderungsvolumen im Fenster. Sie darf nicht als aktuelle Codebasis gelesen werden.

*The cumulative curve sums gross change volume within the window only. It must not be read as the current code base.*

### Monatsvolumen / Monthly Volume

```text
Last 12 calendar months
  cap 200000 | . . . . . . . . . . . .
      166667 | . . . . . . . . . . . .
      133333 | . . . . . . . . . . . #
      100000 | . . . . . . . . . . . #
       66667 | . . . . . . . . . . . #
       33333 | . . . . . . . . . . . #
           0 +-------------------------
```

Es liegen keine belastbaren Phasendaten vor. Deshalb zeigt dieses Diagramm Monate und erfindet keine Projektphasen.

*No reliable phase series is available. This chart therefore shows months and does not invent project phases.*

### Beschleunigungsfaktoren / Acceleration Factors

```text
Scale: 0..100x
80 lines/day       [####################] 97.6x
80 lines/day       [####################] 97.6x
```

Die Faktoren vergleichen sichtbare Lieferdichte mit den dokumentierten manuellen Referenzen. Sie messen keine Arbeitszeit.

*The factors compare visible delivery density with documented manual references. They do not measure working time.*

### Durchsatzvergleich / Throughput Comparison

```text
Scale: 0..10000 lines/day
Experienced manual [#...................] 80
Thorsten solo      [#...................] 80
Visible repository [################....] 7806.9
```

Die gemeinsame Skala vergleicht Referenzen und sichtbare Lieferdichte. Sie schreibt die Git-Aktivitaet keiner Person oder KI pauschal zu.

*The common scale compares references with visible delivery density. It does not attribute Git activity to a person or AI by default.*

### Textalternative / Text Alternative

DE: Das Fenster beginnt am 2025-08-17 und endet am 2026-08-11. Es enthaelt 26 aktive und 334 inaktive vergangene Tage. Peak-Tag: 2026-08-09 / 133528. Peak-Woche: 2026-08-09 / 136395. Laengste Serie: 3 Tage (2025-10-07..2025-10-09).

*EN: The window starts on 2025-08-17 and ends on 2026-08-11. It contains 26 active and 334 inactive elapsed days. Peak day: 2026-08-09 / 133528. Peak week: 2026-08-09 / 136395. Longest streak: 3 days (2025-10-07..2025-10-09).*

| Monat / Month | Geaenderte Textzeilen / Changed text lines |
|---|---:|
| 2025-09 | 6 |
| 2025-10 | 2003 |
| 2025-11 | 331 |
| 2025-12 | 2010 |
| 2026-01 | 34 |
| 2026-02 | 0 |
| 2026-03 | 2 |
| 2026-04 | 16 |
| 2026-05 | 190 |
| 2026-06 | 0 |
| 2026-07 | 0 |
| 2026-08 | 136395 |

<!-- project-statistics-v2:end -->
