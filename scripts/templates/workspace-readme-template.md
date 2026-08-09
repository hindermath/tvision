# {{WORKSPACE_NAME}} — Workspace Baseline

Dieses Repository enthält die gemeinsame Konfiguration und Infrastruktur für alle Projekte im Workspace **{{WORKSPACE_NAME}}**.

*This repository contains the shared configuration and infrastructure for all projects within the **{{WORKSPACE_NAME}}** workspace.*

---

## Workspace-Übersicht / Workspace overview

| Projekt / Project | Beschreibung / Description | Status |
|---|---|---|
<!-- project-table-end -->

---

## Für Entwickler & Nutzende / For Developers & Users

### Wichtige Befehle / Important Commands

Hier sind die am häufigsten benötigten Befehle für die Arbeit in diesem Workspace:

*Here are the most commonly used commands for working in this workspace:*

#### 1. Neues Projekt anlegen / Create a new project
```bash
# macOS / Linux
bash ~/scripts/bootstrap-project.sh <ProjektName> <WorkspacePfad>

# Beispiel:
bash ~/scripts/bootstrap-project.sh MeinNeuesProjekt ~/{{WORKSPACE_NAME}}
```

#### 2. Compliance prüfen / Check compliance
Prüft, ob alle Projekte im Workspace den Standards entsprechen.
```bash
bash ~/scripts/check-homogeneity.sh ~/{{WORKSPACE_NAME}}
```

#### 3. STATS.md aktualisieren / Update STATS.md
Erzeugt eine statistische Übersicht über den Code-Bestand im Workspace.
```bash
bash ~/scripts/init-stats.sh
```

---

## Für Azubis / For Apprentices

Herzlich willkommen in deinem Workspace! Ein **Workspace** ist wie ein großer Ordner für ein bestimmtes Thema (z. B. "C#-Projekte" oder "Webentwicklung"). 

### Warum haben wir dieses Verzeichnis? / Why this directory?

Dieser Ordner ist dein **Zuhause für Projekte**. Er sorgt dafür, dass:
- Alle deine Projekte die gleichen **Sicherheits-Checks** haben.
- Deine Arbeit automatisch auf **GitHub** gesichert wird.
- Du KI-Agenten (wie Claude oder Copilot) nutzen kannst, die dein Projekt verstehen.

### So arbeitest du hier / How to work here

1.  **Projekte anlegen:** Nutze immer das `bootstrap-project.sh` Skript (siehe oben). Es richtet alles fix und fertig für dich ein.
2.  **Sicherheit:** In jedem Projekt gibt es einen "Wächter" (den `pre-push`-Hook). Er verhindert, dass du aus Versehen Passwörter oder geheime Schlüssel hochlädst.
3.  **Versionsverwaltung:** Speichere deine Arbeit regelmäßig mit Git-Commits.
    ```bash
    git add .
    git commit -m "feat: erklärung was ich getan habe"
    git push
    ```

### Glossar / Glossary
- **Baseline:** Die Grundausstattung, die jedes Projekt von uns bekommt.
- **Hook:** Ein kleiner automatischer Helfer, der beim Speichern (Commit) oder Hochladen (Push) aufpasst.
- **Remote:** Deine Kopie des Projekts in der Cloud (auf GitHub).

---

## Plattform-Übersicht / Platform overview

| Plattform | Unterstützt | Voraussetzung |
|---|---|---|
| macOS | ✅ nativ | – |
| Linux | ✅ nativ | – |
| Windows | ✅ PowerShell Core | Git for Windows + pwsh >= 7 |

---

<!-- EN: README.md placeholder
[DE-Zusammenfassung: Inhalt dieser Datei auf Deutsch]
-->

## Barrierefreiheit / Accessibility (A11Y)

Dieses Projekt folgt grundlegenden Barrierefreiheitsstandards für alle
dokumentierten Inhalte und Benutzeroberflächen.

Richtlinien für Markdown-Dokumentation:

- Überschriften folgen einer klaren Hierarchie (h1 → h2 → h3 — keine Ebene überspringen)
- Alle Bilder haben aussagekräftige Alt-Texte (`![Beschreibung](bild.png)`)
- Linkbeschriftungen sind beschreibend (`[Installationsanleitung](...)` statt `[hier](...)`)
- Code-Blöcke geben die Sprache an (` ```bash `, ` ```powershell `)
- Tabellen haben Kopfzeilen für alle Spalten
- Keine Informationen werden ausschließlich über Farbe vermittelt

---

This project follows basic accessibility standards for all documented
content and user interfaces.

Guidelines for Markdown documentation:

- Headings follow a clear hierarchy (h1 → h2 → h3 — no level skipped)
- All images have meaningful alt texts (`![Description](image.png)`)
- Link labels are descriptive (`[Installation guide](...)` instead of `[here](...)`)
- Code blocks specify the language (` ```bash `, ` ```powershell `)
- Tables have header rows for all columns
- No information is conveyed through colour alone

## Spec-kit-Workflow

Neue Features in diesem Workspace werden nach dem **Specification-Driven Development (SDD)**-Workflow entwickelt.
Der Workflow verwendet das `speckit`-CLI-Tool.

Schritte für ein neues Feature:

1. **Spezifikation erstellen** — `speckit specify "Feature-Name"` → `specs/{branch}/spec.md`
2. **Klärungsfragen** — `speckit clarify` → offene Fragen in `spec.md` beantworten
3. **Implementierungsplan** — `speckit plan` → `specs/{branch}/plan.md`
4. **Aufgabenliste** — `speckit tasks` → `specs/{branch}/tasks.md`
5. **Implementieren** — `speckit implement` → Aufgaben aus `tasks.md` abarbeiten
6. **Validieren** — `bash scripts/check-homogeneity.sh` → Compliance-Score prüfen

Alle Spec-Artefakte werden im Branch-Verzeichnis `specs/{branch}/` gespeichert und versioniert.

---

## Spec-kit Workflow

New features in this workspace are developed following the **Specification-Driven Development (SDD)** workflow.
The workflow uses the `speckit` CLI tool.

Steps for a new feature:

1. **Create specification** — `speckit specify "Feature Name"` → `specs/{branch}/spec.md`
2. **Clarification questions** — `speckit clarify` → answer open questions in `spec.md`
3. **Implementation plan** — `speckit plan` → `specs/{branch}/plan.md`
4. **Task list** — `speckit tasks` → `specs/{branch}/tasks.md`
5. **Implement** — `speckit implement` → work through tasks in `tasks.md`
6. **Validate** — `bash scripts/check-homogeneity.sh` → check compliance score

All spec artefacts are stored and versioned in the branch directory `specs/{branch}/`.
