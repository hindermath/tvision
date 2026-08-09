#!/usr/bin/env bash
# Richtet die Claude Code statusLine in ~/.claude/settings.json ein.
# macOS/Linux — Gegenstück: setup-claude-settings.ps1
#
# Verwendung / Usage:
#   bash scripts/setup-claude-settings.sh           # einrichten / set up
#   bash scripts/setup-claude-settings.sh --dry-run # Vorschau / preview only
#   bash scripts/setup-claude-settings.sh --force   # bestehende Config überschreiben / overwrite

set -euo pipefail

DRY_RUN=false
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force)   FORCE=true ;;
    -h|--help) printf "USAGE: setup-claude-settings.sh [--dry-run] [--force]\n" >&2; exit 0 ;;
    *) printf "Unbekanntes Argument / Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
  esac
done

SETTINGS_DIR="${HOME}/.claude"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

# --- Prüfungen / Pre-checks ---
if ! command -v python3 &>/dev/null; then
  echo "Fehler / Error: python3 wird benötigt / is required." >&2
  exit 1
fi
if ! command -v jq &>/dev/null; then
  echo "Warnung / Warning: jq nicht gefunden — wird zur Laufzeit der statusLine benötigt / needed at statusLine runtime." >&2
fi

# --- Vorschau / Dry-run ---
if $DRY_RUN; then
  printf "[Dry Run] Würde statusLine setzen in / Would set statusLine in: %s\n" "${SETTINGS_FILE}"
  printf "[Dry Run] Format: Modell | ~/Pfad [Branch] | ctx: %% | 5h: %% | 7d: %%\n"
  exit 0
fi

# --- Prüfe bestehende Konfiguration / Check for existing statusLine ---
if [ -f "${SETTINGS_FILE}" ]; then
  has_statusline=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    print('yes' if 'statusLine' in d else 'no')
except Exception:
    print('no')
" "${SETTINGS_FILE}" 2>/dev/null || echo "no")

  if [ "${has_statusline}" = "yes" ] && ! $FORCE; then
    echo "statusLine bereits konfiguriert / already configured. Verwende --force zum Überschreiben / Use --force to overwrite."
    exit 0
  fi
fi

mkdir -p "${SETTINGS_DIR}"

# --- statusLine einrichten via Python / Set via Python ---
# Python liest settings.json (falls vorhanden), fügt statusLine hinzu und schreibt zurück.
# Python reads settings.json (if present), adds statusLine, and writes back.
python3 - "${SETTINGS_FILE}" <<'PYEOF'
import json, sys, os

path = sys.argv[1]

# Exakter Bash-Befehl wie in ~/.claude/settings.json auf macOS/Linux.
# Exact bash command as stored in ~/.claude/settings.json on macOS/Linux.
STATUS_CMD = (
    """input=$(cat); """
    """model=$(echo "$input" | jq -r '.model.display_name'); """
    """raw_cwd=$(echo "$input" | jq -r '.cwd'); """
    """home=$(echo ~); """
    """cwd=$(echo "$raw_cwd" | sed "s|^$home|~|"); """
    """branch=$(git -C "$raw_cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null); """
    """if [ -n "$branch" ]; then cwd_display="$cwd [$branch]"; else cwd_display="$cwd"; fi; """
    """remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty'); """
    """five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty'); """
    """week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty'); """
    """if [ -n "$remaining" ]; then ctx=$(printf "ctx: %.0f%%" "$remaining"); else ctx="ctx: n/a"; fi; """
    """rl=""; """
    """if [ -n "$five" ]; then rl=$(printf " | 5h: %.0f%%" "$five"); fi; """
    """if [ -n "$week" ]; then rl="$rl"$(printf " | 7d: %.0f%%" "$week"); fi; """
    """printf "%s | %s | %s%s" "$model" "$cwd_display" "$ctx" "$rl\""""
)

data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)

data['statusLine'] = {'type': 'command', 'command': STATUS_CMD}

with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"✓ statusLine gesetzt / set in {path}")
print("  Format: Modell | ~/Pfad [Branch] | ctx: % | 5h: % | 7d: %")
PYEOF
