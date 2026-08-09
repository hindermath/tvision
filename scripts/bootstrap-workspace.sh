#!/usr/bin/env bash
# bootstrap-workspace.sh
# Richtet ein neues Projektverzeichnis als privates Remote-Repo ein:
#   git init · .gitignore · Scripts kopieren · repo create · push · Hooks installieren
#
# Verwendung:
#   bash ~/scripts/bootstrap-workspace.sh <Verzeichnisname> [Repo-Name] [Beschreibung]
#
# Beispiel:
#   bash ~/scripts/bootstrap-workspace.sh WebstormProjects webstorm-baseline "Workspace-Konfiguration für WebStorm-Projekte"
#   bash ~/scripts/bootstrap-workspace.sh WebstormProjects --platform gitlab
#
# Optionen:
#   --dry-run               Zeigt alle Schritte ohne Ausführung
#   --platform <github|gitlab|forgejo|codeberg>
#   --gitlab-url <https://gitlab.example.com>
#   --forgejo-url <https://forgejo.example.com>
#   --no-remote             Nur lokales Git-Repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGEJO_LIB="$SCRIPT_DIR/lib/hg-forgejo.sh"
if [ ! -f "$FORGEJO_LIB" ]; then
  echo "Fehler: Forgejo-Bibliothek fehlt: $FORGEJO_LIB" >&2
  exit 1
fi
# shellcheck source=scripts/lib/hg-forgejo.sh
source "$FORGEJO_LIB"

if [ "${1:-}" = "--teardown" ]; then
  shift
  exec bash "$SCRIPT_DIR/teardown-workspace.sh" "$@"
fi

# --- Hilfsfunktionen -----------------------------------------------------------

usage() {
  echo "Verwendung: $(basename "$0") [OPTIONEN] <Verzeichnisname> [Repo-Name] [Beschreibung]"
  echo "            $(basename "$0") --dry-run <Verzeichnisname> ..."
  exit 1
}

log()  { echo "  $*"; }
ok()   { echo "✓ $*"; }
info() { echo "→ $*"; }

normalize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

# --- Parameter parsen ----------------------------------------------------------

DRY_RUN=0
NO_REMOTE=0
PLATFORM="github"
GITLAB_URL="https://gitlab.com"
GITLAB_HOSTNAME=""
FORGEJO_URL=""
FORGEJO_BASE_URL=""
WORKSPACE_NAME=""
REPO_NAME=""
REPO_DESC=""

while [ $# -gt 0 ]; do
  case "${1:-}" in
    --dry-run)
      DRY_RUN=1
      ;;
    --no-remote)
      NO_REMOTE=1
      ;;
    --platform)
      PLATFORM="${2:-}"
      shift
      ;;
    --gitlab-url)
      GITLAB_URL="${2:-}"
      shift
      ;;
    --forgejo-url)
      FORGEJO_URL="${2:-}"
      shift
      ;;
    --help|-h)
      usage
      ;;
    --)
      shift
      if [ $# -gt 0 ] && [ -z "$WORKSPACE_NAME" ]; then WORKSPACE_NAME="$1"; shift; fi
      if [ $# -gt 0 ] && [ -z "$REPO_NAME" ]; then REPO_NAME="$1"; shift; fi
      if [ $# -gt 0 ] && [ -z "$REPO_DESC" ]; then REPO_DESC="$1"; shift; fi
      continue
      ;;
    --*)
      echo "Fehler: Unbekannte Option: $1" >&2
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [ -z "$WORKSPACE_NAME" ]; then
        WORKSPACE_NAME="$1"
      elif [ -z "$REPO_NAME" ]; then
        REPO_NAME="$1"
      elif [ -z "$REPO_DESC" ]; then
        REPO_DESC="$1"
      else
        echo "Fehler: Zu viele Positionsargumente." >&2
        echo "Error: Too many positional arguments." >&2
        exit 1
      fi
      ;;
  esac
  shift
done

[ -z "$WORKSPACE_NAME" ] && usage

case "$PLATFORM" in
  github|gitlab|forgejo|codeberg) ;;
  *)
    echo "Fehler: Ungültige Plattform '$PLATFORM'. Gültige Werte: github, gitlab, forgejo, codeberg." >&2
    echo "Error: Invalid platform '$PLATFORM'. Valid values: github, gitlab, forgejo, codeberg." >&2
    exit 1
    ;;
