#!/usr/bin/env bash
# Validate the script inventory and render its central bilingual reference.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="."
CHECK_ONLY=0
DRY_RUN=0
JSON=0

usage() {
  cat <<'USAGE'
Verwendung / Usage: render-script-reference.sh [OPTIONEN]

  --repo PFAD     Zielrepository / target repository
  --check-only    Katalog und Drift pruefen / check catalog and drift
  --dry-run       Generierte Dokumente anzeigen / show generated documents
  --json          Maschinenlesbaren Status ausgeben / emit JSON status
  --help, -h      Hilfe anzeigen / show help

Exitcodes: 0 = aktuell/erfolgreich, 1 = Drift, 2 = Aufruf/Katalog/Toolingfehler.
Exit codes: 0 = current/success, 1 = drift, 2 = usage/catalog/tooling error.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:?--repo requires a path}"; shift ;;
    --check-only) CHECK_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --json) JSON=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument / Unbekanntes Argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$CHECK_ONLY" -eq 1 ] && [ "$DRY_RUN" -eq 1 ]; then
  printf '%s\n' '--check-only and --dry-run are mutually exclusive.' >&2
  exit 2
fi
command -v pwsh >/dev/null 2>&1 || {
  printf '%s\n' 'PowerShell 7 (pwsh) is required.' >&2
  exit 2
}

args=(-NoProfile -File "${SCRIPT_DIR}/render-script-reference.ps1" -Repo "$REPO")
[ "$CHECK_ONLY" -eq 1 ] && args+=(-CheckOnly)
[ "$DRY_RUN" -eq 1 ] && args+=(-WhatIf)
[ "$JSON" -eq 1 ] && args+=(-Json)
exec pwsh "${args[@]}"
