#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGEJO_LIB="$SCRIPT_DIR/lib/hg-forgejo.sh"
if [ -f "$FORGEJO_LIB" ]; then
  # shellcheck source=scripts/lib/hg-forgejo.sh
  source "$FORGEJO_LIB"
fi

BOX_WIDTH=66

EXIT_CODE=0
DRY_RUN=0
FORCE=0
YES=0
BACKUP=0
KEEP_REMOTE=0
RECURSIVE=0
WORKSPACE_NAME=""
WORKSPACE_DIR=""
HOME_DIR=""
NORMALIZED_NAME=""
README_PATH=""
GITIGNORE_PATH=""
GITCONFIG_PATH=""
GITCONFIG_D=""
INC_FILE=""

declare -a LEVEL2_PROJECTS=()
declare -a RESULTS=()

usage() {
  cat <<'EOF'
Verwendung / Usage:
  teardown-workspace.sh <WorkspaceName> [OPTIONEN / OPTIONS]

Optionen / Options:
  --backup        Erstellt vor der Löschung ein Backup-Archiv / Create backup archive before deletion
  --keep-remote   Überspringt das Remote-Repository / Skip remote repository deletion
  --recursive     Verarbeitet Level-2-Repositories vor dem Workspace / Process Level-2 repositories first
  --force         Überspringt Sicherheitsprüfungen / Skip safety checks
  --yes           Überspringt die Rückfrage / Skip confirmation prompt
  --dry-run       Zeigt alle Aktionen ohne Ausführung / Show all actions without executing
  --help          Zeigt diese Hilfe / Show this help
EOF
}

set_warning_exit() {
  if [ "$EXIT_CODE" -lt 1 ]; then
    EXIT_CODE=1
  fi
}

add_result() {
  RESULTS+=("$1|$2")
}

box_line() {
  printf '║ %-66.66s ║\n' "$1"
}

print_box() {
  local title="$1"
  shift

  echo "╔════════════════════════════════════════════════════════════════════╗"
  box_line "  $title"
  echo "╠════════════════════════════════════════════════════════════════════╣"

  while [ "$#" -gt 0 ]; do
    box_line "$1"
    shift
  done

  echo "╚════════════════════════════════════════════════════════════════════╝"
}

normalize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'
}

resolve_home_dir() {
  local candidate=""

  if [ -n "${HOME:-}" ]; then
    candidate="$HOME"
  elif [ -n "${USERPROFILE:-}" ]; then
    candidate="$USERPROFILE"
  else
    candidate="$(cd ~ && pwd)"
  fi

  (
    cd "$candidate" >/dev/null 2>&1 && pwd
  )
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --backup)
        BACKUP=1
        ;;
      --keep-remote)
        KEEP_REMOTE=1
        ;;
      --recursive)
        RECURSIVE=1
        ;;
      --force)
        FORCE=1
        ;;
      --yes)
        YES=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --)
        shift
        if [ $# -gt 0 ] && [ -z "$WORKSPACE_NAME" ]; then WORKSPACE_NAME="$1"; shift; fi
        continue
        ;;
      --*)
        echo "Fehler: Unbekannte Option '$1' / Error: Unknown option '$1'" >&2
        exit 2
        ;;
      *)
        if [ -n "$WORKSPACE_NAME" ]; then
          echo "Fehler: Mehr als ein Workspace-Name angegeben / Error: More than one workspace name provided" >&2
          exit 2
        fi
        WORKSPACE_NAME="$1"
        ;;
    esac
    shift
  done

  if [ -z "$WORKSPACE_NAME" ]; then
    usage >&2
    exit 2
  fi
}

