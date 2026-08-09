# {{PROJECT_NAME}}

Dieses Projekt ist Teil des Workspaces **{{WORKSPACE}}**.

*This project is part of the **{{WORKSPACE}}** workspace.*

---

## Über dieses Projekt / About this project

Dieses Projekt ist ein Level-2-Projekt im Workspace **{{WORKSPACE}}**.

*This project is a level-2 project in the **{{WORKSPACE}}** workspace.*

---

## Für Entwickler / For Developers

### Lokale Entwicklung / Local Development

#### 1. Abhängigkeiten installieren / Install dependencies
[Befehl hier einfügen, z. B. `npm install` oder `dotnet restore`]

#### 2. Projekt starten / Run project
[Befehl hier einfügen, z. B. `npm start` oder `dotnet run`]

#### 3. Tests ausführen / Run tests
[Befehl hier einfügen, z. B. `npm test` oder `dotnet test`]

---

## Spec-Kit Workflow (Specification-Driven Development)

Dieses Projekt nutzt **Spec-Kit** für die strukturierte Entwicklung von Features.

*This project uses **Spec-Kit** for structured feature development.*

1.  **Feature spezifizieren:** `speckit.specify "Mein neues Feature"`
2.  **Fragen klären:** `speckit.clarify`
3.  **Plan erstellen:** `speckit.plan`
4.  **Tasks generieren:** `speckit.tasks`
5.  **Implementieren:** `speckit.implement`

---

## Barrierefreiheit / Accessibility

Alle nutzerseitigen Artefakte werden textorientiert gepflegt und sollen mit Tastatur, Screenreader, Braille-Zeile und Textbrowser nutzbar bleiben. WCAG 2.2 Level AA ist die Basis, soweit die Kriterien auf das jeweilige Artefakt anwendbar sind.

*All user-facing artifacts are maintained in a text-oriented form and should remain usable with keyboard, screen readers, Braille displays, and text browsers. WCAG 2.2 Level AA is the baseline where the criteria apply to the artifact.*

---

## Für Auszubildende / For IT Apprentices

Dieses Projekt richtet sich ab dem ersten Ausbildungsjahr an
Fachinformatiker*innen, IT-System-Elektroniker*innen, Kaufleute für
IT-System-Management und Kaufleute für Digitalisierungsmanagement. Fachbegriffe
werden beim ersten Auftreten erklärt; Spec-Kit-Erfahrung wird nicht
vorausgesetzt. Abhängigkeiten, Zustände und Entscheidungen bleiben auch ohne
visuelle Darstellung verständlich.

*This project targets IT specialist apprentices, IT systems electronics
technician apprentices, and both IT management occupations from their first
training year. Technical terms are explained at first use; no prior Spec Kit
experience is assumed. Dependencies, states, and decisions remain
understandable without a visual-only representation.*

In diesem Ordner schreibst du deinen eigentlichen Code. Hier sind ein paar wichtige Regeln für die Arbeit an diesem Projekt:

### Sicherheit / Security
- Der **pre-push Hook** ist aktiv. Er prüft bei jedem `git push`, ob du versehentlich Geheimnisse (Secrets) hochlädst.
- Deine Konfiguration für KI-Agenten findest du in `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` und `.github/copilot-instructions.md`.

### Compliance
Du kannst jederzeit prüfen, ob dein Projekt den Standards entspricht:
```bash
bash scripts/check-homogeneity.sh .
```

### Hilfe holen / Get Help
Nutze deine KI-Agenten direkt im Terminal, wenn du feststeckst:
- `copilot -p "Erkläre mir diesen Code..."`
- `claude "Wie schreibe ich einen Test für..."`

---

## Dokumentation / Documentation
- [CONSTITUTION.md](./constitution.md) — Die Regeln unseres Workspaces.
- [STATS.md](./STATS.md) — Statistiken über dieses Projekt.
- [docs/secure-development/](./docs/secure-development/) — Wiederverwendbare sichere-Entwicklung-Basis inkl. mitgeltender Dokumente und Verzahnungsdatei zu Checklisten und Spec-Kit-Presets. Die RL-SE-/Checklist-Selbstpruefung gilt unabhaengig von MSL; MSL-Status bleibt ein Pruefpunkt.
- [.specify/presets/](./.specify/presets/) — Projektlokal installierte Spec-Kit-Governance-Presets, falls dieses Level-2-Projekt mit der zentralen Preset-Matrix vorbereitet wurde.
- [docs/security/gsdb-self-assessment.md](./docs/security/gsdb-self-assessment.md) — GSDB-Preflight-Bericht, falls mit `check-gsdb-self-assessment.*` erzeugt.
- [Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md](./Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md) — Intake fuer einen spaeter manuell gestarteten Spec-Kit-Lauf zur intensiven GSDB-Pruefung, falls vorhanden.
- [Lastenheft_Abarbeitungsreihenfolge.md](./Lastenheft_Abarbeitungsreihenfolge.md) — Sichtbare Reihenfolge der `Lastenheft*.md`-Dateien fuer spaetere Spec-Kit-Laeufe, falls vorhanden.

---

<!-- EN: README.md contains bilingual setup and usage guidance for this level-2 project. -->