esac

if [ "$PLATFORM" = "gitlab" ]; then
  case "$GITLAB_URL" in
    https://*) ;;
    *)
      echo "Fehler: --gitlab-url muss mit 'https://' beginnen." >&2
      echo "Error: --gitlab-url must start with 'https://'." >&2
      exit 1
      ;;
  esac
  GITLAB_HOSTNAME="${GITLAB_URL#https://}"
  GITLAB_HOSTNAME="${GITLAB_HOSTNAME%/}"
fi

if [ "$NO_REMOTE" -eq 0 ] && { [ "$PLATFORM" = "forgejo" ] || [ "$PLATFORM" = "codeberg" ]; }; then
  FORGEJO_BASE_URL="$(hb_forgejo_resolve_base_url "$PLATFORM" "$FORGEJO_URL")"
fi

HOME_DIR="$(cd ~ && pwd)"
WORKSPACE_DIR="$HOME_DIR/$WORKSPACE_NAME"
SCRIPTS_SRC="$HOME_DIR/scripts"

if [ -z "$REPO_NAME" ]; then
  REPO_NAME="$(echo "$WORKSPACE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/projects$/-baseline/' | sed 's/ /-/g')"
fi
if [ -z "$REPO_DESC" ]; then
  REPO_DESC="Gemeinsame Workspace-Konfiguration für $WORKSPACE_NAME"
fi

# --- Vorabprüfungen ------------------------------------------------------------

# Git-Identität prüfen: Platzhalter-Werte führen zu falschen Commit-Autoren
# Check git identity: placeholder values cause incorrect commit author information
if ! bash "$SCRIPT_DIR/setup-git-identity.sh" --check-only 2>/dev/null; then
  echo "" >&2
  echo "Fehler: Git-Identität muss vor dem Bootstrap konfiguriert werden." >&2
  echo "  Die globale Git-Konfiguration enthält noch Platzhalter-Werte." >&2
  echo "" >&2
  echo "  Behebung / Fix:" >&2
  echo "    bash ~/scripts/setup-git-identity.sh" >&2
  echo "" >&2
  echo "Error: Git identity must be configured before bootstrapping a workspace." >&2
  exit 1
fi

if [ ! -d "$WORKSPACE_DIR" ]; then
  echo "Fehler: Verzeichnis '$WORKSPACE_DIR' existiert nicht." >&2
  exit 1
fi

if [ -d "$WORKSPACE_DIR/.git" ]; then
  echo "Fehler: '$WORKSPACE_DIR' ist bereits ein Git-Repository." >&2
  exit 1
fi

if [ "$NO_REMOTE" -eq 1 ]; then
  REPO_SLUG="$(normalize_name "$REPO_NAME")"
  SLUG_CHANGED=0