validate_context() {
  HOME_DIR="$(resolve_home_dir)"
  WORKSPACE_DIR="$HOME_DIR/$WORKSPACE_NAME"
  NORMALIZED_NAME="$(normalize_name "$WORKSPACE_NAME")"
  README_PATH="$HOME_DIR/README.md"
  GITIGNORE_PATH="$HOME_DIR/.gitignore"
  GITCONFIG_PATH="$HOME_DIR/.gitconfig"
  GITCONFIG_D="$HOME_DIR/.gitconfig.d"
  INC_FILE="$GITCONFIG_D/$NORMALIZED_NAME.inc"

  if [ "$WORKSPACE_NAME" = "home-baseline" ]; then
    echo "Fehler: 'home-baseline' ist geschützt / Error: 'home-baseline' is protected" >&2
    exit 2
  fi

  if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "Fehler: Workspace '$WORKSPACE_DIR' nicht gefunden / Error: Workspace '$WORKSPACE_DIR' not found" >&2
    exit 2
  fi
}

discover_level2_projects() {
  local gitdir=""

  LEVEL2_PROJECTS=()
  while IFS= read -r gitdir; do
    LEVEL2_PROJECTS+=("$(dirname "$gitdir")")
  done < <(find "$WORKSPACE_DIR" -mindepth 2 -maxdepth 2 -name ".git" -type d 2>/dev/null | sort)
}

remote_platform_for_dir() {
  local dir="$1"
  local remote_url=""
  local configured_platform=""

  remote_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
  configured_platform="$(git -C "$dir" config --local --get home-baseline.remote-platform 2>/dev/null || true)"
  if [ -z "$remote_url" ]; then
    echo "kein Remote / no remote"
  elif [ "$configured_platform" = "forgejo" ] || [ "$configured_platform" = "codeberg" ]; then
    echo "$configured_platform"
  elif echo "$remote_url" | grep -qi 'github\.com'; then
    echo "GitHub"
  elif echo "$remote_url" | grep -qi 'gitlab\.com'; then
    echo "GitLab"
  else
    echo "anderes Remote / other remote"
  fi
}

build_preamble() {
  local title="teardown-workspace - Workspace-Entfernung / Workspace Removal"
  local line=""
  local project=""
  local project_name=""
  local remote_desc=""

  if [ "$DRY_RUN" -eq 1 ]; then
    title="[DRY-RUN] $title"
  fi

  box_line_buffer=()
  box_line_buffer+=("  Workspace:   $WORKSPACE_NAME")
  box_line_buffer+=("  Pfad / Path: $WORKSPACE_DIR")
  box_line_buffer+=("")
  box_line_buffer+=("  Geplante Aktionen / Planned actions:")

  if [ "${#LEVEL2_PROJECTS[@]}" -gt 0 ]; then
    for project in "${LEVEL2_PROJECTS[@]}"; do
      project_name="$(basename "$project")"
      remote_desc="$(remote_platform_for_dir "$project")"
      line="    L2 $project_name: Sicherheitsprüfung / Safety"
      if [ "$FORCE" -eq 1 ]; then
        line="    L2 $project_name: --force überspringt Safety / --force skips safety"
      fi
      box_line_buffer+=("$line")
      if [ "$BACKUP" -eq 1 ]; then
        box_line_buffer+=("      Backup / backup: $(basename "$(planned_backup_path "$project_name")")")
      fi
      box_line_buffer+=("      Remote / remote: $remote_desc")
      box_line_buffer+=("      Lokal löschen / delete local directory")
    done
  fi

  if [ "$BACKUP" -eq 1 ]; then
    box_line_buffer+=("    1. Backup / backup: $(basename "$(planned_backup_path "$WORKSPACE_NAME")")")
  fi

  if [ "$FORCE" -eq 1 ]; then
    box_line_buffer+=("    2. --force: Sicherheitsprüfungen übersprungen / safety checks skipped")
  else
    box_line_buffer+=("    2. Sicherheitsprüfung / safety check")
  fi

  box_line_buffer+=("    3. Remote / remote: $(remote_platform_for_dir "$WORKSPACE_DIR")")
  box_line_buffer+=("    4. Verzeichnis löschen / delete directory")
  box_line_buffer+=("    5. Artefakte bereinigen / clean up artifacts")
  box_line_buffer+=("       - ~/README.md")
  box_line_buffer+=("       - ~/.gitignore")
  box_line_buffer+=("       - ~/.gitconfig")
  box_line_buffer+=("       - ~/.gitconfig.d/$NORMALIZED_NAME.inc")

  print_box "$title" "${box_line_buffer[@]}"
}

