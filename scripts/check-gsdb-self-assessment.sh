#!/usr/bin/env bash
# check-gsdb-self-assessment.sh
# Preflight-check GSDB readiness and prepare a later Spec Kit intake.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/lib/secure-development-hardening.sh"
PRESET_CONFIG="$SCRIPT_DIR/config/spec-kit-governance-presets.json"

if [ ! -f "$LIB_FILE" ]; then
  echo "Fehler: Hilfsbibliothek nicht gefunden: $LIB_FILE" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$LIB_FILE"

OPT_REGISTRY=""
OPT_HOME_DIR="$HOME"
OPT_REPOS=()
OPT_CHECK_ONLY=false
OPT_DRY_RUN=false
OPT_FAIL_ON_OPEN=false

usage() {
  cat <<'EOF'
check-gsdb-self-assessment.sh - GSDB-Preflight und Spec-Kit-Intake vorbereiten

Usage:
  bash scripts/check-gsdb-self-assessment.sh [options]

Options:
  --repo PATH             Explicit repository; repeatable. Default: local GSDB registry.
  --registry PATH         Registry JSON. Default: ~/.home-baseline/level2-repository-registry.json.
  --home-dir PATH         Home directory for registry-relative paths.
  --check-only            Do not write report, intake, or order file.
  --fail-on-open          Exit non-zero when Open findings exist.
  --dry-run               Show write actions only; implies no tracked-file writes.
  -h, --help              Show this help.
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

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      [ $# -ge 2 ] || die "--repo braucht einen Pfad"
      OPT_REPOS+=("$(normalize_path "$2")")
      shift 2
      ;;
    --registry)
      [ $# -ge 2 ] || die "--registry braucht einen Pfad"
      OPT_REGISTRY="$(normalize_path "$2")"
      shift 2
      ;;
    --home-dir)
      [ $# -ge 2 ] || die "--home-dir braucht einen Pfad"
      OPT_HOME_DIR="$(normalize_path "$2")"
      shift 2
      ;;
    --check-only)
      OPT_CHECK_ONLY=true
      shift
      ;;
    --fail-on-open)
      OPT_FAIL_ON_OPEN=true
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

OPT_REGISTRY="${OPT_REGISTRY:-$(default_registry)}"

load_registry_repos() {
  local registry="$1"
  local home_dir="$2"
  [ -f "$registry" ] || return 1
  command -v python3 >/dev/null 2>&1 || die "python3 nicht gefunden"
  python3 - "$registry" "$home_dir" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
home = Path(sys.argv[2]).expanduser()
data = json.loads(registry.read_text(encoding="utf-8"))
for item in data.get("repositories", []):
    if item.get("gsdbRequired") is True:
        path = Path(item.get("path", ""))
        print(str(path if path.is_absolute() else home / path))
PY
}

registry_entry_for_repo() {
  local repo="$1"
  [ -f "$OPT_REGISTRY" ] || return 1
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - "$OPT_REGISTRY" "$OPT_HOME_DIR" "$repo" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
home = Path(sys.argv[2]).expanduser()
repo = Path(sys.argv[3]).expanduser().resolve(strict=False)
data = json.loads(registry.read_text(encoding="utf-8"))
for item in data.get("repositories", []):
    path = Path(item.get("path", ""))
    candidate = (path if path.is_absolute() else home / path).resolve(strict=False)
    if candidate == repo:
        print(
            f"{item.get('level', '')}\t"
            f"{item.get('primaryLanguage', '')}\t"
            f"{item.get('mslStatus', '')}\t"
            f"{item.get('presetProfile', '')}"
        )
        break
PY
}

if [ "${#OPT_REPOS[@]}" -eq 0 ]; then
  while IFS= read -r repo; do
    [ -n "$repo" ] && OPT_REPOS+=("$repo")
  done < <(load_registry_repos "$OPT_REGISTRY" "$OPT_HOME_DIR" || true)
fi

if [ "${#OPT_REPOS[@]}" -eq 0 ]; then
  OPT_REPOS+=("$PWD")
fi