elif [ "$PLATFORM" = "github" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    GH_USER="<GITHUB-USER>"
    REPO_SLUG="$REPO_NAME"
    SLUG_CHANGED=0
  else
  if ! command -v gh >/dev/null 2>&1; then
    echo "Fehler: gh (GitHub CLI) ist nicht installiert." >&2
    echo "Error: gh (GitHub CLI) is not installed." >&2
    exit 1
  fi

  GH_USER=$(gh api user --jq '.login' 2>/dev/null || true)
  if [ -z "$GH_USER" ]; then
    echo "Fehler: Konnte GitHub-Benutzername nicht ermitteln. Bitte 'gh auth login' ausführen." >&2
    echo "Error: Could not retrieve GitHub username. Please run 'gh auth login'." >&2
    exit 1
  fi

  REPO_SLUG="$REPO_NAME"
  SLUG_CHANGED=0
  fi
elif [ "$PLATFORM" = "gitlab" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    GITLAB_USER="<GITLAB-USER>"
    REPO_SLUG="$(normalize_name "$REPO_NAME")"
    SLUG_CHANGED=0
    [ "$REPO_SLUG" != "$REPO_NAME" ] && SLUG_CHANGED=1
  else
  if ! command -v glab >/dev/null 2>&1; then
    echo "Fehler: glab (GitLab CLI) ist nicht installiert." >&2
    echo "  macOS/Linux: brew install glab" >&2
    echo "  Windows:     winget install GLabCLI.GlabCLI" >&2
    echo "Error: glab (GitLab CLI) is not installed." >&2
    exit 1
  fi

  if ! GITLAB_HOST="$GITLAB_HOSTNAME" glab auth status >/dev/null 2>&1; then
    echo "Fehler: Nicht bei GitLab ($GITLAB_HOSTNAME) authentifiziert. Bitte 'glab auth login' ausführen." >&2
    echo "Error: Not authenticated with GitLab ($GITLAB_HOSTNAME). Please run 'glab auth login'." >&2
    exit 1
  fi

  GITLAB_USER="$(
    glab api user --hostname "$GITLAB_HOSTNAME" 2>/dev/null \
      | tr -d '\r\n' \
      | sed -n 's/.*"username":"\([^"]*\)".*/\1/p'
  )"
  if [ -z "$GITLAB_USER" ]; then
    echo "Fehler: Konnte GitLab-Benutzername nicht ermitteln." >&2
    echo "Error: Could not retrieve GitLab username." >&2
    exit 1
  fi

  REPO_SLUG="$(normalize_name "$REPO_NAME")"
  SLUG_CHANGED=0
  [ "$REPO_SLUG" != "$REPO_NAME" ] && SLUG_CHANGED=1
  fi
else
  REPO_SLUG="$(normalize_name "$REPO_NAME")"
  SLUG_CHANGED=0
  [ "$REPO_SLUG" != "$REPO_NAME" ] && SLUG_CHANGED=1
fi

# --- Zusammenfassung anzeigen --------------------------------------------------

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  bootstrap-workspace – Neue Workspace-Einrichtung               ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
printf "║  Verzeichnis : %-51s║\n" "$WORKSPACE_DIR"
printf "║  Beschreibung: %-51s║\n" "${REPO_DESC:0:51}"
if [ "$NO_REMOTE" -eq 1 ]; then
  printf "║  Remote      : %-51s║\n" "kein Remote / no remote"
elif [ "$PLATFORM" = "github" ]; then
  printf "║  GitHub-Repo : %-51s║\n" "$GH_USER/$REPO_NAME (privat)"
  printf "║  Plattform   : %-51s║\n" "GitHub (privat)"
elif [ "$PLATFORM" = "gitlab" ]; then
  printf "║  GitLab-Repo : %-51s║\n" "$GITLAB_USER/$REPO_SLUG (privat)"
  printf "║  Plattform   : %-51s║\n" "GitLab — $GITLAB_URL (privat)"
  if [ "$SLUG_CHANGED" -eq 1 ]; then
    printf "║  GitLab-Slug : %-51s║\n" "$REPO_SLUG (normalisiert von: $REPO_NAME)"
  fi
else
  printf "║  Remote-Repo : %-51s║\n" "<USER>/$REPO_SLUG (privat)"
  printf "║  Plattform   : %-51s║\n" "$PLATFORM - $FORGEJO_BASE_URL"
  if [ "$SLUG_CHANGED" -eq 1 ]; then
    printf "║  Repo-Slug   : %-51s║\n" "$REPO_SLUG (normalisiert von: $REPO_NAME)"
  fi
fi
echo "╚══════════════════════════════════════════════════════════════════╝"
[ "$DRY_RUN" -eq 1 ] && echo "  [DRY RUN – keine Änderungen werden vorgenommen]"
echo ""

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

# --- Sub-Repos ermitteln (bestehende .git-Verzeichnisse) ----------------------

info "Suche bestehende Sub-Repositories …"
SUB_REPOS=()
while IFS= read -r sub; do
  sub_name="$(basename "$(dirname "$sub")")"
  SUB_REPOS+=("$sub_name")
  log "Gefunden: $sub_name/"
done < <(find "$WORKSPACE_DIR" -maxdepth 2 -name ".git" -type d | sort)

# --- .gitignore erstellen ------------------------------------------------------

info "Erstelle .gitignore …"
GITIGNORE_PATH="$WORKSPACE_DIR/.gitignore"

if [ "$DRY_RUN" -eq 0 ]; then
  {
    echo "# Sub-Verzeichnisse mit eigenen Git-Repositories (automatisch erkannt)"
    for repo in "${SUB_REPOS[@]+"${SUB_REPOS[@]}"}"; do
      echo "$repo/"
    done
    echo ""
    cat <<'STATIC'
# macOS
.DS_Store
.AppleDouble
.LSOverride

# JetBrains IDEs
.idea/
*.iws
*.iml

# VS Code (lokale Einstellungen)
.vscode/c_cpp_properties.json
.vscode/settings.json

# Build-Artefakte
bin/
obj/
build/
node_modules/
STATIC
  } > "$GITIGNORE_PATH"
  ok ".gitignore erstellt"
else
  sub_repos_display="keine"
  if [ "${#SUB_REPOS[@]}" -gt 0 ]; then
    sub_repos_display="${SUB_REPOS[*]}"
  fi
  echo "  [dry-run] .gitignore würde erstellt mit Einträgen für: $sub_repos_display"
fi

# --- Scripts kopieren ----------------------------------------------------------

info "Kopiere Scripts …"
run "mkdir -p '$WORKSPACE_DIR/scripts'"
run "cp -R '$SCRIPTS_SRC/.' '$WORKSPACE_DIR/scripts/'"
run "chmod +x '$WORKSPACE_DIR/scripts/'*.sh '$WORKSPACE_DIR/scripts/hooks/pre-push' 2>/dev/null || true"
ok "Scripts kopiert"

# --- README.md erzeugen --------------------------------------------------------

info "Erstelle Workspace-README.md …"
WS_README_TMPL="$SCRIPTS_SRC/templates/workspace-readme-template.md"
if [ -f "$WS_README_TMPL" ]; then
  if [ $DRY_RUN -eq 0 ]; then
    sed "s/{{WORKSPACE_NAME}}/${WORKSPACE_NAME}/g" "$WS_README_TMPL" > "$WORKSPACE_DIR/README.md"
    ok "Workspace-README.md erstellt"
  else
    echo "  [dry-run] Workspace-README.md würde aus $WS_README_TMPL erstellt."
  fi
else
  log "WARN: Template '$WS_README_TMPL' nicht gefunden — überspringe README-Erstellung."
fi

# --- Agentische Level-1-Baseline erzeugen -------------------------------------

info "Erzeuge agentische Level-1-Baseline …"
TEMPLATES_DIR="$SCRIPTS_SRC/templates"

render_workspace_template() {
  local template="$1" output="$2"
  sed \
    -e "s|{{PROJECT_NAME}}|${WORKSPACE_NAME}|g" \
    -e "s|{{WORKSPACE}}|~/${WORKSPACE_NAME}|g" \
    "$template" > "$output"
}

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$WORKSPACE_DIR/.github/workflows" "$WORKSPACE_DIR/docs"

  for agent_file in AGENTS.md CLAUDE.md GEMINI.md; do
    tmpl="$TEMPLATES_DIR/${agent_file}.tmpl"
    if [ -f "$tmpl" ]; then
      render_workspace_template "$tmpl" "$WORKSPACE_DIR/$agent_file"
    fi
  done

  if [ -f "$TEMPLATES_DIR/copilot-instructions.tmpl" ]; then
    render_workspace_template "$TEMPLATES_DIR/copilot-instructions.tmpl" "$WORKSPACE_DIR/.github/copilot-instructions.md"
  fi

  if [ -f "$HOME_DIR/constitution.md" ]; then
    cp "$HOME_DIR/constitution.md" "$WORKSPACE_DIR/constitution.md"
  fi

  constitution_ver="v1.0.0"
  if [ -f "$WORKSPACE_DIR/constitution.md" ]; then
    constitution_ver=$(head -1 "$WORKSPACE_DIR/constitution.md" | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' || echo "v1.0.0")
  fi
  cat > "$WORKSPACE_DIR/.github/workflows/homogeneity-check.yml" <<EOF
name: Homogeneity Check

on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main, master]

jobs:
  homogeneity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ripgrep
        run: sudo apt-get install -y ripgrep
      - name: Run homogeneity check
        run: bash scripts/check-homogeneity.sh --json --fail-fast .
        env:
          CONSTITUTION_VERSION: "${constitution_ver}"
EOF

  cat > "$WORKSPACE_DIR/docs/project-statistics.md" <<STATSDOC
# Projektstatistik / Project Statistics — ${WORKSPACE_NAME}

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
| $(date +%Y-%m-%d) | 0 — Bootstrap | 1 | — | 1 | Initialer Workspace-Bootstrap via bootstrap-workspace |

---

## Gesamtstand des Repositories / Repository Snapshot

Stand / As of: $(date +%Y-%m-%d) — *Erste Einträge nach dem initialen Arbeitspaket eintragen.*

| Kategorie / Category | Dateien / Files | Zeilen / Lines | Anteil / Share |
|---|---:|---:|---:|
| Produktionscode / Production code | — | — | — |
| Tests / Tests | — | — | — |
| Dokumentation / Documentation (.md) | — | — | — |
| **Gesamt / Total** | — | — | — |

---

## Gesamtstatistik / Overall Statistics

*Wird nach dem ersten dokumentierten Arbeitspaket befüllt.*
*To be filled after the first documented work package.*

| Kennzahl / Metric | Verdichteter Gesamtblick / Condensed Overview |
|---|---:|
| Artefaktbasis gesamt | — |
| Beobachtbarer Projektzeitraum | $(date +%Y-%m-%d) bis — |
| Sichtbare Git-Aktivtage | — |
| Repo-weiter Speedup gg. 80-Zeilen-Referenz | — |
| Repo-weiter Speedup gg. Thorsten-Referenz | — |
STATSDOC

  workspace_name_json="$(json_escape "$WORKSPACE_NAME")"
  cat > "$WORKSPACE_DIR/docs/project-statistics.config.json" <<STATSCONFIG
{
  "\$schema": "../scripts/config/project-statistics.schema.json",
  "schemaVersion": 1,
  "methodologyVersion": 2,
  "repositoryName": "${workspace_name_json}",
  "timeZone": "Europe/Berlin",
  "activityWindowWeeks": 52,
  "references": {
    "conservativeLinesPerDay": 80,
    "thorstenLinesPerDay": 100
  },
  "phases": [],
  "excludedPaths": [],
  "categoryOverrides": []
}
STATSCONFIG

  printf '# STATS.md — %s\n\n## Überblick / Overview\n\nCompliance-Historie — Compliance History\n\n## Verwendung / Usage\n\nJeder `check-homogeneity.sh`-Aufruf fügt hier einen Eintrag hinzu.\n\nEach `check-homogeneity.sh` run appends an entry here.\n\n' "$WORKSPACE_NAME" > "$WORKSPACE_DIR/STATS.md"

  if [ "$PLATFORM" = "github" ] && [ "$NO_REMOTE" -eq 0 ]; then
    cat > "$WORKSPACE_DIR/release-please-config.json" <<'RPCFG'
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "simple",
  "packages": {
    ".": {
      "changelog-sections": [
        {"type": "feat", "section": "Features / Neue Funktionen"},
        {"type": "fix", "section": "Bug Fixes / Fehlerbehebungen"},
        {"type": "docs", "section": "Documentation / Dokumentation"},
        {"type": "chore", "section": "Maintenance / Wartung", "hidden": false},
        {"type": "refactor", "section": "Refactoring", "hidden": true}
      ]
    }
  }
}
RPCFG
    printf '{\n  ".": "0.1.0"\n}\n' > "$WORKSPACE_DIR/.release-please-manifest.json"
    cat > "$WORKSPACE_DIR/.github/workflows/release-please.yml" <<'RPWF'
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      # Pinned Node.js 24-capable upstream SHA until the next tagged v4 release targets node24.
      - uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