planned_backup_path() {
  local target_name="$1"
  printf '%s/%s-backup-%s.tar.gz' "$HOME_DIR" "$target_name" "$(date +%Y-%m-%d)"
}

confirm_or_abort() {
  local answer=""

  if [ "$DRY_RUN" -eq 1 ] || [ "$YES" -eq 1 ]; then
    return 0
  fi

  printf 'Fortfahren? / Proceed? [y/N]: '
  read -r answer
  case "$answer" in
    y|Y)
      ;;
    *)
      echo "Abgebrochen / Aborted."
      exit 1
      ;;
  esac
}

check_safety() {
  local label="$1"
  local dir="$2"

  if [ "$FORCE" -eq 1 ]; then
    add_result "skip" "Sicherheitsprüfung übersprungen / Safety check skipped: $label"
    return 0
  fi

  if [ ! -d "$dir/.git" ]; then
    add_result "skip" "Kein Git-Repository für Sicherheitsprüfung / No git repository for safety check: $label"
    return 0
  fi

  if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
    add_result "fail" "Uncommittete Änderungen erkannt / Uncommitted changes detected: $label"
    set_warning_exit
    return 1
  fi

  if git -C "$dir" rev-parse @{u} >/dev/null 2>&1; then
    if [ -n "$(git -C "$dir" log @{u}..HEAD --oneline 2>/dev/null)" ]; then
      add_result "fail" "Ungepushte Commits erkannt / Unpushed commits detected: $label"
      set_warning_exit
      return 1
    fi
  fi

  add_result "done" "Sicherheitsprüfung bestanden / Safety check passed: $label"
}

unique_backup_path() {
  local target_name="$1"
  local base=""
  local archive=""
  local index=1

  base="$HOME_DIR/$target_name-backup-$(date +%Y-%m-%d)"
  archive="${base}.tar.gz"
  while [ -e "$archive" ]; do
    archive="${base}-${index}.tar.gz"
    index=$((index + 1))
  done

  printf '%s\n' "$archive"
}

create_backup() {
  local label="$1"
  local dir="$2"
  local target_name="$3"
  local archive=""

  if [ "$BACKUP" -ne 1 ]; then
    return 0
  fi

  if ! command -v tar >/dev/null 2>&1; then
    add_result "fail" "Backup nicht erstellt, tar fehlt / Backup not created, tar missing: $label"
    set_warning_exit
    return 0
  fi

  archive="$(unique_backup_path "$target_name")"
  if tar czf "$archive" -C "$(dirname "$dir")" "$(basename "$dir")" >/dev/null 2>&1; then
    add_result "done" "Backup erstellt / Backup created: $(basename "$archive")"
  else
    add_result "fail" "Backup fehlgeschlagen / Backup failed: $label"
    set_warning_exit
  fi
}

extract_owner_repo() {
  local remote_url="$1"
  local host="$2"

  echo "$remote_url" | sed -E "s#.*${host}[:/]##" | sed 's/\.git$//'
}

