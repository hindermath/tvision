# {{PROJECT_NAME}}

Kurze Beschreibung des Projekts. / Short project description.

## Überblick / Overview

Beschreibe hier den Zweck und den Umfang des Projekts.

*Describe the purpose and scope of the project here.*

## Lernenden- und A11Y-Basis / Learner and A11Y Baseline

Inhalte stehen auf Deutsch zuerst und Englisch danach, verwenden ungefähr CEFR
B2, erklären Fachbegriffe beim ersten Auftreten und setzen keine
Spec-Kit-Erfahrung voraus. Abhängigkeiten, Zustände und Entscheidungen erhalten
immer eine textorientierte Erklärung. WCAG 2.2 Level AA ist die Prüfbasis,
soweit die Kriterien anwendbar sind.

*Content is German-first/English-second at about CEFR B2, explains technical
terms at first use, and assumes no prior Spec Kit experience. Dependencies,
states, and decisions always receive a text-first explanation. WCAG 2.2 Level
AA is the review baseline wherever applicable.*

## Voraussetzungen / Prerequisites

- Git ≥ 2.30
- Bash 5+ (macOS/Linux) oder PowerShell 7+ (Windows)
- ripgrep (`brew install ripgrep` / `apt install ripgrep` / `choco install ripgrep`)

## Erste Schritte / Getting Started

```bash
git clone <repo-url>
cd {{PROJECT_NAME}}
bash scripts/install-hooks.sh
bash scripts/check-homogeneity.sh
```

## Verwendung / Usage

```bash
# Beispiel-Befehl / Example command
bash scripts/check-homogeneity.sh
```

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
Der Workflow verwendet das `speckit`-CLI-Tool (GitHub Copilot Skill).

Schritte für ein neues Feature:

1. **Spezifikation erstellen** — `speckit specify "Feature-Name"` → `specs/{branch}/spec.md`
2. **Klärungsfragen** — `speckit clarify` → offene Fragen in `spec.md` beantworten
3. **Implementierungsplan** — `speckit plan` → `specs/{branch}/plan.md`
4. **Aufgabenliste** — `speckit tasks` → `specs/{branch}/tasks.md`
5. **Implementieren** — `speckit implement` → Aufgaben aus `tasks.md` abarbeiten
6. **Validieren** — `bash scripts/check-homogeneity.sh` → Compliance-Score prüfen

---

New features in this workspace are developed following the **Specification-Driven Development (SDD)** workflow.
The workflow uses the `speckit` CLI tool (GitHub Copilot Skill).

Steps for a new feature:

1. **Create specification** — `speckit specify "Feature Name"` → `specs/{branch}/spec.md`
2. **Clarification questions** — `speckit clarify` → answer open questions in `spec.md`
3. **Implementation plan** — `speckit plan` → `specs/{branch}/plan.md`
4. **Task list** — `speckit tasks` → `specs/{branch}/tasks.md`
5. **Implement** — `speckit implement` → work through tasks in `tasks.md`
6. **Validate** — `bash scripts/check-homogeneity.sh` → check compliance score

## Für Azubis / For Apprentices

Willkommen! Diese Sektion beschreibt den Einstieg in die Entwicklungsumgebung
für Fachinformatiker-Azubis und andere Einsteiger.

**Voraussetzungen:**

- Git (macOS: `brew install git` / Windows: `winget install Git.Git`)
- PowerShell 7+ (Windows: `winget install Microsoft.PowerShell`)
- ripgrep (macOS: `brew install ripgrep` / Windows: `winget install BurntSushi.ripgrep.MSVC`)
- GitHub CLI (macOS: `brew install gh` / Windows: `winget install GitHub.cli`)

**Ersten Schritt ausführen:**

```bash
bash scripts/install-hooks.sh
bash scripts/check-homogeneity.sh
```

Bei Fragen: Issue im GitHub-Repository erstellen oder Mentor ansprechen.

---

Welcome! For questions: open an issue in the GitHub repository or ask your mentor.

<!-- EN: README.md placeholder
[DE-Zusammenfassung: Vollständige bilinguale README für {{PROJECT_NAME}} mit A11Y-, Spec-kit- und Azubis-Abschnitten.]
-->
