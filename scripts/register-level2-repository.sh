#!/usr/bin/env bash
# register-level2-repository.sh
# Register a Level-1/Level-2 repository in the operational GSDB registry.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/lib/secure-development-hardening.sh"
PRESET_PROFILE_CATALOG="$SCRIPT_DIR/config/spec-kit-preset-profiles.json"

if [ -f "$LIB_FILE" ]; then
  # shellcheck source=/dev/null
  . "$LIB_FILE"
fi

OPT_REGISTRY=""
OPT_REPOS=()
OPT_SCAN_ROOTS=()
OPT_LEVEL=""
OPT_PRIMARY_LANGUAGE=""
OPT_MSL_STATUS=""
OPT_GSDB_REQUIRED=""
OPT_PRESET_PROFILE=""
OPT_ROLE=""
OPT_SOURCE=""
OPT_DRY_RUN=false

usage() {
  cat <<'EOF'
register-level2-repository.sh - Level-1/Level-2-Repo in GSDB-Registry eintragen

Usage:
  bash scripts/register-level2-repository.sh --repo PATH [options]
  bash scripts/register-level2-repository.sh --scan-root PATH [options]

Options:
  --repo PATH                 Repository to register. Repeatable.
  --scan-root PATH            Scan a workspace root for git repositories. Repeatable.
  --registry PATH             Registry JSON. Default: ~/.home-baseline/level2-repository-registry.json.
  --level 1|2                 Explicit repository level. Default: infer from parent git repo.
  --primary-language LANG     Optional primary language. Default: detect from governance, project suffix, or files.
  --msl-status STATUS         Override: msl, non-msl, msl-mixed-tooling, n/a, or unknown.
  --gsdb-required true|false  Whether GSDB applies. Default: true for Level-2 repos.
  --preset-profile NAME       Entry-scoped preset profile. It never changes the registry default.
                              Default: registry defaultPresetProfile,
                              otherwise standard-eight-governance-presets for GSDB Level-2.
  --role NAME                 Registry role note. Default: level-2-project or level-1-workspace.
  --source NAME               Registration source. Default: manual-registration or maintenance-discovery.
  --dry-run                   Show the registry update without writing.
  -h, --help                  Show this help.
EOF
}

die() {
  printf 'Fehler: %s\n' "$*" >&2
  exit 1
}

