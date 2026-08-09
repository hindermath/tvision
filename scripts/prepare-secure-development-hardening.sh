#!/usr/bin/env bash
# prepare-secure-development-hardening.sh
# Prepare MSL-based Level-2 repositories for later secure-development hardening runs.

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
OPT_PRIMARY_LANGUAGE=""
OPT_REPOS=()

usage() {
  cat <<'EOF'
prepare-secure-development-hardening.sh — Secure-Development-Hardening vorbereiten

Usage:
  bash scripts/prepare-secure-development-hardening.sh [options]

Options:
  --home-dir PATH             Home directory to scan (default: $HOME)
  --repo PATH                 Prepare one explicit Level-2 repo; repeatable
  --primary-language LANG     Override language detection for all discovered repos
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

is_level2_repo() {
  local repo="$1"
  [ -d "$repo/.git" ] || return 1
  [ -d "$repo/.specify" ] || [ -f "$repo/AGENTS.md" ] || [ -f "$repo/CLAUDE.md" ] || return 1
}

add_repo() {
  local repo="$1"
  [ -d "$repo" ] || return 0
  is_level2_repo "$repo" || return 0
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

  for workspace in "$HOME_DIR"/*; do
    [ -d "$workspace" ] || continue
    [ -d "$workspace/.git" ] || continue
    for project in "$workspace"/*; do
      [ -d "$project" ] || continue
      add_repo "$project"
    done
  done
}

commit_and_push() {
  local repo="$1"
  local branch

  if ! $OPT_COMMIT && ! $OPT_PUSH; then
    return 0
  fi

  if $OPT_DRY_RUN; then
    $OPT_COMMIT && log "  [dry-run] git add docs/secure-development Lastenheft_Secure-Development-Hardening.md Lastenheft_Abarbeitungsreihenfolge.md && git commit"
    $OPT_PUSH && log "  [dry-run] git push origin <branch>"
    return 0
  fi

  git -C "$repo" add docs/secure-development Lastenheft_Secure-Development-Hardening.md Lastenheft_Abarbeitungsreihenfolge.md
  git -C "$repo" diff --cached --check

  if ! git -C "$repo" diff --cached --quiet; then
    git -C "$repo" commit -m "docs: prepare secure development hardening"
  fi

  if $OPT_PUSH; then
    branch="$(git -C "$repo" branch --show-current)"
    [ -n "$branch" ] || die "Kein aktueller Branch in $repo"
    git -C "$repo" push origin "$branch"
  fi
}

prepare_repo() {
  local repo="$1"
  local status project_name dry force

  project_name="$(basename "$repo")"
  log "## $repo"

  if ! $OPT_DRY_RUN && ! $OPT_ALLOW_DIRTY; then
    status="$(git -C "$repo" status --short)"
    [ -z "$status" ] || die "Repo hat lokale Aenderungen: $repo"
  fi

  dry=0
  force=0
  $OPT_DRY_RUN && dry=1

  if ! sdh_prepare_repo "$repo" "$project_name" "$OPT_PRIMARY_LANGUAGE" "$dry" "$force" "$SCRIPT_DIR"; then
    die "$SDH_PREPARE_REASON"
  fi

  case "$SDH_PREPARE_RESULT" in
    prepared)
      log "  vorbereitet: $SDH_PREPARE_REASON"
      commit_and_push "$repo"
      ;;
    skipped)
      log "  uebersprungen: $SDH_PREPARE_REASON"
      ;;
    *)
      log "  Status: $SDH_PREPARE_RESULT $SDH_PREPARE_REASON"
      ;;
  esac
}

discover_repos

log "Secure-Development-Hardening Vorbereitung"
log "  Home             : $HOME_DIR"
if [ "${#OPT_REPOS[@]}" -gt 0 ]; then
  log "  Repos            : ${#OPT_REPOS[@]} explizit"
fi
log "  Primaersprache   : ${OPT_PRIMARY_LANGUAGE:-auto}"
log "  Commit           : $OPT_COMMIT"
log "  Push             : $OPT_PUSH"
log "  Dry-run          : $OPT_DRY_RUN"
log ""

if [ "${#REPOS[@]}" -eq 0 ]; then
  die "Keine Level-2-Repos gefunden"
fi

for repo in "${REPOS[@]}"; do
  prepare_repo "$repo"
done

log ""
log "Secure-Development-Hardening Vorbereitung abgeschlossen."
