#!/usr/bin/env bash
# propagate-security-guidance.sh
# Propagiert Security-Guidance-Updates aus Level-0 (~/home-baseline-source) auf alle
# gefundenen Level-1- und Level-2-Repos unter dem Home-Verzeichnis.
#
# Kernprinzipien:
#   - Dynamische Repo-Erkennung: sucht Verzeichnisse mit .git + Agent-Dateien —
#     keine hartcodierten Pfade. Neue Workspaces werden automatisch erfasst.
#   - Canonical-Content-Quellen: Abschnitte werden zur Laufzeit aus Level-0-Dateien
#     gelesen. Wenn Level-0 aktualisiert wird, propagiert der nächste Lauf automatisch
#     den neuen Inhalt.
#   - Idempotent: prüft per Fingerprint-String vor jeder Änderung; keine Doppelschreibungen.
#   - Dry-Run: --dry-run zeigt alle geplanten Änderungen ohne zu schreiben.
#
# Verwendung / Usage:
#   bash ~/scripts/propagate-security-guidance.sh
#   bash ~/scripts/propagate-security-guidance.sh --dry-run
#   bash ~/scripts/propagate-security-guidance.sh --verbose
#   bash ~/scripts/propagate-security-guidance.sh --only-level1
#   bash ~/scripts/propagate-security-guidance.sh --only-constitution
#   bash ~/scripts/propagate-security-guidance.sh --only-environment-registry
#
# Was das Script propagiert / What the script propagates:
#   1. Sicherheitsdokumentation-Sektion (XII–XVIII Extensions, alle 10 Templates)
#      in AGENTS.md, CLAUDE.md, GEMINI.md, .github/copilot-instructions.md
#   2. CRA/Prinzip-XIX-Referenz in der Sicherheitsstandards-Sektion aller Agent-Dateien
#   3. setup-git-identity-Known-Pitfall in CLAUDE.md
#   4. Prinzipien XVI (SBOM auf allen Ebenen + automatisierte Tools),
#      XVII (CIA-Matrix-Pflicht) und XIX (EU CRA) in .specify/memory/constitution.md

set -euo pipefail

# --- Konfiguration / Configuration --------------------------------------------

HOME_DIR="$(cd ~ && pwd)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/resolve-home-baseline-source.sh
source "${SCRIPT_DIR}/lib/resolve-home-baseline-source.sh"
LEVEL0_DIR="$(resolve_hb_source_repository "${BASH_SOURCE[0]}" 1)"
LEVEL0_CLAUDE="${LEVEL0_DIR}/CLAUDE.md"
LEVEL0_AGENTS="${LEVEL0_DIR}/AGENTS.md"
LEVEL0_GEMINI="${LEVEL0_DIR}/GEMINI.md"
LEVEL0_COPILOT="${LEVEL0_DIR}/.github/copilot-instructions.md"
LEVEL0_CONST="${LEVEL0_DIR}/constitution.md"

DRY_RUN=0
VERBOSE=0
ONLY_LEVEL1=0
ONLY_CONSTITUTION=0
ONLY_ENVIRONMENT_REGISTRY=0
CHANGED_COUNT=0
SKIPPED_COUNT=0

# --- Parameter / Arguments ----------------------------------------------------

while [ $# -gt 0 ]; do
  case "${1:-}" in
    --dry-run)            DRY_RUN=1 ;;
    --verbose|-v)         VERBOSE=1 ;;
    --only-level1)        ONLY_LEVEL1=1 ;;
    --only-constitution)  ONLY_CONSTITUTION=1 ;;
    --only-environment-registry) ONLY_ENVIRONMENT_REGISTRY=1 ;;
    --help|-h)
      echo "Verwendung / Usage: $(basename "$0") [OPTIONEN]"
      echo ""
      echo "  --dry-run           Vorschau ohne Schreiben / Preview without writing"
      echo "  --verbose,-v        Auch unveränderte Dateien anzeigen / Show unchanged files too"
      echo "  --only-level1       Nur Level-1-Repos, keine Level-2-Projekte"
      echo "  --only-constitution Nur .specify/memory/constitution.md-Dateien aktualisieren"
      echo "  --only-environment-registry Nur das Level-2-Umgebungsregister synchronisieren"
      echo ""
      echo "Canonical-Quellen / Canonical sources: $LEVEL0_DIR"
      exit 0
      ;;
    --) shift; break ;;
    --*) echo "Fehler: Unbekannte Option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$ONLY_CONSTITUTION" -eq 1 ] && [ "$ONLY_ENVIRONMENT_REGISTRY" -eq 1 ]; then
  echo "Fehler: --only-constitution und --only-environment-registry sind nicht kombinierbar." >&2
  exit 2
