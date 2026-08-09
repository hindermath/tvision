#!/usr/bin/env bash
# sync-constitution.sh — constitution.md in alle Level-1-Workspaces synchronisieren
# FR-REV-F01, FR-REV-F02; Contract: sync-constitution-cli.md
# Usage: bash scripts/sync-constitution.sh [--dry-run] [--yes]
# Requires: bash 3.2+, git

set -euo pipefail

OPT_DRY_RUN=false
OPT_YES=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) OPT_DRY_RUN=true ;;
    --yes)     OPT_YES=true ;;
    -h|--help) echo "USAGE: sync-constitution.sh [--dry-run] [--yes]" >&2; exit 0 ;;
    *) echo "Fehler: Unbekannte Option: $1" >&2; exit 1 ;;
  esac
  shift
done

HOME_CONSTITUTION="${HOME}/constitution.md"

if [ ! -f "$HOME_CONSTITUTION" ]; then
  echo "ERROR: ~/constitution.md nicht gefunden — bitte zuerst erstellen." >&2
  exit 2
fi

CONST_VER=$(head -1 "$HOME_CONSTITUTION" | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' || true)
if [ -z "$CONST_VER" ]; then
  echo "ERROR: constitution.md hat keine Versionszeile (erwartet: # Constitution vX.Y.Z)" >&2
  exit 2
fi

echo "Sync constitution ${CONST_VER} -> Level-1-Workspaces"
echo "$(printf '=%.0s' {1..50})"

ws_get_status() {
  local ws="$1"
  local ws_const="${ws}/constitution.md"
  if [ -f "$ws_const" ]; then
    local ws_ver
    ws_ver=$(head -1 "$ws_const" | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' || true)
    if [ "${ws_ver:-}" = "$CONST_VER" ]; then
      echo "ALREADY UP-TO-DATE"
    else
      echo "WOULD UPDATE (${ws_ver:-?} -> ${CONST_VER})"
    fi
  else
    echo "WOULD CREATE"
  fi
}

HAS_WORKSPACES=false
while IFS= read -r ws; do
  [ -d "${ws}/.git" ] || continue
  HAS_WORKSPACES=true
  ws_short="${ws/#$HOME/~}"
  status=$(ws_get_status "$ws")
  echo "  ${status}: ${ws_short}"
done < <(find "$HOME" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

if ! $HAS_WORKSPACES; then
  echo "Keine Level-1-Workspaces gefunden."
  exit 0
fi

echo ""

if $OPT_DRY_RUN; then
  echo "[DRY-RUN] Keine Aenderungen vorgenommen."
  exit 0
fi

if ! $OPT_YES; then
  printf "Fortfahren? Proceed? [y/N]: "
  read -r answer
  case "$answer" in
    [yYjJ]) ;;
    *) echo "Abgebrochen."; exit 0 ;;
  esac
fi

UPDATED=0
SKIPPED=0
ALREADY=0

while IFS= read -r ws; do
  [ -d "${ws}/.git" ] || continue
  ws_short="${ws/#$HOME/~}"
  status=$(ws_get_status "$ws")

  if [ "$status" = "ALREADY UP-TO-DATE" ]; then
    echo "  ALREADY UP-TO-DATE: ${ws_short}"
    ALREADY=$((ALREADY + 1))
    continue
  fi

  if git -C "$ws" status --porcelain 2>/dev/null | grep -q .; then
    echo "  WARN: ${ws_short} hat uncommittete Aenderungen -- uebersprungen"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if ! cp "$HOME_CONSTITUTION" "${ws}/constitution.md" 2>/dev/null; then
    echo "  ERROR: Kopieren fehlgeschlagen: ${ws_short}" >&2
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  git -C "$ws" add constitution.md >/dev/null 2>&1
  git -C "$ws" commit -m "chore: sync constitution to ${CONST_VER}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" >/dev/null 2>&1 || true

  echo "  UPDATED: ${ws_short} (${CONST_VER})"
  UPDATED=$((UPDATED + 1))
done < <(find "$HOME" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

echo ""
echo "$(printf '=%.0s' {1..50})"
echo "  Fertig: UPDATED=${UPDATED}  SKIPPED=${SKIPPED}  ALREADY=${ALREADY}"

[ "$SKIPPED" -gt 0 ] && exit 1
exit 0