normalize_path() {
  local path="$1"
  case "$path" in
    ~/*) printf '%s/%s\n' "$HOME" "${path#~/}" ;;
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$PWD" "$path" ;;
  esac
}

default_registry() {
  printf '%s\n' "$HOME/.home-baseline/level2-repository-registry.json"
}

infer_level() {
  local repo="$1"
  local parent
  parent="$(dirname "$repo")"
  if [ -d "$parent/.git" ]; then
    printf '%s\n' "2"
  else
    printf '%s\n' "1"
  fi
}

to_home_relative() {
  local path="$1"
  case "$path" in
    "$HOME"/*) printf '%s\n' "${path#"$HOME"/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

discover_repositories() {
  local root="$1"
  [ -d "$root" ] || return 0
  root="${root%/}"
  find "$root" -type d -name .git -prune -print 2>/dev/null \
    | while IFS= read -r git_dir; do
        repo_dir="$(dirname "$git_dir")"
        [ "$repo_dir" = "$root" ] && continue
        printf '%s\n' "$repo_dir"
      done
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      [ $# -ge 2 ] || die "--repo braucht einen Pfad"
      OPT_REPOS+=("$(normalize_path "$2")")
      shift 2
      ;;
    --scan-root)
      [ $# -ge 2 ] || die "--scan-root braucht einen Pfad"
      OPT_SCAN_ROOTS+=("$(normalize_path "$2")")
      shift 2
      ;;
    --registry)
      [ $# -ge 2 ] || die "--registry braucht einen Pfad"
      OPT_REGISTRY="$(normalize_path "$2")"
      shift 2
      ;;
    --level)
      [ $# -ge 2 ] || die "--level braucht einen Wert"
      OPT_LEVEL="$2"
      shift 2
      ;;
    --primary-language)
      [ $# -ge 2 ] || die "--primary-language braucht einen Wert"
      OPT_PRIMARY_LANGUAGE="$2"
      shift 2
      ;;
    --msl-status)
      [ $# -ge 2 ] || die "--msl-status braucht einen Wert"
      OPT_MSL_STATUS="$2"
      shift 2
      ;;
    --gsdb-required)
      [ $# -ge 2 ] || die "--gsdb-required braucht true oder false"
      OPT_GSDB_REQUIRED="$2"
      shift 2
      ;;
    --preset-profile)
      [ $# -ge 2 ] || die "--preset-profile braucht einen Wert"
      OPT_PRESET_PROFILE="$2"
      shift 2
      ;;
    --role)
      [ $# -ge 2 ] || die "--role braucht einen Wert"
      OPT_ROLE="$2"
      shift 2
      ;;
    --source)
      [ $# -ge 2 ] || die "--source braucht einen Wert"
      OPT_SOURCE="$2"
      shift 2
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

[ "${#OPT_REPOS[@]}" -gt 0 ] || [ "${#OPT_SCAN_ROOTS[@]}" -gt 0 ] || die "--repo oder --scan-root ist erforderlich"
command -v python3 >/dev/null 2>&1 || die "python3 nicht gefunden"

OPT_REGISTRY="${OPT_REGISTRY:-$(default_registry)}"
if ! $OPT_DRY_RUN; then
  mkdir -p "$(dirname "$OPT_REGISTRY")"
fi

if [ -z "$OPT_SOURCE" ]; then
  if [ "${#OPT_SCAN_ROOTS[@]}" -gt 0 ]; then
    OPT_SOURCE="maintenance-discovery"
  else
    OPT_SOURCE="manual-registration"
  fi
fi

if [ "${#OPT_SCAN_ROOTS[@]}" -gt 0 ]; then
  while IFS= read -r discovered_repo; do
    [ -n "$discovered_repo" ] && OPT_REPOS+=("$discovered_repo")
  done < <(
    for scan_root in "${OPT_SCAN_ROOTS[@]}"; do
      discover_repositories "$scan_root"
    done | sort -u
  )
fi

register_repository() {
  local repo="$1"
  [ -d "$repo/.git" ] || die "kein Git-Repository: $repo"

  local project_name level language msl_status gsdb_required preset_profile role repo_rel today dry_run

  project_name="$(basename "$repo")"
  level="${OPT_LEVEL:-$(infer_level "$repo")}"
  case "$level" in
    1|2) ;;
    *) die "--level muss 1 oder 2 sein" ;;
  esac

  language="$OPT_PRIMARY_LANGUAGE"
  if [ -z "$language" ] && command -v sdh_detect_language >/dev/null 2>&1; then
    language="$(sdh_detect_language "$repo" "$project_name" "" 2>/dev/null || true)"
  fi
  [ -n "$language" ] || language="unknown"

  msl_status="$OPT_MSL_STATUS"
  if [ -z "$msl_status" ]; then
    msl_status="unknown"
    if command -v sdh_is_msl_language >/dev/null 2>&1 && sdh_is_msl_language "$language"; then
      msl_status="msl"
    elif command -v sdh_is_known_non_msl_language >/dev/null 2>&1 && sdh_is_known_non_msl_language "$language"; then
      msl_status="non-msl"
    elif [ "$language" = "none" ]; then
      msl_status="n/a"
    fi
  fi
  case "$msl_status" in
    msl|non-msl|msl-mixed-tooling|n/a|unknown) ;;
    *) die "--msl-status ist ungueltig: $msl_status" ;;
  esac

  gsdb_required="$OPT_GSDB_REQUIRED"
  if [ -z "$gsdb_required" ]; then
    if [ "$level" = "2" ]; then
      gsdb_required="true"
    else
      gsdb_required="false"
    fi
  fi
  case "$gsdb_required" in
    true|false) ;;
    *) die "--gsdb-required muss true oder false sein" ;;
  esac

  preset_profile="$OPT_PRESET_PROFILE"
  if [ -z "$preset_profile" ] && [ -f "$OPT_REGISTRY" ]; then
    preset_profile="$(python3 - "$OPT_REGISTRY" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle).get("defaultPresetProfile", "")
if isinstance(value, str):
    print(value)
PY
)"
  fi
  if [ -z "$preset_profile" ]; then
    if [ "$level" = "2" ] && [ "$gsdb_required" = "true" ]; then
      preset_profile="standard-eight-governance-presets"
    else
      preset_profile="none"
    fi
  fi

  role="$OPT_ROLE"
  if [ -z "$role" ]; then
    if [ "$level" = "2" ]; then
      role="level-2-project"
    else
      role="level-1-workspace"
    fi
  fi

  repo_rel="$(to_home_relative "$repo")"
  today="$(date +%Y-%m-%d)"
  dry_run="false"
  $OPT_DRY_RUN && dry_run="true"

  python3 - "$OPT_REGISTRY" "$repo_rel" "$level" "$language" "$msl_status" "$gsdb_required" "$preset_profile" "$role" "$OPT_SOURCE" "$today" "$dry_run" \
    "$([ -n "$OPT_PRIMARY_LANGUAGE" ] && printf true || printf false)" \
    "$([ -n "$OPT_MSL_STATUS" ] && printf true || printf false)" \
    "$([ -n "$OPT_GSDB_REQUIRED" ] && printf true || printf false)" \
    "$([ -n "$OPT_PRESET_PROFILE" ] && printf true || printf false)" \
    "$([ -n "$OPT_ROLE" ] && printf true || printf false)" \
    "$PRESET_PROFILE_CATALOG" <<'PY'
import json
import sys
from pathlib import Path

registry_path = Path(sys.argv[1])
repo_path = sys.argv[2]
level = int(sys.argv[3])
language = sys.argv[4]
msl_status = sys.argv[5]
gsdb_required = sys.argv[6] == "true"
preset_profile = sys.argv[7]
role = sys.argv[8]
source = sys.argv[9]
today = sys.argv[10]
dry_run = sys.argv[11] == "true"
language_explicit = sys.argv[12] == "true"
msl_explicit = sys.argv[13] == "true"
gsdb_explicit = sys.argv[14] == "true"
preset_explicit = sys.argv[15] == "true"
role_explicit = sys.argv[16] == "true"
profile_catalog_path = Path(sys.argv[17])

if registry_path.exists():
    data = json.loads(registry_path.read_text(encoding="utf-8"))
else:
    data = {
        "schemaVersion": 1,
        "description": "Local operational registry for GSDB-relevant level-1 and level-2 repositories. Paths are relative to the user's home directory.",
        "defaultPresetProfile": "standard-eight-governance-presets",
        "updatedAt": today,
        "repositories": [],
    }

repos = data.setdefault("repositories", [])
existing = next((item for item in repos if item.get("path") == repo_path), None)
entry = {
    "path": repo_path,
    "level": level,
    "primaryLanguage": language,
    "mslStatus": msl_status,
    "gsdbRequired": gsdb_required,
    "presetProfile": preset_profile,
    "role": role,
    "source": source,
    "registeredAt": today,
}

if existing:
    preserve_curated = source == "maintenance-discovery" and existing.get("source") not in (None, "", "maintenance-discovery")
    if not language_explicit and (preserve_curated or language == "unknown") and existing.get("primaryLanguage") not in (None, "", "unknown"):
        entry["primaryLanguage"] = existing["primaryLanguage"]
    if not msl_explicit and (preserve_curated or msl_status == "unknown") and existing.get("mslStatus") not in (None, "", "unknown"):
        entry["mslStatus"] = existing["mslStatus"]
    if not gsdb_explicit and (preserve_curated or existing.get("gsdbRequired") is True):
        entry["gsdbRequired"] = existing.get("gsdbRequired", entry["gsdbRequired"])
    existing_profile = existing.get("presetProfile")
    if existing_profile in (
        "standard-six-governance-presets",
        "standard-seven-governance-presets",
    ):
        existing_profile = "standard-eight-governance-presets"
    if not preset_explicit and (preserve_curated or preset_profile == "none") and existing_profile not in (None, ""):
        entry["presetProfile"] = existing_profile
    if not role_explicit and preserve_curated and existing.get("role") not in (None, ""):
        entry["role"] = existing["role"]
    if source == "maintenance-discovery" and existing.get("source"):
        entry["source"] = existing["source"]
    entry["registeredAt"] = existing.get("registeredAt", today)

profile_catalog = json.loads(profile_catalog_path.read_text(encoding="utf-8"))
supported_profiles = profile_catalog.get("profiles", {})
if entry["presetProfile"] not in supported_profiles:
    raise SystemExit(
        f"Unbekanntes Preset-Profil / unknown preset profile: {entry['presetProfile']}"
    )

if existing:
    changed = any(existing.get(key) != value for key, value in entry.items())
    if changed:
        existing.update(entry)
        action = "updated"
    else:
        action = "unchanged"
else:
    repos.append(entry)
    action = "added"

if action != "unchanged":
    data["updatedAt"] = today
    data["repositories"] = sorted(repos, key=lambda item: item.get("path", ""))

if dry_run:
    print(f"[dry-run] {action}: {repo_path} -> {registry_path}")
elif action == "unchanged":
    print(f"unchanged: {repo_path} -> {registry_path}")
else:
    registry_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{action}: {repo_path} -> {registry_path}")
PY
}

for repo in "${OPT_REPOS[@]}"; do
  register_repository "$repo"
done