RPWF
  fi

  if command -v specify >/dev/null 2>&1; then
    for agent in agy opencode claude copilot codex; do
      (cd "$WORKSPACE_DIR" && specify init --here --force --integration "$agent" >/dev/null 2>&1) || log "WARN: specify init fehlgeschlagen fuer $agent"
    done
    if [ -f "$WORKSPACE_DIR/constitution.md" ] && [ -d "$WORKSPACE_DIR/.specify/memory" ]; then
      cp "$WORKSPACE_DIR/constitution.md" "$WORKSPACE_DIR/.specify/memory/constitution.md"
    fi
  else
    log "WARN: specify nicht installiert — Spec-Kit manuell nachziehen"
  fi

  ok "Agentische Level-1-Baseline erzeugt"
else
  echo "  [dry-run] Agenten-Dateien, Constitution, Workflows, Statistik, Release Please und Spec-Kit würden erzeugt."
fi

# --- git init + commit ---------------------------------------------------------

info "Initialisiere Git-Repository …"
run "git -C '$WORKSPACE_DIR' init"
run "git -C '$WORKSPACE_DIR' add -A"
run "git -C '$WORKSPACE_DIR' commit -m 'chore: initiale Baseline-Konfiguration für $WORKSPACE_NAME

- .gitignore        – schließt Sub-Repos und Artefakte aus
- scripts/          – Secret-Scan, Hook-Installation (Bash + PowerShell)
- README.md         – Workspace-Dokumentation (bilingual)