fi

# --- Vorabprüfungen / Prerequisite checks -------------------------------------

for f in "$LEVEL0_CLAUDE" "$LEVEL0_AGENTS" "$LEVEL0_CONST"; do
  if [ ! -f "$f" ]; then
    echo "Fehler: Level-0-Quelldatei nicht gefunden: $f" >&2
    echo "Error: Level-0 source file not found: $f" >&2
    exit 1
  fi
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "Fehler: python3 ist erforderlich." >&2
  echo "Error: python3 is required." >&2
  exit 1
fi

# --- Hilfsfunktionen / Helper functions ---------------------------------------

log()     { echo "  $*"; }
ok()      { echo "✓ $*"; }
info()    { echo "→ $*"; }
warn()    { echo "⚠ $*"; }

mark_changed() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] Würde ändern / Would change: $*"
  else
    echo "  [GEÄNDERT / CHANGED] $*"
  fi
  CHANGED_COUNT=$((CHANGED_COUNT + 1))
}

mark_skipped() {
  [ "$VERBOSE" -eq 1 ] && echo "  [OK] $*" || true
  SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
}

# Prüft ob eine Datei einen String enthält / Check if file contains a string
has_marker() { grep -qF "$1" "$2" 2>/dev/null; }

# Extrahiert einen Markdown-Abschnitt (## Heading bis nächstes ## oder EOF)
# Args: <Datei> <Heading-Prefix z. B. "## Sicherheitsdokumentation">
extract_section() {
  local file="$1" heading_prefix="$2"
  python3 - "$file" "$heading_prefix" <<'PYEOF'
import re, sys
with open(sys.argv[1], encoding='utf-8') as fh:
    content = fh.read()
prefix = re.escape(sys.argv[2])
# Match the heading line + body up to the next same-level heading or EOF
m = re.search(r'(' + prefix + r'[^\n]*\n)(.*?)(?=\n## |\Z)', content, re.DOTALL)
if m:
    print(m.group(0).rstrip())
PYEOF
}

# Ersetzt einen Markdown-Abschnitt in einer Datei
# Args: <Datei> <Heading-Prefix> <neuer Abschnittsinhalt>
replace_section_in_file() {
  local file="$1" heading_prefix="$2" new_content="$3"
  [ "$DRY_RUN" -eq 1 ] && return 0
  python3 - "$file" "$heading_prefix" "$new_content" <<'PYEOF'
import re, sys
file_path, prefix, new_content = sys.argv[1], re.escape(sys.argv[2]), sys.argv[3]
with open(file_path, encoding='utf-8') as fh:
    content = fh.read()
pattern = r'(' + prefix + r'[^\n]*\n)(.*?)(?=\n## |\Z)'
result = re.sub(pattern, lambda m: new_content + '\n', content, flags=re.DOTALL)
with open(file_path, 'w', encoding='utf-8') as fh:
    fh.write(result)
PYEOF
}

# Fügt am Ende eines Abschnitts neuen Inhalt ein (nur wenn Marker fehlt)
# Args: <Datei> <Heading-Prefix> <Marker> <hinzuzufügender Inhalt>
append_to_section_if_missing() {
  local file="$1" heading_prefix="$2" marker="$3" content_to_add="$4"
  has_marker "$marker" "$file" && return 1
  [ "$DRY_RUN" -eq 1 ] && return 0
  python3 - "$file" "$heading_prefix" "$content_to_add" <<'PYEOF'
import re, sys
file_path, prefix, content_to_add = sys.argv[1], re.escape(sys.argv[2]), sys.argv[3]
with open(file_path, encoding='utf-8') as fh:
    content = fh.read()
pattern = r'(' + prefix + r'[^\n]*\n)(.*?)(?=\n## |\Z)'
def replacement(m):
    return m.group(1) + m.group(2).rstrip() + '\n' + content_to_add + '\n'
result = re.sub(pattern, replacement, content, flags=re.DOTALL)
with open(file_path, 'w', encoding='utf-8') as fh:
    fh.write(result)
PYEOF
}

