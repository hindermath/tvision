# GitHub Copilot Agent Instructions — tvision

Diese Agentenfläche ergänzt [die allgemeinen Copilot-Anweisungen](../copilot-instructions.md).
Sie hält die projektspezifischen Fakten für agentische Aufgaben kurz und
textorientiert fest.

*This agent surface supplements [the general Copilot instructions](../copilot-instructions.md).
It keeps the project-specific facts for agentic work concise and text-oriented.*

- Primärsprache ist C++14 mit CMake. Der Build mit Tests verwendet
  `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DTV_BUILD_TESTS=ON` und
  `cmake --build build`.
- Die Nicht-MSL-Ausnahme beruht auf der notwendigen Borland-/Turbo-Vision-
  Quell- und ABI-Kompatibilität über Unix-, Windows- und DOS-Ziele hinweg.
- Eingaben, Puffergrenzen, Zeigerlebenszeiten und Terminal-I/O benötigen bei
  Änderungen eine explizite Secure-Coding-Prüfung.
- Bestehende englische Upstream-Dokumentation bleibt erhalten. Neue lokale
  Governance-Inhalte stehen Deutsch zuerst und Englisch danach.
- Nach vollständig beendeten Python-Testläufen dürfen regenerierbare
  `__pycache__/`-Verzeichnisse und `*.pyc`-, `*.pyo`- und `*.pyd`-Dateien
  entfernt werden; niemals löschen, solange ein zugehöriger Python-Prozess
  noch läuft.
- Die konservative und vorläufige Thorsten-Solo-Referenz beträgt jeweils
  `80` Zeilen/Arbeitstag; ein eigener C++-Speedup braucht eine begründete
  Neufestlegung.

*The primary language is C++14 with CMake. The non-MSL exception preserves
Borland/Turbo Vision source and ABI compatibility across Unix, Windows, and
DOS targets. Changes require explicit secure-coding review of input, buffer
bounds, pointer lifetimes, and terminal I/O. Existing English upstream
documentation is preserved; new local governance content is German-first and
English-second. After Python test runs have fully finished, regenerable
`__pycache__/` directories and `*.pyc`, `*.pyo`, and `*.pyd` files may be
removed; never delete them while a related Python process is still running.
Both conservative and provisional Thorsten-solo references
remain `80` lines per workday until a justified C++ baseline is adopted.*

<!-- BEGIN spec-kit-diagrams-completion -->
## Mermaid und Spec-Kit-Abschlussbericht / Mermaid and Spec Kit completion report

Neue Lastenhefte enthalten bei hilfreichen Abläufen, Zuständen oder Abhängigkeiten
lesbaren Mermaid-Quelltext im Markdown und eine gleichwertige Textalternative.
Bei einfachen Inhalten die Nichtanwendung kurz begründen. Diagramme bilden die
verbindlichen Text-/Manifestquellen ab; Farbe allein trägt keine Bedeutung.
Nach jedem vollständig abgeschlossenen Spec-Kit-Feature-Lauf den vollständigen
Ergebnisbericht im Chat anzeigen und im Feature-Verzeichnis als
`completion-report.md` versionieren. Einzelne Planungs-/Status-/Review-Kommandos
lösen keinen solchen Bericht aus; blockierte oder pausierte Läufe als
Zwischenbericht kennzeichnen. Vorlage: `.specify/templates/completion-report-template.md`;
Regel: `docs/spec-kit-diagrams-and-completion-reports.md`.
Ergebnis, Tests, Dokumentation, Git-gebundene Umfangszahlen, Verlauf und Restpunkte
belegen. Programmlogik von generierter Evidence, Git-Wandzeit von aktiver
Arbeitszeit und bestandene von ausgefallenen Prüfungen unterscheiden. Finale
Merge-/Sync-Evidence im Chat und bestehenden Closeout-Nachweis ergänzen; keine
zusätzlichen Commits allein für selbstreferenzielle Berichts-/Statistikwerte.
Diese Projektregel und lokale Vorlagen bei Spec-Kit-Updates erhalten.

*New intakes use readable Mermaid Markdown and equivalent text alternatives for
useful workflows, states or dependencies; justify omission for simple content.
Diagrams reflect authoritative text/manifests and never rely on color alone.
After each completed feature run, show the full outcome report in chat and
version completion-report.md in the feature directory using the shared template
and rule above. Individual planning/status/review commands do not trigger it;
paused/blocked runs receive interim reports. Evidence outcomes, tests, docs,
Git-bound counts, delivery history and remaining work. Distinguish code from
volume generated as evidence, elapsed from active time, and passed from failed
checks. Add final merge/sync proof in chat and existing closeout evidence, without
commits solely for self-referential counts or IDs. Preserve local rules/templates
across Spec Kit updates.*
<!-- END spec-kit-diagrams-completion -->

<!-- project-statistics-rollout:begin -->
## Statistik-Preset und Pflege / Statistics preset and maintenance

Das aktuelle Projektprofil ist `project-statistics-fourteen-governance-presets`:
bestehende 12er-Basis plus Assurance v0.1.3 bei Prioritaet 15 und Statistik
v0.1.0 bei Prioritaet 90. Dieser Projektvertrag hat Vorrang vor alten Profilangaben. Globale Defaults
bleiben erhalten; die operative lokale Zuordnung folgt erst nach Lieferung.
`docs/project-statistics/config.json` steuert den getrennten UTC-/52-Wochen-Kontext.
Profil 2 bleibt kanonisch; Referenzmodelle im neuen Kontext bleiben aus.
Nach abgeschlossenem Feature/Implementierungsabschnitt Inhalte zuerst committen,
Update ausdruecklich beauftragen und vorab im Dry-Run pruefen. Beide Statistiken
aus derselben Inhaltsrevision pflegen, Ausgaben committen und lesend verifizieren.
Keine Personen-, Lernleistungs-, Qualitaets-, Sicherheits- oder KI-Produktivitaetsbewertung.
Bedienung: `docs/project-statistics/README.md`; Quellen und Abnahme:
`docs/maintenance/project-statistics-rollout-v010.md`. Kein automatischer
Spec-Kit-Lauf und keine Commit-/Push-/Merge- oder menschliche Freigabe durch das Preset.

The current profile adds assurance v0.1.3 at priority 15 and statistics v0.1.0
at priority 90 to the unchanged twelve-preset base. This overrides older profile guidance. Preserve global defaults and defer operational assignment
until delivery. Keep legacy Profile 2 authoritative; use the separate UTC context
with reference models disabled. After feature/implementation completion, commit
content first, preview an expressly authorized update, render both contexts,
commit outputs and verify read-only status. Statistics do not rate people,
learning, quality, security or AI productivity. See the repository-relative
usage and rollout records. Installation grants no feature or delivery authority.
<!-- project-statistics-rollout:end -->
