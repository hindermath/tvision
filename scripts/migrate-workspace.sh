#!/usr/bin/env bash
# migrate-workspace.sh — Workspace Homogeneity Migration v1.0
# FR-REV-A01–A06; Contract: migrate-workspace-cli.md
#
# Usage: migrate-workspace.sh [workspace-name] [--dry-run] [--yes]
# Exit codes: 0=success, 1=partial fail, 2=critical error
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
WORKSPACE_GITIGNORE_HEADER="# Sub-Verzeichnisse mit eigenen Git-Repositories (automatisch erkannt)"
WORKSPACE_GITIGNORE_RESULT="unchanged"

# ─── Argument Parsing ────────────────────────────────────────────────────────

OPT_DRY_RUN=false
OPT_YES=false
WORKSPACE_NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) OPT_DRY_RUN=true ;;
    --yes)     OPT_YES=true ;;
    --)
      shift
      if [ $# -gt 0 ] && [ -z "$WORKSPACE_NAME" ]; then WORKSPACE_NAME="$1"; shift; fi
      continue ;;
    --*) echo "ERROR: unknown option $1" >&2; exit 2 ;;
    *) WORKSPACE_NAME="$1" ;;
  esac
  shift
done

# ─── Prerequisites ────────────────────────────────────────────────────────────

for tmpl in a11y-section.md speckit-workflow-section.md azubis-section.md; do
  if ! [ -f "${TEMPLATES_DIR}/${tmpl}" ]; then
    echo "ERROR: template not found: scripts/templates/${tmpl}" >&2
    exit 1
  fi
done

# Get constitution version
constitution_file="${HOME}/constitution.md"
if [ -f "$constitution_file" ]; then
  constitution_version=$(grep -m1 '^# Constitution v' "$constitution_file" 2>/dev/null | grep -o 'v[0-9.]*' || echo "v1.0.0")
else
  constitution_version="v1.0.0"
fi

# ─── homogeneity-check.yml Template ─────────────────────────────────────────

workflow_uses_legacy_check() {
  local yml_file="$1"
  [ -f "$yml_file" ] || return 1
  rg -q 'scripts/check-homogeneity\.(sh|ps1)|-WorkspaceName' "$yml_file"
}