# Fügt einen Block vor einem bestimmten Heading ein
# Args: <Datei> <Marker für "bereits vorhanden"> <Anker-Heading> <einzufügender Block>
insert_before_heading_if_missing() {
  local file="$1" marker="$2" anchor_heading="$3" block="$4"
  has_marker "$marker" "$file" && return 1
  [ "$DRY_RUN" -eq 1 ] && return 0
  python3 - "$file" "$anchor_heading" "$block" <<'PYEOF'
import re, sys
file_path, anchor, block = sys.argv[1], re.escape(sys.argv[2]), sys.argv[3]
with open(file_path, encoding='utf-8') as fh:
    content = fh.read()
result = re.sub(r'(\n' + anchor + r'[^\n]*)', r'\n' + block + r'\n\1', content)
with open(file_path, 'w', encoding='utf-8') as fh:
    fh.write(result)
PYEOF
}

# --- Canonical-Inhalte zur Laufzeit aus Level-0 lesen -------------------------
# So bleibt das Script immer aktuell: Level-0 ändern → nächster Lauf propagiert es.

info "Lese Canonical-Inhalte aus Level-0 / Reading canonical content from Level-0..."

CANONICAL_SECDOC_CLAUDE="$(extract_section "$LEVEL0_CLAUDE" "## Sicherheitsdokumentation")"
CANONICAL_SECDOC_AGENTS="$(extract_section "$LEVEL0_AGENTS" "## Sicherheitsdokumentation")"
CANONICAL_SECDOC_GEMINI="$(extract_section "$LEVEL0_GEMINI" "### Sicherheit & Wartung")"
CANONICAL_SECDOC_COPILOT=""  # copilot-instructions hat andere Struktur; nur Marker-Check

CANONICAL_STANDARDS_CLAUDE="$(extract_section "$LEVEL0_CLAUDE" "## Sicherheitsstandards")"
CANONICAL_WORKFLOW_CLAUDE="$(extract_section "$LEVEL0_CLAUDE" "## Agentischer Security-Workflow")"

# Constitution-Ergänzungen aus Level-0 constitution.md extrahieren
CANONICAL_CONST_XIX="$(extract_section "$LEVEL0_CONST" "### XIX. EU Cyber Resilience")"
CANONICAL_CONST_XVII="$(extract_section "$LEVEL0_CONST" "### XVII. Threat Modeling")"
CANONICAL_CONST_XVI="$(extract_section "$LEVEL0_CONST" "### XVI. Supply-Chain")"
CANONICAL_ENVIRONMENT_REGISTRY="$(extract_section "$LEVEL0_CONST" "## Level-2 Project Environment Registry")"

# Fingerprints / Marker (eindeutige Strings aus dem aktualisierten Inhalt)
MARKER_SECDOC_COMPLETE="samm-assessment-template.md"           # alle 10 Templates
MARKER_CRA="XIX\|Cyber Resilience Act"                          # CRA-Referenz (grep-E)
MARKER_IDENTITY="setup-git-identity"                            # Known-Pitfall-Eintrag
MARKER_CONST_XIX="XIX. EU Cyber Resilience"                     # Prinzip XIX in CONST
MARKER_CONST_XVII_CIA="asset inventory with a CIA"              # CIA-Matrix in XVII
MARKER_CONST_XVI_SBOM="ALL workspace levels"                    # Erweitertes SBOM XVI

if [ -z "$CANONICAL_SECDOC_CLAUDE" ]; then
  echo "Fehler: Konnte Sicherheitsdokumentation-Sektion nicht aus Level-0 CLAUDE.md lesen." >&2
  exit 1
fi
if [ -z "$CANONICAL_CONST_XIX" ]; then
  echo "Fehler: Konnte Prinzip XIX nicht aus Level-0 constitution.md lesen." >&2
  exit 1
fi
if [ -z "$CANONICAL_ENVIRONMENT_REGISTRY" ]; then
  echo "Fehler: Konnte das Level-2-Umgebungsregister nicht aus Level-0 constitution.md lesen." >&2
  exit 1
fi
ok "Canonical-Inhalte geladen."
echo ""

# --- Repo-Erkennung / Repository discovery ------------------------------------
# Level-1: direkte Unterverzeichnisse von ~/ mit .git + Agent-Dateien (nicht Level-0)
# Level-2: Unterverzeichnisse von Level-1-Repos mit .git + Agent-Dateien

