#!/usr/bin/env bash
# update-spec-kit.sh — Refresh Spec-Kit integrations across home-baseline repos.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOME_DIR="${HOME}"
# shellcheck source=scripts/lib/resolve-home-baseline-source.sh
source "${SCRIPT_DIR}/lib/resolve-home-baseline-source.sh"
LEVEL0_SOURCE="$(resolve_hb_source_repository "${BASH_SOURCE[0]}" 1)"

AGENTS=(claude opencode agy copilot codex)
OPT_DRY_RUN=false
OPT_COMMIT=false
OPT_PUSH=false
OPT_ALLOW_DIRTY=false
TEMPLATE_SOURCE=""

usage() {
  cat <<'EOF'
update-spec-kit.sh — Spec-Kit-Integrationen aktualisieren / refresh Spec-Kit integrations

Usage:
  bash scripts/update-spec-kit.sh [options]

Options:
  --home-dir PATH          Home directory to scan (default: $HOME)
  --template-source PATH   Repo whose local governance templates are canonical
                           (default: repository running this script)
  --agents LIST            Comma-separated integrations (default: claude,opencode,agy,copilot,codex)
  --commit                 Commit changes in each changed repo
  --push                   Push current branch after commit/check
  --allow-dirty            Continue even if a repo already has local changes
  --dry-run                Show targets and actions only
  -h, --help               Show this help
EOF
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Fehler: %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --home-dir)
      [ $# -ge 2 ] || die "--home-dir braucht einen Pfad"
      HOME_DIR="$2"
      shift 2
      ;;
    --template-source)
      [ $# -ge 2 ] || die "--template-source braucht einen Pfad"
      TEMPLATE_SOURCE="$2"
      shift 2
      ;;
    --agents)
      [ $# -ge 2 ] || die "--agents braucht eine Liste"
      IFS=',' read -r -a AGENTS <<< "$2"
      shift 2
      ;;
    --commit)
      OPT_COMMIT=true
      shift
      ;;
    --push)
      OPT_PUSH=true
      OPT_COMMIT=true
      shift
      ;;
    --allow-dirty)
      OPT_ALLOW_DIRTY=true
      shift
      ;;
    --dry-run)
      OPT_DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unbekannte Option: $1"
      ;;
  esac
done

command -v git >/dev/null 2>&1 || die "git nicht gefunden"
if ! $OPT_DRY_RUN; then
  command -v specify >/dev/null 2>&1 || die "specify nicht gefunden"
fi

