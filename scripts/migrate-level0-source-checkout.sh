#!/usr/bin/env bash
# Migrate the permanent Level-0 checkout through the canonical PowerShell engine.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE=""
TARGET="${HOME}/home-baseline-source"
CHECK_ONLY=0
DRY_RUN=0
FINALIZE=0
JSON=0
YES=0

usage() {
  cat <<'USAGE'
Verwendung / Usage: migrate-level0-source-checkout.sh [OPTIONEN]

  --source PFAD   Bestehender Checkout / existing checkout
  --target PFAD   Neuer Checkout / new checkout (default: ~/home-baseline-source)
  --check-only    Vollstaendiger Preflight / complete preflight
  --dry-run       Migration anzeigen / preview migration
  --finalize      Alten Kompatibilitaetslink entfernen / remove legacy link
  --yes           Rueckfrage fuer Schreib-/Finalize-Lauf bestaetigen / confirm write/finalize
  --json          Maschinenlesbaren Status ausgeben / emit JSON status
  --help, -h      Hilfe anzeigen / show help
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="${2:?--source requires a path}"; shift ;;
    --target) TARGET="${2:?--target requires a path}"; shift ;;
    --check-only) CHECK_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --finalize) FINALIZE=1 ;;
    --yes) YES=1 ;;
    --json) JSON=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument / Unbekanntes Argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$CHECK_ONLY" -eq 1 ] && { [ "$DRY_RUN" -eq 1 ] || [ "$FINALIZE" -eq 1 ]; }; then
  printf '%s\n' '--check-only cannot be combined with --dry-run or --finalize.' >&2
  exit 2
fi
command -v pwsh >/dev/null 2>&1 || {
  printf '%s\n' 'PowerShell 7 (pwsh) is required.' >&2
  exit 2
}

args=(-NoProfile -File "${SCRIPT_DIR}/migrate-level0-source-checkout.ps1" -Target "$TARGET")
[ -n "$SOURCE" ] && args+=(-Source "$SOURCE")
[ "$CHECK_ONLY" -eq 1 ] && args+=(-CheckOnly)
[ "$DRY_RUN" -eq 1 ] && args+=(-WhatIf)
[ "$FINALIZE" -eq 1 ] && args+=(-Finalize)
[ "$JSON" -eq 1 ] && args+=(-Json)
[ "$YES" -eq 0 ] || args+=('-Confirm:$false')
exec pwsh "${args[@]}"
