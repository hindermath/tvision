#!/usr/bin/env bash
# Propagate the canonical agentic toolchain maintenance package to Level-1/2 repos.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOME_DIR="$(cd -- ~ && pwd)"
REGISTRY="${HOME_DIR}/.home-baseline/level2-repository-registry.json"
MANIFEST="${SOURCE_ROOT}/scripts/config/agentic-toolchain-maintenance-files.json"

DRY_RUN=0
CHECK_ONLY=0
ONLY_LEVEL1=0
ONLY_LEVEL2=0
VERBOSE=0
TARGET_REPO=""

REPOS_TOTAL=0
REPOS_CURRENT=0
REPOS_CHANGED=0
REPOS_DRIFTED=0
REPOS_SKIPPED=0
FILES_CHANGED=0
RAW_DIFFERENCES=0
FILES_EXCEPTED=0

usage() {
  cat <<USAGE
Verwendung / Usage: $(basename -- "$0") [OPTIONEN]

  --dry-run          Aenderungen nur anzeigen / Preview changes only
  --check-only       Drift pruefen; Exit 1 bei Abweichungen / Check drift; exit 1 on differences
  --only-level1      Nur Level-1-Repositories / Level-1 repositories only
  --only-level2      Nur Level-2-Repositories / Level-2 repositories only
  --repo PFAD        Nur ein Repository pruefen / Check one repository only
  --home-dir PFAD    Alternatives Home-Verzeichnis / Alternative home directory
  --registry PFAD    Alternative Level-2-Registry / Alternative Level-2 registry
  --manifest PFAD    Alternative Dateiliste / Alternative file manifest
  --verbose, -v      Unveraenderte Dateien anzeigen / Show unchanged files

Kanonische Quelle / Canonical source: ${SOURCE_ROOT}
USAGE
}

while [ $# -gt 0 ]; do
  case "${1:-}" in
    --dry-run) DRY_RUN=1 ;;
    --check-only) CHECK_ONLY=1 ;;
    --only-level1) ONLY_LEVEL1=1 ;;
    --only-level2) ONLY_LEVEL2=1 ;;
    --repo) TARGET_REPO="${2:?--repo benoetigt einen Pfad / requires a path}"; shift ;;
    --home-dir) HOME_DIR="$(cd -- "${2:?--home-dir benoetigt einen Pfad / requires a path}" && pwd)"; shift ;;
    --registry) REGISTRY="${2:?--registry benoetigt einen Pfad / requires a path}"; shift ;;
    --manifest) MANIFEST="${2:?--manifest benoetigt einen Pfad / requires a path}"; shift ;;
    --verbose|-v) VERBOSE=1 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    --*) echo "Fehler / Error: Unbekannte Option / Unknown option: $1" >&2; exit 2 ;;
    *) echo "Fehler / Error: Unerwartetes Argument / Unexpected argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$ONLY_LEVEL1" -eq 1 ] && [ "$ONLY_LEVEL2" -eq 1 ]; then
  echo "Fehler / Error: --only-level1 und / and --only-level2 sind nicht kombinierbar / cannot be combined." >&2
  exit 2
fi
if [ "$DRY_RUN" -eq 1 ] && [ "$CHECK_ONLY" -eq 1 ]; then
  echo "Fehler / Error: --dry-run und / and --check-only sind nicht kombinierbar / cannot be combined." >&2
  exit 2
fi

for tool in python3 git cmp cp; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Fehler / Error: $tool erforderlich / required." >&2
    exit 2
  }
done
if [ ! -f "$MANIFEST" ]; then
  echo "Fehler / Error: Manifest nicht gefunden / not found: $MANIFEST" >&2
  exit 2
fi
if [ -z "$TARGET_REPO" ] && [ ! -f "$REGISTRY" ]; then
  echo "Fehler / Error: Level-2-Registry nicht gefunden / not found: $REGISTRY" >&2
  exit 2
fi

info() { echo "-> $*"; }
ok() { echo "OK: $*"; }
warn() { echo "WARN: $*" >&2; }