discover_repos() {
  local repos=()
  for dir in "${HOME_DIR}"/*/; do
    dir="${dir%/}"
    [ -d "$dir/.git" ] || continue
    [ "$dir" = "$LEVEL0_DIR" ] && continue  # Level-0 überspringen
    { [ -f "$dir/AGENTS.md" ] || [ -f "$dir/CLAUDE.md" ]; } || continue
    repos+=("$dir")
    [ "$ONLY_LEVEL1" -eq 1 ] && continue
    # Level-2: Unterverzeichnisse dieses Level-1-Repos
    for subdir in "$dir"/*/; do
      subdir="${subdir%/}"
      [ -d "$subdir" ] || continue
      [ -d "$subdir/.git" ] || continue
      { [ -f "$subdir/AGENTS.md" ] || [ -f "$subdir/CLAUDE.md" ]; } || continue
      repos+=("$subdir")
    done
  done
  # Bash 3.x-sicher: kein ${array[@]+...}-Muster
  local i
  for i in "${!repos[@]}"; do
    printf '%s\n' "${repos[$i]}"
  done
}

# Bash 3.x-kompatibel: kein mapfile / Bash 3.x compatible: no mapfile
REPOS=()
while IFS= read -r _repo_line; do
  [ -n "$_repo_line" ] && REPOS+=("$_repo_line")
done < <(discover_repos)

if [ "${#REPOS[@]}" -eq 0 ]; then
  warn "Keine Level-1/Level-2-Repos gefunden unter ${HOME_DIR}."
  exit 0
fi

info "Gefundene Repos / Discovered repos: ${#REPOS[@]}"
for _ri in "${!REPOS[@]}"; do
  log "${REPOS[$_ri]}"
done
echo ""

# --- Anwenden der Änderungen / Apply changes ----------------------------------