is_spec_repo() {
  [ -e "$1/.git" ] && [ -d "$1/.specify" ] &&
    git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

contains_repo() {
  local needle="$1"
  local item
  for item in "${REPOS[@]+"${REPOS[@]}"}"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

add_repo() {
  local repo="$1"
  [ -d "$repo" ] || return 0
  is_spec_repo "$repo" || return 0
  contains_repo "$repo" && return 0
  REPOS+=("$repo")
}

discover_repos() {
  REPOS=()

  add_repo "$LEVEL0_SOURCE"

  local workspace project
  for workspace in "${HOME_DIR}"/*; do
    [ -d "$workspace" ] || continue
    [ "$workspace" = "$LEVEL0_SOURCE" ] && continue
    add_repo "$workspace"

    if is_spec_repo "$workspace"; then
      for project in "$workspace"/*; do
        [ -d "$project" ] || continue
        add_repo "$project"
      done
    fi
  done
}

select_template_source() {
  if [ -n "$TEMPLATE_SOURCE" ]; then
    return
  fi

  if [ -d "$REPO_DIR/.specify/templates" ]; then
    TEMPLATE_SOURCE="$REPO_DIR"
  elif [ -d "${LEVEL0_SOURCE}/.specify/templates" ]; then
    TEMPLATE_SOURCE="$LEVEL0_SOURCE"
  else
    die "Keine Governance-Template-Quelle gefunden; nutze --template-source PATH"
  fi
}

snapshot_governance_templates() {
  local src="${TEMPLATE_SOURCE}/.specify/templates"
  [ -d "$src" ] || die "Template-Quelle nicht gefunden: $src"

  TEMPLATE_CACHE="$(mktemp -d)"
  trap 'rm -rf "$TEMPLATE_CACHE"' EXIT

  local name
  for name in spec-template.md plan-template.md tasks-template.md; do
    [ -f "$src/$name" ] || die "Template fehlt in Quelle: $src/$name"
    cp "$src/$name" "$TEMPLATE_CACHE/$name"
  done
}

run_or_show() {
  if $OPT_DRY_RUN; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

run_specify() {
  local repo="$1"
  local agent="$2"

  if $OPT_DRY_RUN; then
    printf '  [dry-run] specify init --here --force --integration %s\n' "$agent"
    return 0
  fi

  if ! (cd "$repo" && specify init --here --force --integration "$agent"); then
    log "  WARN: --integration fehlgeschlagen fuer ${agent}, versuche legacy --ai"
    (cd "$repo" && specify init --here --force --ignore-agent-tools --ai "$agent")
  fi
}

restore_constitution() {
  local repo="$1"
  local backup="$2"
  [ -f "$backup" ] || return 0
  run_or_show cp "$backup" "$repo/.specify/memory/constitution.md"
}

apply_governance_templates() {
  local repo="$1"
  local name

  for name in spec-template.md plan-template.md tasks-template.md; do
    run_or_show cp "$TEMPLATE_CACHE/$name" "$repo/.specify/templates/$name"
  done

  if ! $OPT_DRY_RUN; then
    perl -0pi -e 's#/speckit\.checklist#/speckit-checklist#g; s#/speckit\.plan#/speckit-plan#g; s#/speckit\.tasks#/speckit-tasks#g' \
      "$repo"/.specify/templates/*.md
  fi
}

ensure_opencode_allowlist() {
  local repo="$1"
  local gitignore="$repo/.gitignore"

  [ -d "$repo/.opencode/command" ] || return 0
  [ -f "$gitignore" ] || return 0

  if ! git -C "$repo" check-ignore -q .opencode/command/speckit.plan.md 2>/dev/null; then
    return 0
  fi

  if $OPT_DRY_RUN; then
    log "  [dry-run] .gitignore fuer .opencode/command/*.md oeffnen"
    return 0
  fi

  if grep -qF '!.opencode/command/*.md' "$gitignore"; then
    return 0
  fi

  cat >> "$gitignore" <<'EOF'

# opencode Spec-Kit Commands (nur commands/, NICHT root - root kann Cache enthalten)
!.opencode/
.opencode/*
!.opencode/command/
!.opencode/command/*.md
EOF
}

clean_generated_whitespace() {
  local repo="$1"
  local dir

  if $OPT_DRY_RUN; then
    log "  [dry-run] generierte Spec-Kit-Dateien von trailing whitespace bereinigen"
    return 0
  fi

  for dir in \
    "$repo/.opencode/command" \
    "$repo/.claude/skills"/speckit-* \
    "$repo/.agents/skills"/speckit-* \
    "$repo/.github/agents" \
    "$repo/.github/prompts" \
    "$repo/.specify/templates" \
    "$repo/.specify/scripts" \
    "$repo/.specify/extensions"; do
    if [ -d "$dir" ]; then
      find "$dir" -type f -exec perl -0pi -e 's/[ \t]+$//mg; s/\n+\z/\n/' {} +
    fi
  done

  if [ -f "$repo/.vscode/settings.json" ]; then
    perl -0pi -e 's/\n+\z/\n/' "$repo/.vscode/settings.json"
  fi
}

remove_legacy_gemini_integration() {
  local repo="$1"

  if $OPT_DRY_RUN; then
    log "  [dry-run] legacy .gemini/commands und gemini.manifest.json entfernen"
    return 0
  fi

  rm -rf -- "$repo/.gemini/commands"
  rm -f -- "$repo/.specify/integrations/gemini.manifest.json"
  if [ -d "$repo/.gemini" ] && [ -z "$(find "$repo/.gemini" -mindepth 1 -print -quit)" ]; then
    rmdir "$repo/.gemini"
  fi
}

commit_and_push() {
  local repo="$1"
  local branch

  if ! $OPT_COMMIT && ! $OPT_PUSH; then
    return 0
  fi

  if $OPT_DRY_RUN; then
    $OPT_COMMIT && log "  [dry-run] git add -A && git commit"
    $OPT_PUSH && log "  [dry-run] git push origin <branch>"
    return 0
  fi

  git -C "$repo" add -A
  git -C "$repo" diff --cached --check

  if $OPT_COMMIT && ! git -C "$repo" diff --cached --quiet; then
    git -C "$repo" commit -m "chore: update spec-kit integrations"
  fi

  if $OPT_PUSH; then
    branch="$(git -C "$repo" branch --show-current)"
    [ -n "$branch" ] || die "Kein aktueller Branch in $repo"
    git -C "$repo" push origin "$branch"
  fi
}

update_repo() {
  local repo="$1"
  local status
  local constitution_backup=""
  local agent

  log "## $repo"

  if ! $OPT_DRY_RUN && ! $OPT_ALLOW_DIRTY; then
    status="$(git -C "$repo" status --short)"
    [ -z "$status" ] || die "Repo hat lokale Aenderungen: $repo"
  fi

  if [ -f "$repo/.specify/memory/constitution.md" ] && ! $OPT_DRY_RUN; then
    constitution_backup="$(mktemp)"
    cp "$repo/.specify/memory/constitution.md" "$constitution_backup"
  fi

  for agent in "${AGENTS[@]}"; do
    run_specify "$repo" "$agent"
  done

  restore_constitution "$repo" "$constitution_backup"
  [ -n "$constitution_backup" ] && rm -f "$constitution_backup"

  apply_governance_templates "$repo"
  ensure_opencode_allowlist "$repo"
  remove_legacy_gemini_integration "$repo"
  clean_generated_whitespace "$repo"
  commit_and_push "$repo"
}

discover_repos
select_template_source
snapshot_governance_templates

log "Spec-Kit Update"
log "  Home            : $HOME_DIR"
log "  Template-Quelle : $TEMPLATE_SOURCE"
log "  Agenten         : ${AGENTS[*]}"
log "  Commit          : $OPT_COMMIT"
log "  Push            : $OPT_PUSH"
log "  Dry-run         : $OPT_DRY_RUN"
log ""

if [ "${#REPOS[@]}" -eq 0 ]; then
  die "Keine Spec-Kit-Repos gefunden"
fi

for repo in "${REPOS[@]}"; do
  update_repo "$repo"
done

log ""
log "Spec-Kit Update abgeschlossen."