MANAGED_PATHS=()
MANAGED_EXECUTABLE=()
while IFS=$'\t' read -r relative_path executable; do
  [ -n "$relative_path" ] || continue
  MANAGED_PATHS+=("$relative_path")
  MANAGED_EXECUTABLE+=("$executable")
done < <(python3 - "$MANIFEST" <<'PYEOF'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
data = json.loads(manifest_path.read_text(encoding="utf-8"))
if data.get("schemaVersion") != 1 or not isinstance(data.get("files"), list):
    raise SystemExit("Unsupported propagation manifest schema")
seen = set()
for entry in data["files"]:
    path = entry.get("path") if isinstance(entry, dict) else None
    if not isinstance(path, str) or not path or pathlib.PurePosixPath(path).is_absolute():
        raise SystemExit(f"Invalid managed path: {path!r}")
    parts = pathlib.PurePosixPath(path).parts
    if ".." in parts or path in seen:
        raise SystemExit(f"Unsafe or duplicate managed path: {path}")
    seen.add(path)
    print(f"{path}\t{'true' if entry.get('executable') else 'false'}")
PYEOF
)

if [ "${#MANAGED_PATHS[@]}" -eq 0 ]; then
  echo "Fehler / Error: Manifest enthaelt keine Dateien / contains no files." >&2
  exit 2
fi

for index in "${!MANAGED_PATHS[@]}"; do
  source_file="${SOURCE_ROOT}/${MANAGED_PATHS[$index]}"
  if [ ! -f "$source_file" ]; then
    echo "Fehler / Error: Kanonische Datei fehlt / canonical file missing: $source_file" >&2
    exit 2
  fi
done

EXCEPTION_REPOSITORIES=()
EXCEPTION_PATHS=()
EXCEPTION_REASONS=()
if ! EXCEPTION_ROWS="$(python3 - "$MANIFEST" <<'PYEOF'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
data = json.loads(manifest_path.read_text(encoding="utf-8"))
managed = {
    entry["path"]
    for entry in data["files"]
    if isinstance(entry, dict) and isinstance(entry.get("path"), str)
}
seen = set()
for entry in data.get("exceptions", []):
    if not isinstance(entry, dict):
        raise SystemExit("Invalid propagation exception")
    repository = entry.get("repositoryPath")
    path = entry.get("path")
    reason = entry.get("reason")
    for label, value in (
        ("repositoryPath", repository),
        ("path", path),
        ("reason", reason),
    ):
        if (
            not isinstance(value, str)
            or not value
            or "\t" in value
            or "\n" in value
            or "\r" in value
        ):
            raise SystemExit(f"Invalid propagation exception {label}: {value!r}")
    repository_parts = pathlib.PurePosixPath(repository).parts
    if (
        pathlib.PurePosixPath(repository).is_absolute()
        or ".." in repository_parts
        or repository in (".", "")
    ):
        raise SystemExit(f"Unsafe propagation exception repository: {repository}")
    if path not in managed:
        raise SystemExit(f"Exception path is not managed: {path}")
    key = (repository, path)
    if key in seen:
        raise SystemExit(
            f"Duplicate propagation exception: {repository} / {path}"
        )
    seen.add(key)
    print(f"{repository}\t{path}\t{reason}")
PYEOF
)"; then
  fail "Ausnahmen im Manifest sind ungueltig / Manifest exceptions are invalid."
fi
while IFS=$'\t' read -r repository_path relative_path reason; do
  [ -n "$repository_path" ] || continue
  EXCEPTION_REPOSITORIES+=("$repository_path")
  EXCEPTION_PATHS+=("$relative_path")
  EXCEPTION_REASONS+=("$reason")
done <<EOF
${EXCEPTION_ROWS}
EOF

exception_reason() {
  local repo="$1" relative_path="$2"
  local repository_relative index
  case "$repo" in
    "${HOME_DIR}/"*) repository_relative="${repo#"${HOME_DIR}/"}" ;;
    *) return 1 ;;
  esac
  [ -n "${EXCEPTION_REPOSITORIES[*]-}" ] || return 1
  for index in "${!EXCEPTION_REPOSITORIES[@]}"; do
    if [ "${EXCEPTION_REPOSITORIES[$index]}" = "$repository_relative" ] &&
       [ "${EXCEPTION_PATHS[$index]}" = "$relative_path" ]; then
      printf '%s' "${EXCEPTION_REASONS[$index]}"
      return 0
    fi
  done
  return 1
}