Nach dem Clonen auf neuem Gerät:
  bash scripts/install-hooks.sh       (macOS/Linux)
  pwsh scripts/install-hooks.ps1      (Windows)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>'"
ok "Initialer Commit erstellt"

if [ -f "$WORKSPACE_DIR/scripts/render-project-statistics.sh" ]; then
  info "Initialisiere ASCII-Statistikprofil 2 ..."
  if bash "$WORKSPACE_DIR/scripts/render-project-statistics.sh" --repo "$WORKSPACE_DIR" >/dev/null; then
    if [ -n "$(git -C "$WORKSPACE_DIR" status --porcelain -- docs/project-statistics.md)" ]; then
      git -C "$WORKSPACE_DIR" add docs/project-statistics.md
      git -C "$WORKSPACE_DIR" commit -m "docs: initialize ASCII statistics profile 2

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
    fi
    ok "ASCII-Statistikprofil 2 initialisiert"
  else
    warn "ASCII-Statistikprofil 2 konnte nicht initialisiert werden"
  fi
fi

# --- Remote-Repo erstellen und pushen ------------------------------------------

if [ "$NO_REMOTE" -eq 1 ]; then
  info "Remote-Erstellung uebersprungen (--no-remote)."
elif [ "$PLATFORM" = "github" ]; then
  info "Erstelle privates GitHub-Repository '$REPO_NAME' …"
  run "gh repo create '$REPO_NAME' --private --description '$REPO_DESC' --source '$WORKSPACE_DIR' --remote origin --push"
  ok "GitHub-Repo erstellt und gepusht"