apply_agent_file_updates() {
  local repo="$1"
  local label
  label="$(basename "$repo")"

  # Dateien die in diesem Repo existieren
  local claude_md="${repo}/CLAUDE.md"
  local agents_md="${repo}/AGENTS.md"
  local gemini_md="${repo}/GEMINI.md"
  local copilot_md="${repo}/.github/copilot-instructions.md"

  # --- CLAUDE.md ---
  if [ -f "$claude_md" ]; then
    local changed_claude=0

    # 1. Sicherheitsdokumentation-Sektion: alle 10 Templates prüfen
    if ! has_marker "$MARKER_SECDOC_COMPLETE" "$claude_md"; then
      mark_changed "$label/CLAUDE.md: Sicherheitsdokumentation-Sektion (alle 10 Templates)"
      replace_section_in_file "$claude_md" "## Sicherheitsdokumentation" \
        "$CANONICAL_SECDOC_CLAUDE"
      changed_claude=1
    else
      mark_skipped "$label/CLAUDE.md: Sicherheitsdokumentation OK"
    fi

    # 2. Sicherheitsstandards-Sektion: CRA / Prinzip XIX
    if ! grep -qE "$MARKER_CRA" "$claude_md" 2>/dev/null; then
      mark_changed "$label/CLAUDE.md: Sicherheitsstandards-Sektion (CRA/XIX)"
      replace_section_in_file "$claude_md" "## Sicherheitsstandards" \
        "$CANONICAL_STANDARDS_CLAUDE"
      changed_claude=1
    else
      mark_skipped "$label/CLAUDE.md: Sicherheitsstandards-CRA OK"
    fi

    # 3. Agentischer Security-Workflow-Sektion: ebenfalls aus Level-0 übernehmen
    if [ -n "$CANONICAL_WORKFLOW_CLAUDE" ] && \
       ! has_marker "docs/security/samm-assessment.md" "$claude_md"; then
      mark_changed "$label/CLAUDE.md: Agentischer-Security-Workflow-Sektion"
      replace_section_in_file "$claude_md" "## Agentischer Security-Workflow" \
        "$CANONICAL_WORKFLOW_CLAUDE"
      changed_claude=1
    else
      mark_skipped "$label/CLAUDE.md: Agentischer-Security-Workflow OK"
    fi

    # 4. setup-git-identity Known Pitfall (CLAUDE.md only)
    if ! has_marker "$MARKER_IDENTITY" "$claude_md"; then
      local pitfall_block
      pitfall_block="$(extract_section "$LEVEL0_CLAUDE" "### Git-Identität: Platzhalter")"
      if [ -n "$pitfall_block" ]; then
        mark_changed "$label/CLAUDE.md: setup-git-identity Known Pitfall"
        append_to_section_if_missing "$claude_md" "### Bekannte Fallstricke" \
          "$MARKER_IDENTITY" "$pitfall_block"
        changed_claude=1
      fi
    else
      mark_skipped "$label/CLAUDE.md: setup-git-identity-Pitfall OK"
    fi

    [ "$changed_claude" -eq 0 ] || true  # Logging bereits oben
  fi

  # --- AGENTS.md ---
  if [ -f "$agents_md" ]; then
    local changed_agents=0

    if ! has_marker "$MARKER_SECDOC_COMPLETE" "$agents_md"; then
      if [ -n "$CANONICAL_SECDOC_AGENTS" ]; then
        mark_changed "$label/AGENTS.md: Sicherheitsdokumentation-Sektion (alle 10 Templates)"
        replace_section_in_file "$agents_md" "## Sicherheitsdokumentation" \
          "$CANONICAL_SECDOC_AGENTS"
        changed_agents=1
      fi
    else
      mark_skipped "$label/AGENTS.md: Sicherheitsdokumentation OK"
    fi

    if ! grep -qE "$MARKER_CRA" "$agents_md" 2>/dev/null; then
      local agents_standards
      agents_standards="$(extract_section "$LEVEL0_AGENTS" "## Sicherheitsstandards")"
      if [ -n "$agents_standards" ]; then
        mark_changed "$label/AGENTS.md: Sicherheitsstandards-Sektion (CRA/XIX)"
        replace_section_in_file "$agents_md" "## Sicherheitsstandards" \
          "$agents_standards"
        changed_agents=1
      fi
    else
      mark_skipped "$label/AGENTS.md: Sicherheitsstandards-CRA OK"
    fi

    [ "$changed_agents" -eq 0 ] || true
  fi

  # --- GEMINI.md ---
  if [ -f "$gemini_md" ]; then
    # GEMINI.md hat eine andere Struktur — nur prüfen ob git-identity fehlt
    if ! has_marker "$MARKER_IDENTITY" "$gemini_md"; then
      if has_marker "setup-git-identity" "$LEVEL0_GEMINI"; then
        local gemini_security
        gemini_security="$(extract_section "$LEVEL0_GEMINI" "### Sicherheit & Wartung")"
        if [ -n "$gemini_security" ]; then
          mark_changed "$label/GEMINI.md: Sicherheit-&-Wartung-Sektion (setup-git-identity)"
          replace_section_in_file "$gemini_md" "### Sicherheit & Wartung" \
            "$gemini_security"
        fi
      fi
    else
      mark_skipped "$label/GEMINI.md: setup-git-identity OK"
    fi

    if ! grep -qE "$MARKER_CRA" "$gemini_md" 2>/dev/null; then
      local gemini_cra
      gemini_cra="$(extract_section "$LEVEL0_GEMINI" "## Sicherheitsstandards" 2>/dev/null || true)"
      if [ -n "$gemini_cra" ]; then
        mark_changed "$label/GEMINI.md: Sicherheitsstandards-Sektion (CRA/XIX)"
        replace_section_in_file "$gemini_md" "## Sicherheitsstandards" "$gemini_cra"
      fi
    else
      mark_skipped "$label/GEMINI.md: Sicherheitsstandards-CRA OK"
    fi
  fi

  # --- .github/copilot-instructions.md ---
  if [ -f "$copilot_md" ]; then
    if ! has_marker "$MARKER_SECDOC_COMPLETE" "$copilot_md"; then
      local copilot_secdoc
      copilot_secdoc="$(extract_section "$LEVEL0_COPILOT" "## Sicherheitsdokumentation" 2>/dev/null || true)"
      if [ -n "$copilot_secdoc" ]; then
        mark_changed "$label/.github/copilot-instructions.md: Sicherheitsdokumentation-Sektion"
        replace_section_in_file "$copilot_md" "## Sicherheitsdokumentation" \
          "$copilot_secdoc"
      fi
    else
      mark_skipped "$label/.github/copilot-instructions.md: Sicherheitsdokumentation OK"
    fi

    if ! has_marker "$MARKER_IDENTITY" "$copilot_md"; then
      local copilot_identity
      copilot_identity="$(extract_section "$LEVEL0_COPILOT" "## Git-Identität" 2>/dev/null || true)"
      if [ -n "$copilot_identity" ]; then
        mark_changed "$label/.github/copilot-instructions.md: setup-git-identity"
        replace_section_in_file "$copilot_md" "## Git-Identität" "$copilot_identity"
      fi
    else
      mark_skipped "$label/.github/copilot-instructions.md: setup-git-identity OK"
    fi
  fi
}