discover_repositories() {
  python3 - "$HOME_DIR" "$REGISTRY" "$SOURCE_ROOT" "$TARGET_REPO" "$ONLY_LEVEL1" "$ONLY_LEVEL2" <<'PYEOF'
import json
import pathlib
import sys

home = pathlib.Path(sys.argv[1]).resolve()
registry = pathlib.Path(sys.argv[2])
source = pathlib.Path(sys.argv[3]).resolve()
target = sys.argv[4]
only_level1 = sys.argv[5] == "1"
only_level2 = sys.argv[6] == "1"

def is_repo(path):
    return (path / ".git").exists() and ((path / "AGENTS.md").is_file() or (path / "CLAUDE.md").is_file())

if target:
    path = pathlib.Path(target).expanduser().resolve()
    if not is_repo(path):
        raise SystemExit(f"Target is not a managed Git repository: {path}")
    print(f"target\t{path}")
    raise SystemExit(0)

repos = {}
data = json.loads(registry.read_text(encoding="utf-8"))
entries = data.get("repositories", []) if isinstance(data, dict) else data
for entry in entries:
    if not isinstance(entry, dict) or entry.get("level") not in (1, 2):
        continue
    raw = entry.get("path")
    if not isinstance(raw, str) or not raw:
        continue
    path = (home / raw).resolve()
    try:
        path.relative_to(home)
    except ValueError:
        continue
    if path != source and is_repo(path):
        repos[path] = int(entry["level"])

for path, level in sorted(repos.items(), key=lambda item: (item[1], str(item[0]).lower())):
    if only_level1 and level != 1:
        continue
    if only_level2 and level != 2:
        continue
    print(f"{level}\t{path}")
PYEOF
}