elif [ "$PLATFORM" = "gitlab" ]; then
  REMOTE_URL="https://${GITLAB_HOSTNAME}/${GITLAB_USER}/${REPO_SLUG}.git"
  info "Erstelle privates GitLab-Repository '$REPO_SLUG' …"
  run "GITLAB_HOST='$GITLAB_HOSTNAME' glab repo create '$REPO_SLUG' --private --description '$REPO_DESC'"
  ok "GitLab-Repo erstellt"
  run "git -C '$WORKSPACE_DIR' remote add origin '$REMOTE_URL'"
  run "git -C '$WORKSPACE_DIR' push -u origin HEAD"
  ok "Remote gesetzt und gepusht"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] Forgejo-API wuerde privates Repository '$REPO_SLUG' auf '$FORGEJO_BASE_URL' anlegen oder wiederverwenden."
    echo "  [dry-run] git remote add origin <API-CLONE-URL>"
    echo "  [dry-run] git push -u origin HEAD"
  else
    info "Erstelle oder verwende privates $PLATFORM-Repository '$REPO_SLUG' ..."
    hb_forgejo_create_or_get_repository "$FORGEJO_BASE_URL" "$REPO_SLUG" "$REPO_DESC"
    git -C "$WORKSPACE_DIR" remote add origin "$HB_FORGEJO_CLONE_URL"
    git -C "$WORKSPACE_DIR" config --local home-baseline.remote-platform "$PLATFORM"
    git -C "$WORKSPACE_DIR" config --local home-baseline.remote-base-url "$FORGEJO_BASE_URL"
    git -C "$WORKSPACE_DIR" config --local home-baseline.remote-owner "$HB_FORGEJO_REPOSITORY_OWNER"
    git -C "$WORKSPACE_DIR" config --local home-baseline.remote-repository "$HB_FORGEJO_REPOSITORY_NAME"
    git -C "$WORKSPACE_DIR" push -u origin HEAD
    REPO_URL="$HB_FORGEJO_HTML_URL"
    DISPLAY_REPO="$HB_FORGEJO_REPOSITORY_NAME"
    if [ "$HB_FORGEJO_REPOSITORY_CREATED" -eq 1 ]; then
      ok "$PLATFORM-Repo erstellt und gepusht"
    else
      ok "Vorhandenes $PLATFORM-Repo verbunden und gepusht"
    fi
  fi
