#!/usr/bin/env bash
# prepare-rl-se-checklist-selbstpruefung.sh
# Prepare repositories for later RL-SE / checklist self-assessment runs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/lib/secure-development-hardening.sh"

if [ ! -f "$LIB_FILE" ]; then
  echo "Fehler: Hilfsbibliothek nicht gefunden: $LIB_FILE" >&2
  echo "Error: helper library not found: $LIB_FILE" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$LIB_FILE"

HOME_DIR="${HOME}"
OPT_DRY_RUN=false
OPT_COMMIT=false
OPT_PUSH=false
OPT_ALLOW_DIRTY=false
OPT_BASELINE_ONLY=false
OPT_DISCOVER=false
OPT_REGISTRY="$HOME/.home-baseline/level2-repository-registry.json"
OPT_PRIMARY_LANGUAGE=""
OPT_REPOS=()

usage() {
  cat <<'EOF'
prepare-rl-se-checklist-selbstpruefung.sh — RL-SE-/Checklist-Selbstpruefung vorbereiten

Usage:
  bash scripts/prepare-rl-se-checklist-selbstpruefung.sh [options]

Options:
  --home-dir PATH             Home directory to scan (default: $HOME)
  --repo PATH                 Prepare one explicit repository; repeatable
  --registry PATH             Level-2 registry (default: ~/.home-baseline/level2-repository-registry.json)
  --discover                  Discover repositories below --home-dir instead of using the registry
  --baseline-only             Synchronize docs/secure-development only; do not create or update Lastenhefte
  --primary-language LANG     Optional language note; does not gate preparation
  --commit                    Commit changes in each changed repo
  --push                      Push current branch after commit/check; implies --commit
  --allow-dirty               Continue even if a repo already has local changes
  --dry-run                   Show targets and actions only
  -h, --help                  Show this help
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
    --primary-language)
      [ $# -ge 2 ] || die "--primary-language braucht einen Wert"
      OPT_PRIMARY_LANGUAGE="$2"
      shift 2
      ;;
    --registry)
      [ $# -ge 2 ] || die "--registry braucht einen Pfad"
      OPT_REGISTRY="$2"
      shift 2
      ;;
    --discover)
      OPT_DISCOVER=true
      shift
      ;;
    --baseline-only)
      OPT_BASELINE_ONLY=true
      shift
      ;;
    --repo)
      [ $# -ge 2 ] || die "--repo braucht einen Pfad"
      OPT_REPOS+=("$2")
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

REPOS=()

contains_repo() {
  local needle="$1"
  local item
  for item in "${REPOS[@]+"${REPOS[@]}"}"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

is_target_repo() {
  local repo="$1"
  [ -d "$repo/.git" ] || return 1
  [ -d "$repo/.specify" ] || [ -f "$repo/AGENTS.md" ] || [ -f "$repo/CLAUDE.md" ] || return 1
}

add_repo() {
  local repo="$1"
  [ -d "$repo" ] || return 0
  is_target_repo "$repo" || return 0
  contains_repo "$repo" && return 0
  REPOS+=("$repo")
}

discover_repos() {
  local workspace project
  REPOS=()

  if [ "${#OPT_REPOS[@]}" -gt 0 ]; then
    for project in "${OPT_REPOS[@]}"; do
      add_repo "$project"
    done
    return 0
  fi

  if ! $OPT_DISCOVER; then
    command -v jq >/dev/null 2>&1 || die "jq wird fuer die Registry benoetigt"
    [ -f "$OPT_REGISTRY" ] || die "Registry nicht gefunden: $OPT_REGISTRY (alternativ --discover nutzen)"
    while IFS= read -r project; do
      case "$project" in /*) add_repo "$project" ;; *) add_repo "$HOME_DIR/$project" ;; esac
    done < <(jq -r '.repositories[] | select(.level == 2 and .gsdbRequired == true) | .path' "$OPT_REGISTRY")
    return 0
  fi

  for workspace in "$HOME_DIR"/*; do
    [ -d "$workspace" ] || continue
    [ -d "$workspace/.git" ] || continue
    for project in "$workspace"/*; do
      [ -d "$project" ] || continue
      add_repo "$project"
    done
  done
}

find_selfcheck_template_file() {
  local repo_dir
  repo_dir="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

  for candidate in \
    "$SCRIPT_DIR/templates/rl-se-checklist-selbstpruefung-lastenheft.md" \
    "$repo_dir/scripts/templates/rl-se-checklist-selbstpruefung-lastenheft.md" \
    "$HOME/scripts/templates/rl-se-checklist-selbstpruefung-lastenheft.md" \
    "$HOME/home-baseline-source/scripts/templates/rl-se-checklist-selbstpruefung-lastenheft.md"; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

commit_and_push() {
  local repo="$1"
  local branch

  if ! $OPT_COMMIT && ! $OPT_PUSH; then
    return 0
  fi

  if $OPT_DRY_RUN; then
    if $OPT_BASELINE_ONLY; then
      $OPT_COMMIT && log "  [dry-run] git add docs/secure-development && git commit"
    else
      $OPT_COMMIT && log "  [dry-run] git add docs/secure-development Lastenheft_RL-SE-Checklist-Selbstpruefung.md Lastenheft_Abarbeitungsreihenfolge.md && git commit"
    fi
    $OPT_PUSH && log "  [dry-run] git push origin <branch>"
    return 0
  fi

  if $OPT_BASELINE_ONLY; then
    git -C "$repo" add docs/secure-development
  else
    git -C "$repo" add docs/secure-development Lastenheft_RL-SE-Checklist-Selbstpruefung.md Lastenheft_Abarbeitungsreihenfolge.md
  fi
  git -C "$repo" diff --cached --check

  if ! git -C "$repo" diff --cached --quiet; then
    if $OPT_BASELINE_ONLY; then
      git -C "$repo" commit -m "docs: update secure development baseline to 3.0.0"
    else
      git -C "$repo" commit -m "docs: prepare RL-SE checklist self-assessment"
    fi
  fi

  if $OPT_PUSH; then
    branch="$(git -C "$repo" branch --show-current)"
    [ -n "$branch" ] || die "Kein aktueller Branch in $repo"
    git -C "$repo" push origin "$branch"
  fi
}

prepare_repo() {
  local repo="$1"
  local status project_name language source_dir template_file target_docs intake_file dry_mode

  project_name="$(basename "$repo")"
  log "## $repo"

  if ! $OPT_DRY_RUN && ! $OPT_ALLOW_DIRTY; then
    status="$(git -C "$repo" status --short)"
    [ -z "$status" ] || die "Repo hat lokale Aenderungen: $repo"
  fi

  source_dir="$(sdh_find_source_dir "$SCRIPT_DIR" 2>/dev/null || true)"
  template_file="$(find_selfcheck_template_file 2>/dev/null || true)"
  if [ -z "$source_dir" ]; then
    die "docs/secure-development Quelle nicht gefunden"
  fi
  if [ -z "$template_file" ]; then
    die "RL-SE-/Checklist-Selbstpruefungs-Template nicht gefunden"
  fi

  language="$(sdh_detect_language "$repo" "$project_name" "$OPT_PRIMARY_LANGUAGE" 2>/dev/null || true)"
  [ -n "$language" ] || language="unklar / unknown"
  log "  Sprache / language: $language"

  target_docs="$repo/docs/secure-development"
  intake_file="$repo/Lastenheft_RL-SE-Checklist-Selbstpruefung.md"

  if $OPT_DRY_RUN; then
    sdh_sync_baseline "$source_dir" "$target_docs" 1
  else
    sdh_sync_baseline "$source_dir" "$target_docs" 0
  fi

  if $OPT_BASELINE_ONLY; then
    commit_and_push "$repo"
    return 0
  fi

  if [ -f "$intake_file" ]; then
    $OPT_DRY_RUN && log "  [dry-run] Lastenheft vorhanden, wird nicht ueberschrieben: $(basename "$intake_file")"
  else
    if $OPT_DRY_RUN; then
      log "  [dry-run] Lastenheft_RL-SE-Checklist-Selbstpruefung.md erzeugen"
    else
      sdh_render_template "$template_file" "$intake_file" "$project_name"
    fi
  fi

  dry_mode=0
  $OPT_DRY_RUN && dry_mode=1
  if sdh_update_order_file "$repo" "$dry_mode"; then
    $OPT_DRY_RUN && log "  [dry-run] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren"
  else
    $OPT_DRY_RUN && log "  [dry-run] Lastenheft_Abarbeitungsreihenfolge.md unveraendert"
  fi

  commit_and_push "$repo"
}

discover_repos

log "RL-SE-/Checklist-Selbstpruefung Vorbereitung"
log "  Home             : $HOME_DIR"
if [ "${#OPT_REPOS[@]}" -gt 0 ]; then
  log "  Repos            : ${#OPT_REPOS[@]} explizit"
fi
log "  Primaersprache   : ${OPT_PRIMARY_LANGUAGE:-auto/optional}"
log "  Registry         : $OPT_REGISTRY"
log "  Discover         : $OPT_DISCOVER"
log "  Baseline only    : $OPT_BASELINE_ONLY"
log "  Commit           : $OPT_COMMIT"
log "  Push             : $OPT_PUSH"
log "  Dry-run          : $OPT_DRY_RUN"
log ""

if [ "${#REPOS[@]}" -eq 0 ]; then
  die "Keine Ziel-Repositories gefunden"
fi

for repo in "${REPOS[@]}"; do
  prepare_repo "$repo"
done

log ""
log "RL-SE-/Checklist-Selbstpruefung Vorbereitung abgeschlossen."