write_workflow_yml() {
  local target_dir="$1"
  local yml_dir="${target_dir}/.github/workflows"
  local yml_file="${yml_dir}/homogeneity-check.yml"
  local workflow_action="CREATED"
  if [ -f "$yml_file" ]; then
    if workflow_uses_legacy_check "$yml_file"; then
      workflow_action="UPDATED"
      if $OPT_DRY_RUN; then
        echo "  WOULD UPDATE: ${yml_file/#$HOME/~}"
        return 0
      fi
      mkdir -p "$yml_dir"
    else
      echo "  INFO: homogeneity-check.yml already present — skip"
      return 0
    fi
  fi
  if $OPT_DRY_RUN; then
    echo "  WOULD CREATE: ${yml_file/#$HOME/~}"
    return 0
  fi
  mkdir -p "$yml_dir"
  cat > "$yml_file" <<'YMLEOF'
name: Homogeneity Check

on:
  push:
  pull_request:

jobs:
  check:
    name: Agent Secret Scan (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    timeout-minutes: 10

    strategy:
      matrix:
        os: [ubuntu-22.04, macos-14, windows-2022]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install ripgrep (Ubuntu)
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y ripgrep

      - name: Install ripgrep (macOS)
        if: runner.os == 'macOS'
        run: brew install ripgrep

      - name: Install ripgrep (Windows)
        if: runner.os == 'Windows'
        run: choco install ripgrep -y

      - name: Run Agent Secret Scan (Bash)
        if: runner.os != 'Windows'
        run: bash scripts/scan-agent-secrets.sh --fail-on-high .

      - name: Run Agent Secret Scan (Bash on Windows)
        if: runner.os == 'Windows'
        shell: bash
        run: bash scripts/scan-agent-secrets.sh --fail-on-high .
YMLEOF
  echo "  ${workflow_action}: ${yml_file/#$HOME/~}"
}

# ─── .editorconfig for C# projects ───────────────────────────────────────────

write_editorconfig() {
  local target_dir="$1"
  local ec_file="${target_dir}/.editorconfig"
  if [ -f "$ec_file" ]; then
    echo "  INFO: .editorconfig already present — skip"
    return 0
  fi
  # Only for C# projects
  if ! find "$target_dir" -maxdepth 1 -name "*.sln" 2>/dev/null | grep -q .; then
    return 0
  fi
  if $OPT_DRY_RUN; then
    echo "  WOULD CREATE: ${ec_file/#$HOME/~}"
    return 0
  fi
  cat > "$ec_file" <<'ECEOF'
root = true

[*]
charset = utf-8
end_of_line = crlf
indent_style = space
indent_size = 4
trim_trailing_whitespace = true
insert_final_newline = true

[*.cs]
indent_size = 4

[*.md]
trim_trailing_whitespace = false
indent_size = 2

[*.{yml,yaml,json}]
indent_size = 2
ECEOF
  echo "  CREATED: ${ec_file/#$HOME/~}"
}

write_workspace_gitignore() {
  local gitignore_path="$1"
  shift

  {
    printf '%s\n' "$WORKSPACE_GITIGNORE_HEADER"
    while [ "$#" -gt 0 ]; do
      printf '%s/\n' "$1"
      shift
    done
    cat <<'EOF'

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
EOF
  } > "$gitignore_path"
}

ensure_workspace_gitignore_entry() {
  local workspace_dir="$1"
  local project_name="$2"
  local gitignore_path="${workspace_dir}/.gitignore"
  local entry="${project_name}/"
  local tmp_file=""

  WORKSPACE_GITIGNORE_RESULT="unchanged"

  if [ -z "$project_name" ]; then
    return 1
  fi

  if [ ! -f "$gitignore_path" ]; then
    if $OPT_DRY_RUN; then
      WORKSPACE_GITIGNORE_RESULT="would-create"
      return 0
    fi
    write_workspace_gitignore "$gitignore_path" "$project_name"
    WORKSPACE_GITIGNORE_RESULT="created"
    return 0
  fi

  if grep -Fxq "$entry" "$gitignore_path"; then
    return 1
  fi

  if $OPT_DRY_RUN; then
    WORKSPACE_GITIGNORE_RESULT="would-update"
    return 0
  fi

  tmp_file="$(mktemp)"
  if grep -Fxq "$WORKSPACE_GITIGNORE_HEADER" "$gitignore_path"; then
    awk -v header="$WORKSPACE_GITIGNORE_HEADER" -v entry="$entry" '
      BEGIN {
        saw_header = 0
        in_section = 0
        inserted = 0
      }
      {
        if (!saw_header && $0 == header) {
          saw_header = 1
          in_section = 1
          print
          next
        }
        if (in_section && $0 == "") {
          print entry
          print
          inserted = 1
          in_section = 0
          next
        }
        print
      }
      END {
        if (saw_header && in_section && !inserted) {
          print entry
        }
      }
    ' "$gitignore_path" > "$tmp_file"
  else
    {
      printf '%s\n' "$WORKSPACE_GITIGNORE_HEADER"
      printf '%s\n\n' "$entry"
      cat "$gitignore_path"
    } > "$tmp_file"
  fi

  mv "$tmp_file" "$gitignore_path"
  WORKSPACE_GITIGNORE_RESULT="updated"
  return 0
}

# ─── Append EN Guidance Placeholder ───────────────────────────────────────────

has_en_guidance() {
  local file="$1"
  [ -f "$file" ] || return 1
  if rg -q '<!-- EN:' "$file" 2>/dev/null; then
    return 0
  fi
  if rg -qi '^#{1,6}[[:space:]].+[[:space:]]/[[:space:]].*(Shared|Environment|Registry|Security|Secure|Architecture|Documentation|Standards|Workflow|Maintenance|Notes|Description|Accessibility|For Apprentices|Spec[- ]Kit|Governance|Guidelines|Instructions|tooling)' "$file" 2>/dev/null; then
    return 0
  fi
  if rg -qi '(Gemeinsame|Barrierefreiheit|Sichere|Sicherheits|Umgebungsregister|Hinweise|Beschreibung|deutsch)' "$file" 2>/dev/null &&
     rg -qi '(Shared|Accessibility|Secure|Security|Environment|Notes|Description|English|englisch)' "$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

append_en_placeholder() {
  local file="$1" label="$2"
  if ! [ -f "$file" ]; then return 0; fi
  if has_en_guidance "$file"; then
    echo "  INFO: EN guidance already present — skip (${file/#$HOME/~})"
    return 0
  fi
  local basename_label="${label:-$(basename "$file")}"
  if $OPT_DRY_RUN; then
    echo "  WOULD APPEND: EN placeholder to ${file/#$HOME/~}"
    return 0
  fi
  {
    printf '\n<!-- EN: %s placeholder\n' "$basename_label"
    printf '%s\n' '[DE-Zusammenfassung: Inhalt dieser Datei auf Deutsch]'
    printf '%s\n' '-->'
  } >> "$file"
  echo "  APPENDED: EN placeholder to ${file/#$HOME/~}"
}

# ─── Append README Sections ───────────────────────────────────────────────────

append_readme_section() {
  local readme="$1" section_file="$2" heading_pattern="$3"
  if ! [ -f "$readme" ]; then return 0; fi
  if rg -qi "$heading_pattern" "$readme" 2>/dev/null; then
    echo "  INFO: section already present — skip ($(basename "$section_file") in $(basename "$readme"))"
    return 0
  fi
  if $OPT_DRY_RUN; then
    echo "  WOULD APPEND: $(basename "$section_file") to ${readme/#$HOME/~}"
    return 0
  fi
  printf '\n' >> "$readme"
  cat "$section_file" >> "$readme"
  echo "  APPENDED: $(basename "$section_file") to ${readme/#$HOME/~}"
}

# ─── Install pre-push Hook ────────────────────────────────────────────────────

install_hook_if_needed() {
  local target_dir="$1"
  local hook_src="${HOME}/scripts/hooks/pre-push"
  local hook_dst="${target_dir}/.git/hooks/pre-push"
  [ -d "${target_dir}/.git" ] || return 0
  [ -f "$hook_src" ] || return 0
  if [ -f "$hook_dst" ]; then
    echo "  INFO: pre-push hook already installed — skip (${target_dir/#$HOME/~})"
    return 0
  fi
  if $OPT_DRY_RUN; then
    echo "  WOULD INSTALL: pre-push hook in ${target_dir/#$HOME/~}"
    return 0
  fi
  mkdir -p "${target_dir}/.git/hooks"
  cp "$hook_src" "$hook_dst"
  chmod +x "$hook_dst"
  echo "  INSTALLED: pre-push hook in ${target_dir/#$HOME/~}"
}

# ─── Migrate Single Workspace ────────────────────────────────────────────────

PARTIAL_FAIL=false

migrate_workspace() {
  local ws_dir="$1"
  local ws_name
  ws_name=$(basename "$ws_dir")

  echo "Migriere: ${ws_dir/#$HOME/~}"

  # Safety: check for uncommitted changes (warn but proceed)
  if git -C "$ws_dir" diff --quiet HEAD 2>/dev/null && git -C "$ws_dir" diff --cached --quiet HEAD 2>/dev/null; then
    true  # clean
  else
    echo "  WARN: uncommittete Änderungen in ${ws_name} — Rollback via git stash falls nötig"
  fi

  local changed=false

  # Append EN placeholders to agent/governance files when no EN guidance exists yet
  for agent_file in AGENTS.md CLAUDE.md GEMINI.md constitution.md; do
    if [ -f "${ws_dir}/${agent_file}" ]; then
      if ! has_en_guidance "${ws_dir}/${agent_file}"; then
        changed=true
      fi
      append_en_placeholder "${ws_dir}/${agent_file}" "$agent_file"
    fi
  done

  # copilot-instructions.md
  local copilot_file="${ws_dir}/.github/copilot-instructions.md"
  if [ -f "$copilot_file" ]; then
    if ! has_en_guidance "$copilot_file"; then
      changed=true
    fi
    append_en_placeholder "$copilot_file" "copilot-instructions.md"
  fi

  # README.md sections
  local readme="${ws_dir}/README.md"
  if [ -f "$readme" ]; then
    if ! rg -qi '^## .*Barrierefreiheit' "$readme" 2>/dev/null; then changed=true; fi
    append_readme_section "$readme" "${TEMPLATES_DIR}/a11y-section.md" '^## .*Barrierefreiheit'

    if ! rg -qi '^## .*Spec-kit' "$readme" 2>/dev/null; then changed=true; fi
    append_readme_section "$readme" "${TEMPLATES_DIR}/speckit-workflow-section.md" '^## .*Spec-kit'

    if ! rg -qi '^## .*Azubis' "$readme" 2>/dev/null; then changed=true; fi
    append_readme_section "$readme" "${TEMPLATES_DIR}/azubis-section.md" '^## .*Azubis'
  fi

  # homogeneity-check.yml for Level-1 workspace
  if ! [ -f "${ws_dir}/.github/workflows/homogeneity-check.yml" ]; then
    changed=true
  fi
  write_workflow_yml "$ws_dir"

  # Level-2 projects within this workspace
  while IFS= read -r proj_dir; do
    [ -d "${proj_dir}/.git" ] || continue
    local proj_name
    proj_name=$(basename "$proj_dir")
    echo "  Level-2: ${proj_name}/"

    if ensure_workspace_gitignore_entry "$ws_dir" "$proj_name"; then
      changed=true
      case "$WORKSPACE_GITIGNORE_RESULT" in
        created)
          echo "  CREATED: ${ws_dir/#$HOME/~}/.gitignore (+ ${proj_name}/)"
          ;;
        updated)
          echo "  UPDATED: ${ws_dir/#$HOME/~}/.gitignore (+ ${proj_name}/)"
          ;;
        would-create)
          echo "  WOULD CREATE: ${ws_dir/#$HOME/~}/.gitignore (+ ${proj_name}/)"
          ;;
        would-update)
          echo "  WOULD UPDATE: ${ws_dir/#$HOME/~}/.gitignore (+ ${proj_name}/)"
          ;;
      esac
    else
      echo "  INFO: workspace .gitignore already lists ${proj_name}/ — skip"
    fi

    local proj_changed=false

    # constitution.md — copy from workspace parent
    local src_const="${ws_dir}/constitution.md"
    [ -f "$src_const" ] || src_const="${HOME}/constitution.md"
    if [ -f "$src_const" ]; then
      if ! [ -f "${proj_dir}/constitution.md" ]; then
        proj_changed=true
        if $OPT_DRY_RUN; then
          echo "    WOULD COPY: constitution.md to ${proj_name}/"
        else
          cp "$src_const" "${proj_dir}/constitution.md"
          echo "    COPIED: constitution.md to ${proj_name}/"
        fi
      fi
    fi

    # README.md sections
    local proj_readme="${proj_dir}/README.md"
    if [ -f "$proj_readme" ]; then
      if ! rg -qi '^## .*Barrierefreiheit' "$proj_readme" 2>/dev/null; then proj_changed=true; fi
      append_readme_section "$proj_readme" "${TEMPLATES_DIR}/a11y-section.md" '^## .*Barrierefreiheit'

      if ! rg -qi '^## .*Spec-kit' "$proj_readme" 2>/dev/null; then proj_changed=true; fi
      append_readme_section "$proj_readme" "${TEMPLATES_DIR}/speckit-workflow-section.md" '^## .*Spec-kit'

      if ! rg -qi '^## .*Azubis' "$proj_readme" 2>/dev/null; then proj_changed=true; fi
      append_readme_section "$proj_readme" "${TEMPLATES_DIR}/azubis-section.md" '^## .*Azubis'
    fi

    # homogeneity-check.yml
    if ! [ -f "${proj_dir}/.github/workflows/homogeneity-check.yml" ]; then
      proj_changed=true
    fi
    write_workflow_yml "$proj_dir"

    # .editorconfig for C# projects
    if find "$proj_dir" -maxdepth 1 -name "*.sln" 2>/dev/null | grep -q .; then
      if ! [ -f "${proj_dir}/.editorconfig" ]; then proj_changed=true; fi
      write_editorconfig "$proj_dir"
    fi

    # pre-push hook
    install_hook_if_needed "$proj_dir"

    # Commit Level-2 changes
    if ! $OPT_DRY_RUN && [ -n "$(git -C "$proj_dir" status --porcelain 2>/dev/null)" ]; then
      git -C "$proj_dir" add -A 2>/dev/null || true
      git -C "$proj_dir" commit -m "chore: migrate ${proj_name} to homogeneity baseline ${constitution_version}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" >/dev/null 2>&1 || true
      echo "    COMMITTED: migrate ${proj_name}"
    fi

  done < <(find "$ws_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

  if ! $changed; then
    echo "  INFO: already compliant — nothing to do"
    return 0
  fi

  if $OPT_DRY_RUN; then
    echo "  [dry-run: no changes written]"
    return 0
  fi

  # Git commit
  if git -C "$ws_dir" diff --quiet HEAD 2>/dev/null && git -C "$ws_dir" diff --cached --quiet HEAD 2>/dev/null; then
    # Check for untracked new files
    if [ -z "$(git -C "$ws_dir" status --porcelain 2>/dev/null)" ]; then
      echo "  INFO: nothing changed to commit"
    fi
  fi

  if [ -n "$(git -C "$ws_dir" status --porcelain 2>/dev/null)" ]; then
    git -C "$ws_dir" add -A 2>/dev/null || true
    git -C "$ws_dir" commit -m "chore: migrate ${ws_name} to homogeneity baseline ${constitution_version}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" >/dev/null 2>&1 || true
    echo "  COMMITTED: migrate ${ws_name} to homogeneity baseline ${constitution_version}"
  fi

  echo ""
}