fi

# --- Hooks installieren --------------------------------------------------------

info "Installiere Git-Hooks …"
run "bash '$WORKSPACE_DIR/scripts/install-hooks.sh'"
ok "Hooks installiert"

# --- ~/README.md aktualisieren ------------------------------------------------

HOME_README="$HOME_DIR/README.md"
if [ "$NO_REMOTE" -eq 1 ]; then
  REPO_URL=""
  DISPLAY_REPO="lokal / local"
elif [ "$PLATFORM" = "github" ]; then
  REPO_URL="https://github.com/$GH_USER/$REPO_NAME"
  DISPLAY_REPO="$REPO_NAME"
elif [ "$PLATFORM" = "gitlab" ]; then
  REPO_URL="${GITLAB_URL%/}/$GITLAB_USER/$REPO_SLUG"
  DISPLAY_REPO="$REPO_SLUG"
elif [ "$DRY_RUN" -eq 1 ]; then
  REPO_URL="$FORGEJO_BASE_URL/<USER>/$REPO_SLUG"
  DISPLAY_REPO="$REPO_SLUG"
fi
if [ -n "$REPO_URL" ]; then
  NEW_ROW="| \`~/$WORKSPACE_NAME/\` | [$DISPLAY_REPO]($REPO_URL) | \`bootstrap-workspace\` |"
else
  NEW_ROW="| \`~/$WORKSPACE_NAME/\` | $DISPLAY_REPO | \`bootstrap-workspace --no-remote\` |"
fi

if [ -f "$HOME_README" ]; then
  info "Aktualisiere ~/README.md …"
  if grep -qF "~/$WORKSPACE_NAME/" "$HOME_README"; then
    log "Eintrag für '$WORKSPACE_NAME' bereits vorhanden – übersprungen."
  else
    if [ "$DRY_RUN" -eq 0 ]; then
      NEW_ROW="$NEW_ROW" perl -0pi -e 's/\Q<!-- workspace-table-end -->\E/$ENV{NEW_ROW}."\n<!-- workspace-table-end -->"/e' "$HOME_README"
      ok "~/README.md aktualisiert"
    else
      echo "  [dry-run] ~/README.md: neue Zeile würde eingefügt: $NEW_ROW"
    fi
  fi