delete_remote_repo() {
  local label="$1"
  local dir="$2"
  local remote_url=""
  local owner_repo=""
  local configured_platform=""
  local forgejo_base_url=""
  local forgejo_owner=""
  local forgejo_repository=""

  if [ "$KEEP_REMOTE" -eq 1 ]; then
    add_result "skip" "Remote bewusst behalten / Remote intentionally kept: $label"
    return 0
  fi

  if [ ! -d "$dir/.git" ]; then
    add_result "skip" "Kein Git-Repository, Remote-Schritt übersprungen / No git repository, remote step skipped: $label"
    return 0
  fi

  remote_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
  if [ -z "$remote_url" ]; then
    add_result "skip" "Kein Remote konfiguriert / No remote configured: $label"
    return 0
  fi

  configured_platform="$(git -C "$dir" config --local --get home-baseline.remote-platform 2>/dev/null || true)"
  if [ "$configured_platform" = "forgejo" ] || [ "$configured_platform" = "codeberg" ]; then
    if [ ! -f "$FORGEJO_LIB" ]; then
      add_result "fail" "Forgejo-Bibliothek fehlt, Remote-Löschung abgebrochen / Forgejo library missing, remote deletion aborted: $label"
      set_warning_exit
      return 1
    fi
    forgejo_base_url="$(git -C "$dir" config --local --get home-baseline.remote-base-url 2>/dev/null || true)"
    forgejo_owner="$(git -C "$dir" config --local --get home-baseline.remote-owner 2>/dev/null || true)"
    forgejo_repository="$(git -C "$dir" config --local --get home-baseline.remote-repository 2>/dev/null || true)"
    if [ -z "$forgejo_base_url" ] || [ -z "$forgejo_owner" ] || [ -z "$forgejo_repository" ]; then
      add_result "fail" "Forgejo-Metadaten fehlen, bitte --keep-remote verwenden / Forgejo metadata missing, use --keep-remote: $label"
      set_warning_exit
      return 1
    fi
    if hb_forgejo_delete_repository "$forgejo_base_url" "$forgejo_owner" "$forgejo_repository"; then
      add_result "done" "$configured_platform-Remote gelöscht / remote deleted: $forgejo_owner/$forgejo_repository"
      return 0
    fi
    add_result "fail" "$configured_platform-Remote konnte nicht gelöscht werden / remote could not be deleted: $forgejo_owner/$forgejo_repository"
    set_warning_exit
    return 1
  fi

  if echo "$remote_url" | grep -qi 'github\.com'; then
    if ! command -v gh >/dev/null 2>&1; then
      add_result "fail" "gh fehlt, Remote-Löschung abgebrochen / gh missing, remote deletion aborted: $label"
      set_warning_exit
      return 1
    fi
    owner_repo="$(extract_owner_repo "$remote_url" 'github\.com')"
    if gh repo delete "$owner_repo" --yes >/dev/null 2>&1; then
      add_result "done" "Remote-Repo gelöscht / Remote repo deleted: $owner_repo"
      return 0
    fi
    add_result "fail" "GitHub-Remote konnte nicht gelöscht werden / GitHub remote could not be deleted: $owner_repo"
    set_warning_exit
    return 1
  fi

  if echo "$remote_url" | grep -qi 'gitlab\.com'; then
    owner_repo="$(extract_owner_repo "$remote_url" 'gitlab\.com')"
    if ! command -v glab >/dev/null 2>&1; then
      add_result "skip" "glab fehlt, GitLab-Remote übersprungen / glab missing, GitLab remote skipped: $owner_repo"
      set_warning_exit
      return 0
    fi
    if glab repo delete "$owner_repo" --yes >/dev/null 2>&1; then
      add_result "done" "GitLab-Remote gelöscht / GitLab remote deleted: $owner_repo"
      return 0
    fi
    add_result "fail" "GitLab-Remote konnte nicht gelöscht werden / GitLab remote could not be deleted: $owner_repo"
    set_warning_exit
    return 1
  fi

  add_result "fail" "Nicht unterstütztes Remote, bitte --keep-remote verwenden / Unsupported remote, use --keep-remote: $label"
  set_warning_exit
  return 1
}

delete_local_directory() {
  local label="$1"
  local dir="$2"

  rm -rf "$dir"
  add_result "done" "Verzeichnis gelöscht / Directory deleted: $label"
}

