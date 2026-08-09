#!/usr/bin/env bash
# Richtet die Codex CLI status_line in ~/.codex/config.toml ein.
# macOS/Linux -- Gegenstueck: setup-codex-settings.ps1
#
# Verwendung / Usage:
#   bash scripts/setup-codex-settings.sh           # einrichten / set up
#   bash scripts/setup-codex-settings.sh --dry-run # Vorschau / preview only
#   bash scripts/setup-codex-settings.sh --force   # bestehende Config ueberschreiben / overwrite

set -euo pipefail

DRY_RUN=false
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force)   FORCE=true ;;
    -h|--help) printf "USAGE: setup-codex-settings.sh [--dry-run] [--force]\n" >&2; exit 0 ;;
    *) printf "Unbekanntes Argument / Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/templates/codex-statusline.toml"
SETTINGS_DIR="${CODEX_HOME:-${HOME}/.codex}"
SETTINGS_FILE="${SETTINGS_DIR}/config.toml"

# --- Pruefungen / Pre-checks ---
if ! command -v python3 &>/dev/null; then
  echo "Fehler / Error: python3 wird benoetigt / is required." >&2
  exit 1
fi
if [ ! -f "${TEMPLATE_FILE}" ]; then
  printf "Fehler / Error: template not found: %s\n" "${TEMPLATE_FILE}" >&2
  exit 1
fi

# --- Vorschau / Dry-run ---
if $DRY_RUN; then
  printf "[Dry Run] Wuerde Codex status_line setzen in / Would set Codex status_line in: %s\n" "${SETTINGS_FILE}"
  printf "[Dry Run] Vorlage / Template: %s\n" "${TEMPLATE_FILE}"
  printf "[Dry Run] Elemente / Items: model-with-reasoning | context-remaining | current-dir | git-branch | context-used | five-hour-limit | weekly-limit\n"
  exit 0
fi

# --- Pruefe bestehende Konfiguration / Check for existing status_line ---
if [ -f "${SETTINGS_FILE}" ] && ! $FORCE; then
  has_statusline=$(python3 - "${SETTINGS_FILE}" <<'PYEOF'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
section_header = re.compile(r'^\[[^\]]+\]\s*$')
in_tui = False
for line in text.splitlines():
    if section_header.match(line):
        in_tui = bool(re.match(r'^\[tui\]\s*$', line))
        continue
    if in_tui and re.match(r'^\s*status_line\s*=', line):
        print('yes')
        raise SystemExit(0)
print('no')
PYEOF
)

  if [ "${has_statusline}" = "yes" ]; then
    echo "Codex status_line bereits konfiguriert / already configured. Verwende --force zum Ueberschreiben / Use --force to overwrite."
    exit 0
  fi
fi

mkdir -p "${SETTINGS_DIR}"

# --- config.toml aktualisieren / Update config.toml ---
# Das Template ist die zentrale Quelle fuer die status_line-Items.
# The template is the single source of truth for the status line items.
python3 - "${SETTINGS_FILE}" "${TEMPLATE_FILE}" <<'PYEOF'
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
template_path = Path(sys.argv[2])

template_text = template_path.read_text(encoding="utf-8")
status_match = re.search(r'(?m)^status_line\s*=\s*\[.*\]\s*$', template_text)
if not status_match:
    raise SystemExit(f"Fehler / Error: template contains no status_line entry: {template_path}")

status_line = status_match.group(0)

if config_path.exists():
    text = config_path.read_text(encoding="utf-8")
else:
    text = ""

lines = text.splitlines()
section_header = re.compile(r'^\[[^\]]+\]\s*$')
tui_header = re.compile(r'^\[tui\]\s*$')
status_entry = re.compile(r'^\s*status_line\s*=')

out = []
i = 0
found_tui = False

while i < len(lines):
    line = lines[i]
    if tui_header.match(line):
        found_tui = True
        out.append("[tui]")
        i += 1
        section = []
        while i < len(lines) and not section_header.match(lines[i]):
            if not status_entry.match(lines[i]):
                section.append(lines[i])
            i += 1

        insert_at = 0
        while insert_at < len(section):
            stripped = section[insert_at].strip()
            if stripped == "" or section[insert_at].lstrip().startswith("#"):
                insert_at += 1
                continue
            break
        section.insert(insert_at, status_line)
        out.extend(section)
        continue

    out.append(line)
    i += 1

if not found_tui:
    if out and out[-1].strip():
        out.append("")
    out.extend(template_text.strip().splitlines())

new_text = "\n".join(out).rstrip() + "\n"
config_path.write_text(new_text, encoding="utf-8")

print(f"OK  Codex status_line gesetzt / set in {config_path}")
print("    Items: model-with-reasoning | context-remaining | current-dir | git-branch | context-used | five-hour-limit | weekly-limit")
PYEOF
