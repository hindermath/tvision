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
# Repository klonen
git clone <repo-url>
cd <projekt-verzeichnis>

# Hooks installieren
bash scripts/install-hooks.sh

# Compliance prüfen
bash scripts/check-homogeneity.sh
```

**Hilfreiche Befehle:**

| Befehl | Beschreibung |
|--------|--------------|
| `bash scripts/check-homogeneity.sh` | Compliance-Bericht anzeigen |
| `bash scripts/init-stats.sh` | Compliance-Baseline in STATS.md schreiben |
| `git log --oneline -10` | Letzte 10 Commits anzeigen |

Bei Fragen: Issue im GitHub-Repository erstellen oder Mentor ansprechen.

---

Welcome! This section describes how to get started with the development
environment for apprentice software developers (Fachinformatiker-Azubis) and
other beginners.

**Prerequisites:**

- Git (macOS: `brew install git` / Windows: `winget install Git.Git`)
- PowerShell 7+ (Windows: `winget install Microsoft.PowerShell`)
- ripgrep (macOS: `brew install ripgrep` / Windows: `winget install BurntSushi.ripgrep.MSVC`)
- GitHub CLI (macOS: `brew install gh` / Windows: `winget install GitHub.cli`)

**First steps:**

```bash
# Clone the repository
git clone <repo-url>
cd <project-directory>

# Install hooks
bash scripts/install-hooks.sh

# Check compliance
bash scripts/check-homogeneity.sh
```

**Useful commands:**

| Command | Description |
|---------|-------------|
| `bash scripts/check-homogeneity.sh` | Show compliance report |
| `bash scripts/init-stats.sh` | Write compliance baseline to STATS.md |
| `git log --oneline -10` | Show last 10 commits |

For questions: open an issue in the GitHub repository or ask your mentor.