preset_ids() {
  if [ -f "$PRESET_CONFIG" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$PRESET_CONFIG" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    for item in json.load(handle).get("presets", []):
        print(item["id"])
PY
  fi
}

markdown_escape() {
  printf '%s' "$1" | sed 's/|/\\|/g'
}

append_row() {
  local report="$1"
  local status="$2"
  local item="$3"
  local evidence="$4"
  local rationale="$5"
  local follow_up="$6"
  printf '| %s | %s | `%s` | %s | %s |\n' \
    "$status" "$(markdown_escape "$item")" "$(markdown_escape "$evidence")" \
    "$(markdown_escape "$rationale")" "$(markdown_escape "$follow_up")" >> "$report"
}

check_path() {
  local repo="$1"
  local report="$2"
  local label="$3"
  local rel_path="$4"
  local follow_up="$5"
  if [ -e "$repo/$rel_path" ]; then
    append_row "$report" "OK" "$label" "$rel_path" "vorhanden" "-"
  else
    append_row "$report" "Open" "$label" "$rel_path" "fehlt" "$follow_up"
    return 1
  fi
}

find_archived_intake() {
  local repo="$1"
  local rel_path="$2"
  local stem="${rel_path%.md}"

  find "$repo" -maxdepth 1 -type f -name "${stem}.[0-9][0-9][0-9]-*.md" -print 2>/dev/null \
    | sort \
    | head -n 1
}

check_intake_path() {
  local repo="$1"
  local report="$2"
  local label="$3"
  local rel_path="$4"
  local follow_up="$5"
  local archived

  if [ -f "$repo/$rel_path" ]; then
    append_row "$report" "OK" "$label" "$rel_path" "aktiver Intake vorhanden" "-"
    return 0
  fi

  archived="$(find_archived_intake "$repo" "$rel_path")"
  if [ -n "$archived" ]; then
    append_row "$report" "OK" "$label" "$(basename "$archived")" "abgeschlossener oder archivierter Intake vorhanden" "-"
    return 0
  fi

  append_row "$report" "Open" "$label" "$rel_path" "aktiver oder archivierter Intake fehlt" "$follow_up"
  return 1
}

has_non_msl_justification() {
  local repo="$1"
  local content_file
  local combined

  combined="$(mktemp)"
  for content_file in "$repo/constitution.md" "$repo/.specify/memory/constitution.md"; do
    [ -f "$content_file" ] || continue
    cat "$content_file" >> "$combined"
    printf '\n' >> "$combined"
  done

  if grep -Eiq 'Nicht-MSL|non-MSL|not MSL|not an MSL|not memory-safe|C89|cc65' "$combined" \
    && grep -Eiq 'Kompensationskontrollen|compensating controls|Secure-C-Review|Makefile-Kettenpruefung|Artefakt-Hygiene|Target/Sample-Validierung|target compatibility|toolchain compatibility' "$combined"; then
    rm -f "$combined"
    return 0
  fi

  rm -f "$combined"
  return 1
}

render_gsdb_intake() {
  local repo="$1"
  local project_name="$2"
  local target="$repo/Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md"
  local template="$SCRIPT_DIR/templates/gsdb-spec-kit-intensivpruefung-lastenheft.md"
  local rendered tmp archived

  [ -f "$template" ] || die "GSDB-Intake-Template nicht gefunden: $template"

  archived="$(find_archived_intake "$repo" "$(basename "$target")")"
  if [ ! -f "$target" ] && [ -n "$archived" ]; then
    printf '  unveraendert: abgeschlossenes GSDB-Intake vorhanden: %s\n' "$(basename "$archived")"
    return 0
  fi

  if $OPT_CHECK_ONLY || $OPT_DRY_RUN; then
    local mode_label
    if $OPT_CHECK_ONLY; then
      mode_label="check-only"
    else
      mode_label="dry-run"
    fi
    if [ -f "$target" ]; then
      printf '  [%s] GSDB-Intake pruefen/aktualisieren: %s\n' "$mode_label" "$(basename "$target")"
    else
      printf '  [%s] GSDB-Intake erzeugen: %s\n' "$mode_label" "$(basename "$target")"
    fi
    return 0
  fi

  rendered="$(mktemp)"
  sdh_render_template "$template" "$rendered" "$project_name"

  if [ -f "$target" ]; then
    if grep -q '<!-- gsdb-spec-kit-intensivpruefung:start -->' "$target" \
      && grep -q '<!-- gsdb-spec-kit-intensivpruefung:end -->' "$target"; then
      tmp="$(mktemp)"
      awk -v rendered="$rendered" '
        BEGIN {
          while ((getline line < rendered) > 0) block = block line "\n"
          in_generated = 0
        }
        /<!-- gsdb-spec-kit-intensivpruefung:start -->/ {
          printf "%s", block
          in_generated = 1
          next
        }
        /<!-- gsdb-spec-kit-intensivpruefung:end -->/ {
          in_generated = 0
          next
        }
        in_generated == 0 { print }
      ' "$target" > "$tmp"
      mv "$tmp" "$target"
    else
      printf '  Hinweis: vorhandenes GSDB-Intake ohne Marker bleibt unveraendert: %s\n' "$target"
    fi
    rm -f "$rendered"
  else
    mv "$rendered" "$target"
  fi
}

write_report_header() {
  local report="$1"
  local repo="$2"
  local project_name="$3"
  local language="$4"
  local today
  today="$(date +%Y-%m-%d)"
  cat > "$report" <<EOF
# GSDB Self-Assessment / GSDB Preflight

**Projekt / Project:** $project_name
**Datum / Date:** $today
**Repository:** \`$repo\`
**Primaersprache / Primary language:** $language

Dieses Dokument ist ein Preflight-Bericht. Es startet keinen Spec-Kit-Lauf und
ist keine formale Freigabe.

*This document is a preflight report. It does not start a Spec Kit run and is
not a formal approval.*

| Status | Pruefpunkt / Check | Evidenzpfad / Evidence path | Begruendung / Rationale | Follow-up |
|---|---|---|---|---|
EOF
}

check_repo() {
  local repo="$1"
  local project_name language report_tmp report_target open_count=0 preset_output preset_id dry_mode
  local gsdb_intake_missing=false
  local registry_meta registry_level="" registry_language="" registry_msl_status="" registry_preset_profile=""

  [ -d "$repo/.git" ] || die "kein Git-Repository: $repo"
  project_name="$(basename "$repo")"
  registry_meta="$(registry_entry_for_repo "$repo" || true)"
  if [ -n "$registry_meta" ]; then
    IFS=$'\t' read -r registry_level registry_language registry_msl_status registry_preset_profile <<< "$registry_meta"
  fi
  language="$(sdh_detect_language "$repo" "$project_name" "" 2>/dev/null || true)"
  if [ "$registry_msl_status" = "non-msl" ] && [ -n "$registry_language" ]; then
    language="$registry_language"
  elif [ -z "$language" ] && [ -n "$registry_language" ]; then
    language="$registry_language"
  fi
  [ -n "$language" ] || language="unknown"

  printf '## %s\n' "$repo"
  printf '  Sprache / language: %s\n' "$language"

  report_tmp="$(mktemp)"
  write_report_header "$report_tmp" "$repo" "$project_name" "$language"

  check_path "$repo" "$report_tmp" "GSDB README" "docs/secure-development/README.md" "GSDB synchronisieren" || open_count=$((open_count + 1))
  check_path "$repo" "$report_tmp" "GSDB Richtlinie" "docs/secure-development/Richtlinie_Sichere-Entwicklung.md" "GSDB synchronisieren" || open_count=$((open_count + 1))
  check_path "$repo" "$report_tmp" "GSDB Checklistensammelband" "docs/secure-development/Checklistensammelband_Sichere-Entwicklung.md" "GSDB synchronisieren" || open_count=$((open_count + 1))
  check_path "$repo" "$report_tmp" "GSDB mitgeltende Dokumente" "docs/secure-development/mitgeltende-dokumente/README.md" "mitgeltende Dokumente synchronisieren" || open_count=$((open_count + 1))
  check_path "$repo" "$report_tmp" "GSDB Preset-Verzahnung" "docs/secure-development/mitgeltende-dokumente/Verzahnung_Richtlinie_Checklisten_Spec-Kit-Presets.md" "Verzahnung synchronisieren" || open_count=$((open_count + 1))

  local missing_checklists=0 number checklist
  for number in 01 02 03 04 05 06 07 08 09 10 11 12; do
    if ! ls "$repo/docs/secure-development/checklisten/CL_${number}_"*.md >/dev/null 2>&1; then
      missing_checklists=$((missing_checklists + 1))
    fi
  done
  if [ "$missing_checklists" = "0" ]; then
    append_row "$report_tmp" "OK" "CL_01 bis CL_12" "docs/secure-development/checklisten/" "alle 12 Checklisten vorhanden" "-"
  else
    append_row "$report_tmp" "Open" "CL_01 bis CL_12" "docs/secure-development/checklisten/" "${missing_checklists} Checklisten fehlen" "GSDB synchronisieren"
    open_count=$((open_count + 1))
  fi

  if [ "$registry_level" = "1" ] || [ "$registry_msl_status" = "n/a" ] || [ "$language" = "none" ]; then
    append_row "$report_tmp" "N/A" "MSL-Status" "~/.home-baseline/level2-repository-registry.json" "Koordinations- oder Nicht-Implementierungsrepo" "-"
  elif [ "$registry_msl_status" = "msl-mixed-tooling" ]; then
    append_row "$report_tmp" "OK" "MSL-Status" "~/.home-baseline/level2-repository-registry.json" "Registry dokumentiert GSDB-relevanten MSL-/Tooling-Mix" "-"
  elif sdh_is_msl_language "$language"; then
    append_row "$report_tmp" "OK" "MSL-Status" "constitution.md" "Primaersprache ist auf der MSL-Allowlist" "-"
  elif [ "$registry_msl_status" = "non-msl" ] || sdh_is_known_non_msl_language "$language"; then
    if has_non_msl_justification "$repo"; then
      append_row "$report_tmp" "OK" "MSL-Status" "constitution.md" "Nicht-MSL ist mit Begruendung und Kompensationskontrollen dokumentiert" "-"
    else
      append_row "$report_tmp" "Open" "MSL-Status" "constitution.md" "bekannte Nicht-MSL erkannt" "Nicht-MSL-Begruendung pruefen"
      open_count=$((open_count + 1))
    fi
  else
    append_row "$report_tmp" "Open" "MSL-Status" "constitution.md" "Primaersprache unklar oder nicht klassifiziert" "Sprache im Repository dokumentieren"
    open_count=$((open_count + 1))
  fi

  if [ "$registry_level" = "1" ]; then
    append_row "$report_tmp" "N/A" "Spec Kit initialisiert" ".specify/" "Koordinationsrepo ohne eigenen Spec-Kit-Implementierungslauf" "-"
  elif [ -d "$repo/.specify" ]; then
    append_row "$report_tmp" "OK" "Spec Kit initialisiert" ".specify/" "Spec-Kit-Verzeichnis vorhanden" "-"
  else
    append_row "$report_tmp" "Open" "Spec Kit initialisiert" ".specify/" "Spec-Kit-Verzeichnis fehlt" "Spec Kit initialisieren oder N/A begruenden"
    open_count=$((open_count + 1))
  fi

  if [ "$registry_level" = "1" ]; then
    append_row "$report_tmp" "N/A" "Governance-Presets" ".specify/presets/" "Koordinationsrepo ohne eigene Preset-Installation" "-"
  else
    preset_output="$(cd "$repo" && specify preset list 2>/dev/null || true)"
    while IFS= read -r preset_id; do
      [ -n "$preset_id" ] || continue
      if [ -n "$preset_output" ] && [[ "$preset_output" == *"(${preset_id})"* ]]; then
        append_row "$report_tmp" "OK" "Preset $preset_id" ".specify/presets/" "per specify preset list nachweisbar" "-"
      elif find "$repo/.specify/presets" -maxdepth 4 -type d -name "$preset_id" -print -quit 2>/dev/null | grep -q .; then
        append_row "$report_tmp" "OK" "Preset $preset_id" ".specify/presets/" "lokal installiert" "-"
      else
        append_row "$report_tmp" "Open" "Preset $preset_id" ".specify/presets/" "nicht nachweisbar" "Governance-Presets installieren oder Ausnahme dokumentieren"
        open_count=$((open_count + 1))
      fi
    done < <(preset_ids)
  fi

  if [ -d "$repo/docs/security" ]; then
    append_row "$report_tmp" "OK" "Projektspezifischer Nachweisort" "docs/security/" "Nachweisordner vorhanden" "-"
  else
    append_row "$report_tmp" "Open" "Projektspezifischer Nachweisort" "docs/security/" "Nachweisordner fehlt" "docs/security/ anlegen oder gleichwertigen Nachweisort dokumentieren"
    open_count=$((open_count + 1))
  fi

  check_intake_path "$repo" "$report_tmp" "RL-SE-/Checklist-Selbstpruefungs-Intake" "Lastenheft_RL-SE-Checklist-Selbstpruefung.md" "Intake vorbereiten" || open_count=$((open_count + 1))
  if [ "$registry_level" = "1" ]; then
    append_row "$report_tmp" "N/A" "Secure-Development-Hardening-Intake" "Lastenheft_Secure-Development-Hardening.md" "Koordinationsrepo ohne eigene Implementierungshaertung" "-"
  else
    check_intake_path "$repo" "$report_tmp" "Secure-Development-Hardening-Intake" "Lastenheft_Secure-Development-Hardening.md" "Intake vorbereiten" || open_count=$((open_count + 1))
  fi

  if ! check_intake_path "$repo" "$report_tmp" "GSDB-Spec-Kit-Intensivpruefungs-Intake" "Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md" "durch diesen Checker erzeugen lassen"; then
    open_count=$((open_count + 1))
    gsdb_intake_missing=true
  fi

  cat >> "$report_tmp" <<EOF

## Ergebnis / Result

- Offene Punkte / Open findings: $open_count
- Naechster Schritt / Next step: \`Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md\` spaeter manuell mit \`/speckit-specify\` starten, wenn die intensive Pruefung erfolgen soll.
EOF

  if $OPT_CHECK_ONLY; then
    printf '  check-only: Bericht und Intake nicht geschrieben; Open=%s\n' "$open_count"
  elif $OPT_DRY_RUN; then
    printf '  [dry-run] docs/security/gsdb-self-assessment.md schreiben; Open=%s\n' "$open_count"
  else
    mkdir -p "$repo/docs/security"
    report_target="$repo/docs/security/gsdb-self-assessment.md"
    mv "$report_tmp" "$report_target"
    printf '  geschrieben: docs/security/gsdb-self-assessment.md\n'
  fi

  if $OPT_CHECK_ONLY || $OPT_DRY_RUN; then
    rm -f "$report_tmp"
  fi

  render_gsdb_intake "$repo" "$project_name"

  dry_mode=0
  $OPT_DRY_RUN && dry_mode=1
  if $OPT_CHECK_ONLY; then
    printf '  check-only: Lastenheft_Abarbeitungsreihenfolge.md nicht aktualisiert\n'
  elif sdh_update_order_file "$repo" "$dry_mode"; then
    if $OPT_DRY_RUN; then
      printf '  [dry-run] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren\n'
    else
      printf '  aktualisiert: Lastenheft_Abarbeitungsreihenfolge.md\n'
    fi
  elif $OPT_DRY_RUN && $gsdb_intake_missing; then
    printf '  [dry-run] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren\n'
  else
    printf '  unveraendert: Lastenheft_Abarbeitungsreihenfolge.md\n'
  fi

  return "$open_count"
}

total_open=0
for repo in "${OPT_REPOS[@]}"; do
  repo="$(normalize_path "$repo")"
  check_repo "$repo" || total_open=$((total_open + $?))
done

printf '\nGSDB-Preflight abgeschlossen. Offene Punkte gesamt: %s\n' "$total_open"
if $OPT_FAIL_ON_OPEN && [ "$total_open" -gt 0 ]; then
  exit 1
fi