# ─── Build Workspace List ─────────────────────────────────────────────────────

if [ -n "$WORKSPACE_NAME" ]; then
  ws_dir="${HOME}/${WORKSPACE_NAME}"
  if ! [ -d "$ws_dir" ]; then
    echo "ERROR: Workspace nicht gefunden: ${ws_dir}" >&2
    exit 2
  fi
  WORKSPACES=("$ws_dir")
else
  WORKSPACES=()
  while IFS= read -r d; do
    [ -d "${d}/.git" ] && WORKSPACES+=("$d")
  done < <(find "$HOME" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
fi

if [ ${#WORKSPACES[@]} -eq 0 ]; then
  echo "Keine Level-1-Workspaces gefunden."
  exit 0
fi

# ─── Preview ─────────────────────────────────────────────────────────────────

echo "Workspace Homogeneity Migration"
echo "Constitution: ${constitution_version}"
printf '%.0s=' {1..50}; echo
echo ""
echo "Betroffene Workspaces / Affected workspaces:"
for ws in "${WORKSPACES[@]}"; do
  echo "  -> ${ws/#$HOME/~}"
done
echo ""

if $OPT_DRY_RUN; then
  echo "[DRY-RUN] Vorschau / Preview:"
  for ws in "${WORKSPACES[@]}"; do
    OPT_DRY_RUN=true migrate_workspace "$ws"
  done
  exit 0
fi

# ─── Prompt ──────────────────────────────────────────────────────────────────

if ! $OPT_YES; then
  printf "Proceed? [y/N] "
  read -r answer
  if ! echo "$answer" | grep -qiE '^[jy]'; then
    echo "Abgebrochen."
    exit 0
  fi
fi

# ─── Execute Migration ────────────────────────────────────────────────────────

for ws in "${WORKSPACES[@]}"; do
  if ! migrate_workspace "$ws"; then
    echo "WARN: Migration fehlgeschlagen für ${ws/#$HOME/~} — weiter mit nächstem" >&2
    PARTIAL_FAIL=true
  fi
done

# ─── Post-Migration: init-stats ───────────────────────────────────────────────

if [ -f "${SCRIPT_DIR}/init-stats.sh" ]; then
  echo "Starte init-stats.sh..."
  bash "${SCRIPT_DIR}/init-stats.sh" 2>/dev/null || true
fi

echo ""
printf '%.0s=' {1..50}; echo
if $PARTIAL_FAIL; then
  echo "Migration teilweise abgeschlossen (Warnungen vorhanden)"
  exit 1
fi
echo "Migration abgeschlossen ✓"
exit 0