fi

# --- home-baseline committen und pushen ----------------------------------------

HOME_GIT="$HOME_DIR/.git"
if [ -d "$HOME_GIT" ]; then
  info "Committe Änderungen in home-baseline …"
  run "git -C '$HOME_DIR' add README.md"
  run "git -C '$HOME_DIR' commit -m 'chore: $WORKSPACE_NAME in Workspace-Übersicht eingetragen

Automatisch durch bootstrap-workspace.sh hinzugefügt.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>'"
  if git -C "$HOME_DIR" remote get-url origin >/dev/null 2>&1; then
    run "git -C '$HOME_DIR' push"
    ok "home-baseline aktualisiert und gepusht"
  else
    ok "home-baseline committed (kein Remote konfiguriert — Push übersprungen / no remote configured — push skipped)"
  fi
fi



# --- Git Scope-Isolierung -------------------------------------------------------

info "Git Scope-Isolierung / Git Scope Isolation:"
NORMALIZED_NAME=$(normalize_name "$WORKSPACE_NAME")
GITCONFIG_D="${HOME_DIR}/.gitconfig.d"
GITCONFIG="${HOME_DIR}/.gitconfig"

if [ -d "$GITCONFIG_D" ]; then
  # core.autocrlf im lokalen .git/config setzen
  run "git -C '$WORKSPACE_DIR' config --local core.autocrlf input"

  # Idempotenz-Prüfung: bereits ein includeIf-Block für diesen Workspace?
  if ! grep -qF "gitdir:~/${WORKSPACE_NAME}/" "${GITCONFIG}" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 0 ]; then
      printf '\n[includeIf "gitdir:~/%s/"]\n\tpath = ~/.gitconfig.d/%s.inc\n' \
        "${WORKSPACE_NAME}" "${NORMALIZED_NAME}" >> "${GITCONFIG}"
    else
      echo "  [dry-run] ~/.gitconfig: [includeIf \"gitdir:~/${WORKSPACE_NAME}/\"] würde hinzugefügt"
    fi
    log "✓ includeIf für ${WORKSPACE_NAME} / includeIf for ${WORKSPACE_NAME} eingetragen"
  else
    log "→ includeIf für ${WORKSPACE_NAME} bereits vorhanden — übersprungen / already present — skipped"
  fi

  # .inc-Placeholder erstellen wenn nicht vorhanden
  INC_FILE="${GITCONFIG_D}/${NORMALIZED_NAME}.inc"
  if [ ! -f "$INC_FILE" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
      printf '# %s workspace git configuration\n# [user]\n#   email = work@example.com\n' \
        "${WORKSPACE_NAME}" > "$INC_FILE"
    else
      echo "  [dry-run] ~/.gitconfig.d/${NORMALIZED_NAME}.inc würde erstellt"
    fi
    log "✓ ~/.gitconfig.d/${NORMALIZED_NAME}.inc erstellt / created"
  else
    log "→ ~/.gitconfig.d/${NORMALIZED_NAME}.inc bereits vorhanden — übersprungen / already exists — skipped"
  fi
else
  log "→ ~/.gitconfig.d/ nicht vorhanden — Scope-Isolierung übersprungen / not found — skipping scope isolation"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Einrichtung abgeschlossen!                                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
if [ "$PLATFORM" != "github" ] && [ "$SLUG_CHANGED" -eq 1 ]; then
  echo "  Repo-Slug : $REPO_SLUG (normalisiert von: $REPO_NAME)"
fi
if [ -n "$REPO_URL" ]; then
  echo "  Repo   : $REPO_URL"
  echo "  Clone  : git clone $(git -C "$WORKSPACE_DIR" remote get-url origin 2>/dev/null || printf '%s.git' "$REPO_URL") ~/$WORKSPACE_NAME"
else
  echo "  Repo   : kein Remote / no remote"
fi
echo "  Hooks  : bash scripts/install-hooks.sh  (oder pwsh scripts/install-hooks.ps1)"
echo ""
