#!/usr/bin/env bash
# setup-copilot-settings.sh — Überträgt die GitHub Copilot CLI-Einstellungen nach ~/.copilot/config.json
# macOS/Linux — Gegenstück: setup-copilot-settings.ps1
#
# Transferierbare Einstellungen / Transferable settings:
#   effortLevel   → Reasoning-Tiefe in der Statusline, z. B. "(high)"
#   banner        → Begrüßungs-Banner unterdrücken
#   renderMarkdown → Markdown-Rendering in Antworten
#   theme         → Farbthema (auto / light / dark)
#
# NICHT übertragen / NOT transferred:
#   logged_in_users, trusted_folders, firstLaunchAt (maschinenspezifisch / machine-specific)
#
# Verwendung / Usage:
#   bash scripts/setup-copilot-settings.sh           # einrichten / set up
#   bash scripts/setup-copilot-settings.sh --dry-run # Vorschau / preview only
#   bash scripts/setup-copilot-settings.sh --force   # bestehende Config überschreiben / overwrite

set -euo pipefail

DRY_RUN=false
FORCE=false
EFFORT_LEVEL="high"
THEME="auto"

for arg in "$@"; do
  case "$arg" in
    --dry-run)     DRY_RUN=true ;;
    --force)       FORCE=true ;;
    --effort=*)    EFFORT_LEVEL="${arg#--effort=}" ;;
    --theme=*)     THEME="${arg#--theme=}" ;;
    -h|--help) printf "USAGE: setup-copilot-settings.sh [--dry-run] [--force] [--effort=LEVEL] [--theme=THEME]\n" >&2; exit 0 ;;
    *) printf "Unbekanntes Argument / Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
  esac
done

CONFIG_DIR="${HOME}/.copilot"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# --- Validierung / Validation ---
case "$EFFORT_LEVEL" in
  low|medium|high) ;;
  *) echo "Fehler / Error: --effort muss 'low', 'medium' oder 'high' sein." >&2; exit 1 ;;
esac
case "$THEME" in
  auto|light|dark) ;;
  *) echo "Fehler / Error: --theme muss 'auto', 'light' oder 'dark' sein." >&2; exit 1 ;;
esac

if ! command -v python3 &>/dev/null; then
  echo "Fehler / Error: python3 wird benötigt / is required." >&2
  exit 1
fi

# --- Vorschau / Dry-run ---
if $DRY_RUN; then
  printf "[Dry Run] Würde Copilot-Einstellungen schreiben nach / Would write Copilot settings to: %s\n" "${CONFIG_FILE}"
  printf "[Dry Run] effortLevel=%s | banner=never | renderMarkdown=true | theme=%s\n" "$EFFORT_LEVEL" "$THEME"
  printf "[Dry Run] Statusline-Effekt / Statusline effect: ~/Pfad [⎇ Branch] Modell (%s)\n" "$EFFORT_LEVEL"
  exit 0
fi

# --- Prüfe bestehende Konfiguration / Check for existing settings ---
if [ -f "${CONFIG_FILE}" ]; then
  has_effort=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    print('yes' if 'effortLevel' in d else 'no')
except Exception:
    print('no')
" "${CONFIG_FILE}" 2>/dev/null || echo "no")

  if [ "${has_effort}" = "yes" ] && ! $FORCE; then
    existing=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
print(d.get('effortLevel', 'unbekannt / unknown'))
" "${CONFIG_FILE}" 2>/dev/null || echo "unbekannt")
    echo "Copilot-Einstellungen bereits konfiguriert / already configured (effortLevel=${existing})."
    echo "Verwende --force zum Überschreiben / Use --force to overwrite."
    exit 0
  fi
fi

mkdir -p "${CONFIG_DIR}"

# --- Einstellungen schreiben via Python / Write settings via Python ---
# Python liest config.json (falls vorhanden), aktualisiert nur die übertragbaren
# Schlüssel und lässt maschinenspezifische Daten (Auth, trusted_folders) unangetastet.
#
# Python reads config.json (if present), updates only transferable keys and
# leaves machine-specific data (auth, trusted_folders) untouched.
python3 - "${CONFIG_FILE}" "${EFFORT_LEVEL}" "${THEME}" <<'PYEOF'
import json, sys, os

path, effort_level, theme = sys.argv[1], sys.argv[2], sys.argv[3]

data = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            pass

# Nur übertragbare Einstellungen setzen / Set only transferable settings
data['effortLevel']    = effort_level
data['banner']         = 'never'
data['renderMarkdown'] = True
data['theme']          = theme

with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"✓ Copilot-Einstellungen gesetzt / settings written to {path}")
print(f"  effortLevel={effort_level} | banner=never | renderMarkdown=true | theme={theme}")
print(f"  Statusline-Effekt / Statusline effect: ~/Pfad [⎇ Branch] Modell ({effort_level})")
PYEOF