rewrite_without_match() {
  local source="$1"
  local tmp_file="$2"
  local awk_script="$3"
  local changed_message="$4"
  local missing_message="$5"

  if [ ! -f "$source" ]; then
    add_result "skip" "$missing_message"
    return 0
  fi

  awk "$awk_script" "$source" > "$tmp_file"
  if cmp -s "$source" "$tmp_file"; then
    rm -f "$tmp_file"
    add_result "skip" "$missing_message"
    return 0
  fi

  mv "$tmp_file" "$source"
  add_result "done" "$changed_message"
}

cleanup_readme() {
  local tmp_file="$README_PATH.tmp.$$"

  if [ ! -f "$README_PATH" ]; then
    add_result "skip" "README.md fehlt / README.md missing"
    return 0
  fi

  awk -v workspace="$WORKSPACE_NAME" 'index($0, "~/" workspace "/") == 0 { print }' "$README_PATH" > "$tmp_file"
  if cmp -s "$README_PATH" "$tmp_file"; then
    rm -f "$tmp_file"
    add_result "skip" "README.md-Eintrag nicht vorhanden / README.md entry not present"
    return 0
  fi

  mv "$tmp_file" "$README_PATH"
  add_result "done" "README.md bereinigt / README.md cleaned up"
}

cleanup_gitignore() {
  local tmp_file="$GITIGNORE_PATH.tmp.$$"

  if [ ! -f "$GITIGNORE_PATH" ]; then
    add_result "skip" ".gitignore fehlt / .gitignore missing"
    return 0
  fi

  awk -v entry="$WORKSPACE_NAME/" '$0 != entry { print }' "$GITIGNORE_PATH" > "$tmp_file"
  if cmp -s "$GITIGNORE_PATH" "$tmp_file"; then
    rm -f "$tmp_file"
    add_result "skip" ".gitignore-Eintrag nicht vorhanden / .gitignore entry not present"
    return 0
  fi

  mv "$tmp_file" "$GITIGNORE_PATH"
  add_result "done" ".gitignore bereinigt / .gitignore cleaned up"
}

cleanup_gitconfig() {
  local tmp_file="$GITCONFIG_PATH.tmp.$$"
  local tilde_header="[includeIf \"gitdir:~/$WORKSPACE_NAME/\"]"
  local expanded_header="[includeIf \"gitdir:$WORKSPACE_DIR/\"]"

  if [ ! -f "$GITCONFIG_PATH" ]; then
    add_result "skip" ".gitconfig fehlt / .gitconfig missing"
    return 0
  fi

  awk -v header1="$tilde_header" -v header2="$expanded_header" '
    $0 == header1 || $0 == header2 { skip = 1; removed = 1; next }
    skip && /^[[:space:]]/ { next }
    { skip = 0; print }
  ' "$GITCONFIG_PATH" > "$tmp_file"

  if cmp -s "$GITCONFIG_PATH" "$tmp_file"; then
    rm -f "$tmp_file"
    add_result "skip" ".gitconfig includeIf-Block nicht vorhanden / .gitconfig includeIf block not present"
    return 0
  fi

  mv "$tmp_file" "$GITCONFIG_PATH"
  add_result "done" ".gitconfig bereinigt / .gitconfig cleaned up"
}

cleanup_inc_file() {
  if [ ! -d "$GITCONFIG_D" ]; then
    add_result "skip" "~/.gitconfig.d fehlt / ~/.gitconfig.d missing"
    return 0
  fi

  if [ ! -f "$INC_FILE" ]; then
    add_result "skip" ".inc-Datei nicht vorhanden / .inc file not present: $NORMALIZED_NAME.inc"
    return 0
  fi

  rm -f "$INC_FILE"
  add_result "done" ".inc-Datei gelöscht / .inc file deleted: $NORMALIZED_NAME.inc"
}