apply_constitution_updates() {
  local repo="$1"
  local label
  label="$(basename "$repo")"
  local const_file="${repo}/.specify/memory/constitution.md"

  [ -f "$const_file" ] || return 0

  local changed=0

  # Prinzip XIX (EU CRA) — vor dem Level-2-Registry-Abschnitt einfügen
  if ! has_marker "$MARKER_CONST_XIX" "$const_file"; then
    mark_changed "$label/.specify/memory/constitution.md: Prinzip XIX (EU CRA)"
    insert_before_heading_if_missing "$const_file" \
      "$MARKER_CONST_XIX" \
      "## Level-2 Project Environment Registry" \
      "$CANONICAL_CONST_XIX"
    changed=1
  else
    mark_skipped "$label/.specify/memory/constitution.md: Prinzip XIX OK"
  fi

  # Prinzip XVII — CIA-Matrix als erste Regel (den ganzen Abschnitt ersetzen)
  if ! has_marker "$MARKER_CONST_XVII_CIA" "$const_file"; then
    mark_changed "$label/.specify/memory/constitution.md: Prinzip XVII (CIA-Matrix)"
    replace_section_in_file "$const_file" "### XVII. Threat Modeling" \
      "$CANONICAL_CONST_XVII"
    changed=1
  else
    mark_skipped "$label/.specify/memory/constitution.md: Prinzip XVII CIA OK"
  fi

  # Prinzip XVI — SBOM auf allen Levels + automatisierte Tools
  if ! has_marker "$MARKER_CONST_XVI_SBOM" "$const_file"; then
    mark_changed "$label/.specify/memory/constitution.md: Prinzip XVI (SBOM alle Levels)"
    replace_section_in_file "$const_file" "### XVI. Supply-Chain" \
      "$CANONICAL_CONST_XVI"
    changed=1
  else
    mark_skipped "$label/.specify/memory/constitution.md: Prinzip XVI SBOM OK"
  fi

  [ "$changed" -eq 0 ] || true
}

apply_environment_registry_updates() {
  local repo="$1"
  local label current_section const_file relative_path
  label="$(basename "$repo")"

  for const_file in \
    "${repo}/constitution.md" \
    "${repo}/.specify/memory/constitution.md"; do
    relative_path="${const_file#"$repo"/}"
    if [ ! -f "$const_file" ]; then
      warn "$label: Constitution-Datei fehlt: $relative_path"
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
      continue
    fi

    current_section="$(extract_section "$const_file" "## Level-2 Project Environment Registry")"
    if [ -z "$current_section" ]; then
      warn "$label: Level-2-Umgebungsregister fehlt in $relative_path"
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    elif [ "$current_section" = "$CANONICAL_ENVIRONMENT_REGISTRY" ]; then
      mark_skipped "$label/$relative_path: Level-2-Umgebungsregister OK"
    else
      mark_changed "$label/$relative_path: Level-2-Umgebungsregister"
      replace_section_in_file "$const_file" \
        "## Level-2 Project Environment Registry" \
        "$CANONICAL_ENVIRONMENT_REGISTRY"
    fi
  done
}

# --- Hauptschleife / Main loop ------------------------------------------------

# Bash 3.x-sicher: Index-Iteration statt direkter Array-Expansion
for _main_i in "${!REPOS[@]}"; do
  repo="${REPOS[$_main_i]}"
  echo "┌─ $(basename "$repo") ($repo)"

  if [ "$ONLY_ENVIRONMENT_REGISTRY" -eq 1 ]; then
    apply_environment_registry_updates "$repo"
  else
    if [ "$ONLY_CONSTITUTION" -eq 0 ]; then
      apply_agent_file_updates "$repo"
    fi
    apply_constitution_updates "$repo"
  fi

  echo "└─ fertig / done"
  echo ""
done

# --- Zusammenfassung / Summary ------------------------------------------------

echo "════════════════════════════════════════════════"
echo "  Repos verarbeitet / Repos processed : ${#REPOS[@]}"
echo "  Änderungen        / Changes         : ${CHANGED_COUNT}"
echo "  Unverändert       / Unchanged       : ${SKIPPED_COUNT}"
[ "$DRY_RUN" -eq 1 ] && echo "  [DRY-RUN] Keine Dateien wurden geschrieben."
echo "════════════════════════════════════════════════"

if [ "$CHANGED_COUNT" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  echo ""
  echo "  Nächster Schritt / Next step:"
  echo "  → Änderungen prüfen und in jedem betroffenen Repo committen."
  echo "  → Review changes and commit in each affected repo."
fi