file_mode_matches() {
  local path="$1" executable="$2"
  # DrvFS cannot prove executable intent for Windows-hosted WSL fixtures.
  # Content remains governed by Git; native mode checks run in PowerShell.
  if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
    case "$path" in
      /mnt/[A-Za-z]/*) return 0 ;;
    esac
  fi
  if [ "$executable" = "true" ]; then
    [ -x "$path" ]
  else
    [ ! -x "$path" ]
  fi
}

raw_file_matches() {
  local source_file="$1" target_file="$2" executable="$3"
  [ -f "$target_file" ] && cmp -s -- "$source_file" "$target_file" && file_mode_matches "$target_file" "$executable"
}

file_matches() {
  local repo="$1" source_file="$2" target_file="$3" relative_path="$4" executable="$5"
  local source_hash target_hash
  [ -f "$target_file" ] || return 1
  source_hash="$(git -C "$repo" hash-object --path="$relative_path" -- "$source_file" 2>/dev/null)" || return 1
  target_hash="$(git -C "$repo" hash-object --path="$relative_path" -- "$target_file" 2>/dev/null)" || return 1
  [ "$source_hash" = "$target_hash" ] && file_mode_matches "$target_file" "$executable"
}

managed_path_is_dirty() {
  local repo="$1" relative_path="$2" source_file="$3" executable="$4"
  local target_file="${repo}/${relative_path}"
  if file_matches "$repo" "$source_file" "$target_file" "$relative_path" "$executable"; then
    return 1
  fi
  if [ ! -e "$target_file" ] &&
     ! git -C "$repo" ls-files --error-unmatch -- "$relative_path" >/dev/null 2>&1; then
    return 1
  fi
  [ -n "$(git -C "$repo" status --porcelain=v1 --untracked-files=all -- "$relative_path" 2>/dev/null)" ]
}

process_repository() {
  local level="$1" repo="$2" index relative_path executable source_file target_file
  local exception dirty=0 drift=0
  REPOS_TOTAL=$((REPOS_TOTAL + 1))
  echo ""
  info "Level ${level}: ${repo}"

  for index in "${!MANAGED_PATHS[@]}"; do
    relative_path="${MANAGED_PATHS[$index]}"
    executable="${MANAGED_EXECUTABLE[$index]}"
    source_file="${SOURCE_ROOT}/${relative_path}"
    if managed_path_is_dirty "$repo" "$relative_path" "$source_file" "$executable"; then
      warn "Lokale Aenderung an verwalteter Datei / local managed-file change: ${repo}/${relative_path}"
      dirty=1
    fi
  done
  if [ "$dirty" -eq 1 ]; then
    warn "Repository uebersprungen / skipped: ${repo}"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi

  for index in "${!MANAGED_PATHS[@]}"; do
    relative_path="${MANAGED_PATHS[$index]}"
    executable="${MANAGED_EXECUTABLE[$index]}"
    source_file="${SOURCE_ROOT}/${relative_path}"
    target_file="${repo}/${relative_path}"
    if ! raw_file_matches "$source_file" "$target_file" "$executable"; then
      RAW_DIFFERENCES=$((RAW_DIFFERENCES + 1))
    fi
    if file_matches "$repo" "$source_file" "$target_file" "$relative_path" "$executable"; then
      [ "$VERBOSE" -eq 1 ] && echo "  [CURRENT] ${relative_path}"
      continue
    fi
    if [ -f "$target_file" ] &&
       file_mode_matches "$target_file" "$executable" &&
       git -C "$repo" ls-files --error-unmatch -- "$relative_path" >/dev/null 2>&1 &&
       exception="$(exception_reason "$repo" "$relative_path")"; then
      FILES_EXCEPTED=$((FILES_EXCEPTED + 1))
      echo "  [EXCEPTED] ${relative_path}: ${exception}"
      continue
    fi

    drift=$((drift + 1))
    FILES_CHANGED=$((FILES_CHANGED + 1))
    if [ "$CHECK_ONLY" -eq 1 ]; then
      echo "  [DRIFT] ${relative_path}"
    elif [ "$DRY_RUN" -eq 1 ]; then
      echo "  [DRY-RUN] ${relative_path}"
    else
      mkdir -p -- "$(dirname -- "$target_file")"
      temporary_file="${target_file}.tmp.$$"
      cp -- "$source_file" "$temporary_file"
      if [ "$executable" = "true" ]; then
        chmod 0755 "$temporary_file"
      else
        chmod 0644 "$temporary_file"
      fi
      mv -- "$temporary_file" "$target_file"
      echo "  [CHANGED] ${relative_path}"
    fi
  done

  if [ "$drift" -eq 0 ]; then
    REPOS_CURRENT=$((REPOS_CURRENT + 1))
    ok "Bereits aktuell / already current: ${repo}"
  elif [ "$CHECK_ONLY" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    REPOS_DRIFTED=$((REPOS_DRIFTED + 1))
  else
    REPOS_CHANGED=$((REPOS_CHANGED + 1))
  fi
}

while IFS=$'\t' read -r level repository; do
  [ -n "$repository" ] || continue
  process_repository "$level" "$repository"
done < <(discover_repositories)

echo ""
echo "Zusammenfassung / Summary"
echo "  repositories.total:   ${REPOS_TOTAL}"
echo "  repositories.current: ${REPOS_CURRENT}"
echo "  repositories.changed: ${REPOS_CHANGED}"
echo "  repositories.drifted: ${REPOS_DRIFTED}"
echo "  repositories.skipped: ${REPOS_SKIPPED}"
echo "  files.raw_differences: ${RAW_DIFFERENCES}"
echo "  files.exceptions:      ${FILES_EXCEPTED}"
echo "  files.actionable_drift: ${FILES_CHANGED}"
echo "  files.different:       ${FILES_CHANGED}"

if [ "$REPOS_TOTAL" -eq 0 ] || [ "$REPOS_SKIPPED" -gt 0 ]; then
  exit 2
fi
if [ "$CHECK_ONLY" -eq 1 ] && [ "$REPOS_DRIFTED" -gt 0 ]; then
  exit 1
fi
exit 0