commit_artifacts() {
  local staged=0
  local subject="chore: teardown $WORKSPACE_NAME - Artefakte bereinigt / artifacts cleaned up"

  if ! git -C "$HOME_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    add_result "skip" "Artefakt-Commit übersprungen, ~/ ist kein Git-Repo / Artifact commit skipped, ~/ is not a git repo"
    set_warning_exit
    return 0
  fi

  if [ -f "$README_PATH" ]; then
    git -C "$HOME_DIR" add --update -- README.md >/dev/null 2>&1 || true
  fi
  if [ -f "$GITIGNORE_PATH" ]; then
    git -C "$HOME_DIR" add --update -- .gitignore >/dev/null 2>&1 || true
  fi

  if ! git -C "$HOME_DIR" diff --cached --quiet -- README.md .gitignore >/dev/null 2>&1; then
    staged=1
  fi

  if [ "$staged" -eq 0 ]; then
    add_result "skip" "Kein Artefakt-Commit nötig / No artifact commit needed"
    return 0
  fi

  if git -C "$HOME_DIR" commit -m "$subject" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" >/dev/null 2>&1; then
    add_result "done" "Artefakte committed / Artifacts committed"
  else
    add_result "fail" "Artefakt-Commit fehlgeschlagen / Artifact commit failed"
    set_warning_exit
  fi
}

cleanup_workspace_artifacts() {
  cleanup_readme
  cleanup_gitignore
  cleanup_gitconfig
  cleanup_inc_file
  commit_artifacts
}

teardown_target() {
  local label="$1"
  local dir="$2"
  local backup_name="$3"
  local include_artifacts="$4"

  create_backup "$label" "$dir" "$backup_name"

  if ! check_safety "$label" "$dir"; then
    return 1
  fi

  if ! delete_remote_repo "$label" "$dir"; then
    return 1
  fi

  delete_local_directory "$label" "$dir"

  if [ "$include_artifacts" -eq 1 ]; then
    cleanup_workspace_artifacts
  fi
}

print_level2_abort() {
  local lines=()
  local project=""

  lines+=("Level-2-Repositories erkannt / Level-2 repositories detected:")
  for project in "${LEVEL2_PROJECTS[@]}"; do
    lines+=("  - $(basename "$project")")
  done
  lines+=("")
  lines+=("--recursive erforderlich / --recursive required")

  print_box "Teardown abgebrochen / Teardown aborted" "${lines[@]}"
}

print_completion_report() {
  local lines=()
  local entry=""
  local status=""
  local message=""
  local symbol=""

  for entry in "${RESULTS[@]}"; do
    status="${entry%%|*}"
    message="${entry#*|}"
    case "$status" in
      done)
        symbol="✓"
        ;;
      skip)
        symbol="→"
        ;;
      fail)
        symbol="✗"
        ;;
      *)
        symbol="•"
        ;;
    esac
    lines+=("  $symbol $message")
  done

  print_box "Teardown abgeschlossen / Teardown complete" "${lines[@]}"
}

main() {
  parse_args "$@"
  validate_context
  discover_level2_projects

  if [ "${#LEVEL2_PROJECTS[@]}" -gt 0 ] && [ "$RECURSIVE" -ne 1 ]; then
    print_level2_abort
    exit 1
  fi

  build_preamble

  if [ "$DRY_RUN" -eq 1 ]; then
    exit 0
  fi

  confirm_or_abort

  if [ "${#LEVEL2_PROJECTS[@]}" -gt 0 ]; then
    local project=""
    local project_name=""
    for project in "${LEVEL2_PROJECTS[@]}"; do
      project_name="$(basename "$project")"
      if ! teardown_target "Level-2 $project_name" "$project" "$project_name" 0; then
        print_completion_report
        exit "$EXIT_CODE"
      fi
    done
  fi

  if ! teardown_target "Workspace $WORKSPACE_NAME" "$WORKSPACE_DIR" "$WORKSPACE_NAME" 1; then
    print_completion_report
    exit "$EXIT_CODE"
  fi

  print_completion_report
  exit "$EXIT_CODE"
}

main "$@"
