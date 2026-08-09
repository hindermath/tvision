#!/usr/bin/env bash
# sync-home.sh — Synchronisiert die dauerhafte Level-0-Quelle nach ~/
# Verwendung: bash ~/scripts/sync-home.sh [--pull] [--commit] [--check-only] [--dry-run] [--runtime-only] [--force]
#
# --pull     : git pull in der Level-0-Quelle vor dem Sync (Standard: ja)
# --commit   : git commit in ~/ nach dem Sync (Standard: ja)
# --dry-run  : Nur anzeigen, was gemacht würde
# --check-only: Pull-frei und schreibfrei auf Drift pruefen
# --runtime-only: Nur homeRuntime ohne Pull, Commit oder Git-Konfiguration anwenden
# --force    : Nach manueller Pruefung verwaltete Konflikte ueberschreiben
# --no-pull  : Kein git pull (nur kopieren)
# --no-commit: Kein automatischer Commit in ~/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo-Klon: ein Verzeichnis über scripts/
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOME_DIR="${HOME}"

# A copied Home script resolves the permanent source through the shared contract.
if [ "$REPO_DIR" = "$HOME_DIR" ]; then
  # shellcheck source=scripts/lib/resolve-home-baseline-source.sh
  source "${SCRIPT_DIR}/lib/resolve-home-baseline-source.sh"
  REPO_DIR="$(resolve_hb_source_repository "${BASH_SOURCE[0]}" 1)"
fi

if [ "$SCRIPT_DIR" = "${HOME_DIR}/scripts" ] && [ -f "${REPO_DIR}/scripts/sync-home.sh" ]; then
  exec bash "${REPO_DIR}/scripts/sync-home.sh" "$@"
fi

OPT_PULL=true
OPT_COMMIT=true
OPT_DRY_RUN=false
OPT_CHECK_ONLY=false
OPT_FORCE=false
OPT_RUNTIME_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --pull)      OPT_PULL=true ;;
    --no-pull)   OPT_PULL=false ;;
    --commit)    OPT_COMMIT=true ;;
    --no-commit) OPT_COMMIT=false ;;
    --dry-run)   OPT_DRY_RUN=true; OPT_PULL=false; OPT_COMMIT=false ;;
    --check-only) OPT_CHECK_ONLY=true; OPT_PULL=false; OPT_COMMIT=false ;;
    --runtime-only) OPT_RUNTIME_ONLY=true ;;
    --force)      OPT_FORCE=true ;;
    *) echo "Unbekannte Option: $1" >&2; exit 2 ;;
  esac
  shift
done

if $OPT_RUNTIME_ONLY; then
  OPT_PULL=false
  OPT_COMMIT=false
  if $OPT_FORCE; then
    echo "Fehler: --runtime-only und --force sind nicht kombinierbar." >&2
    echo "Error: --runtime-only and --force cannot be combined." >&2
    exit 2
  fi
fi

echo "╔══════════════════════════════════════════════════╗"
echo "║  sync-home — Home-Baseline Sync                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Quelle : ${REPO_DIR}"
echo "  Ziel   : ${HOME_DIR}"
echo "  Pull   : ${OPT_PULL}"
echo "  Commit : ${OPT_COMMIT}"
echo "  Dry-run: ${OPT_DRY_RUN}"
echo "  Check  : ${OPT_CHECK_ONLY}"
echo "  Force  : ${OPT_FORCE}"
echo "  Runtime: ${OPT_RUNTIME_ONLY}"
echo ""

if [ "$HOME_DIR" = "/home/adedev" ] && { [ -f /.dockerenv ] || [ -f /run/.containerenv ]; } && \
   ! $OPT_DRY_RUN && ! $OPT_CHECK_ONLY && ! $OPT_RUNTIME_ONLY; then
  echo "Fehler: Schreibender sync-home-Lauf in der ABS-DD-Sandbox ist gesperrt." >&2
  echo "Error: Writing sync-home runs are blocked inside the ABS-DD sandbox." >&2
  echo "Die Level-0-Referenz direkt unter ~/home-baseline-source verwenden und den Home-Sync auf dem Host ausfuehren." >&2
  exit 2
fi

command -v python3 >/dev/null 2>&1 || {
  echo "Fehler: python3 wird fuer den manifestgesteuerten Home-Sync benoetigt." >&2
  exit 2
}

SYNC_HELPER="${REPO_DIR}/scripts/lib/home-sync-files.py"
SYNC_MANIFEST="${REPO_DIR}/scripts/config/home-sync-manifest.json"
SYNC_STATE="${HOME_DIR}/.home-baseline/home-sync-state.json"
SYNC_RESULT="${HOME_DIR}/.home-baseline/home-sync-result.json"

[ -f "$SYNC_HELPER" ] || { echo "Fehler: Home-Sync-Helfer fehlt: ${SYNC_HELPER}" >&2; exit 2; }
[ -f "$SYNC_MANIFEST" ] || { echo "Fehler: Home-Sync-Manifest fehlt: ${SYNC_MANIFEST}" >&2; exit 2; }

# ── 1. git pull ──────────────────────────────────────────────────────────────
if $OPT_PULL; then
  echo "→ git pull in ${REPO_DIR}..."
  git -C "${REPO_DIR}" pull --ff-only
  echo ""
fi

ensure_gitconfig_baseline() {
  if $OPT_DRY_RUN; then
    echo "  [dry-run] ~/.gitconfig Baseline-Einstellungen prüfen / check baseline settings"
    return
  fi

  touch "${HOME_DIR}/.gitconfig"
  if grep -qF 'WICHTIG / IMPORTANT: Name und E-Mail MÜSSEN geändert werden!' "${HOME_DIR}/.gitconfig" 2>/dev/null; then
    tmp_gitconfig="$(mktemp)"
    cat > "$tmp_gitconfig" <<'EOF'
; ============================================================
; Lokale Git-Konfiguration / Local git configuration
;
; user.name und user.email werden lokal durch setup-git-identity.*
; gepflegt. sync-home.* überschreibt diese Identität nicht.
;
; user.name and user.email are maintained locally by
; setup-git-identity.*. sync-home.* does not overwrite them.
; ============================================================
EOF
    awk '
      BEGIN { skip = 0; done = 0 }
      /^; ============================================================$/ && done == 0 { skip = 1; next }
      skip == 1 && /^; ============================================================$/ { skip = 0; done = 1; next }
      skip == 0 { print }
    ' "${HOME_DIR}/.gitconfig" >> "$tmp_gitconfig"
    mv "$tmp_gitconfig" "${HOME_DIR}/.gitconfig"
  fi

  git config --global init.defaultBranch main
  git config --global core.autocrlf input
  git config --global pull.rebase true

  if ! grep -qF 'gitdir:~/home-baseline-source/' "${HOME_DIR}/.gitconfig" 2>/dev/null; then
    printf '\n[includeIf "gitdir:~/home-baseline-source/"]\n\tpath = ~/.gitconfig.d/home-baseline.inc\n' >> "${HOME_DIR}/.gitconfig"
  fi

  echo "  ✓ ~/.gitconfig Baseline-Einstellungen geprüft / baseline settings checked"
}

echo "→ Dateien synchronisieren..."

sync_args=(
  sync
  --repo "$REPO_DIR"
  --home "$HOME_DIR"
  --manifest "$SYNC_MANIFEST"
  --state "$SYNC_STATE"
  --result "$SYNC_RESULT"
)
$OPT_DRY_RUN && sync_args+=(--dry-run)
$OPT_CHECK_ONLY && sync_args+=(--check-only)
$OPT_FORCE && sync_args+=(--force)

set +e
python3 "$SYNC_HELPER" "${sync_args[@]}"
sync_status=$?
set -e

if $OPT_CHECK_ONLY; then
  exit "$sync_status"
fi
if [ "$sync_status" -ne 0 ]; then
  exit "$sync_status"
fi

if $OPT_RUNTIME_ONLY; then
  echo ""
  echo "✓ Home Runtime synchronisiert / Home Runtime synchronized."
  exit 0
fi

echo ""

# ── 3. ~/.gitconfig.d/ Bootstrap ─────────────────────────────────────────────
gitconfig_d="${HOME}/.gitconfig.d"
placeholder="${gitconfig_d}/home-baseline.inc"
if $OPT_DRY_RUN; then
  if [ -d "$gitconfig_d" ]; then
    echo "  [dry-run] ~/.gitconfig.d/ bereits vorhanden — Inhalt wird nicht überschrieben / already exists — content preserved"
  else
    echo "  [dry-run] ~/.gitconfig.d/ würde erstellt mit home-baseline.inc / would be created with home-baseline.inc"
  fi
elif [ -d "$gitconfig_d" ]; then
  echo "  → ~/.gitconfig.d/ bereits vorhanden — Inhalt wird nicht überschrieben / already exists — content preserved"
else
  mkdir -p "$gitconfig_d"
  printf '# home-baseline workspace git configuration\n# Hier workspace-spezifische git-Einstellungen eintragen:\n# [user]\n#   email = work@example.com\n' > "$placeholder"
  echo "  ✓ ~/.gitconfig.d/ erstellt mit home-baseline.inc / created with home-baseline.inc"
fi

ensure_gitconfig_baseline

echo ""

# ── 4. Globale Git-Identität reparieren ──────────────────────────────────────
identity_script="${HOME_DIR}/scripts/setup-git-identity.sh"
if $OPT_DRY_RUN; then
  echo "  [dry-run] bash ~/scripts/setup-git-identity.sh --auto"
elif [ -f "$identity_script" ]; then
  echo "→ Git-Identität in ~/.gitconfig prüfen und reparieren..."
  bash "$identity_script" --auto
  echo ""
else
  echo "Warnung: ~/scripts/setup-git-identity.sh nicht gefunden — Git-Identität nicht geprüft." >&2
  echo "Warning: ~/scripts/setup-git-identity.sh not found — git identity not checked." >&2
  echo ""
fi

# ── 5. git commit in ~/ ──────────────────────────────────────────────────────
if $OPT_COMMIT; then
  cd "${HOME_DIR}"

  # Falls ~/ noch kein Git-Repo ist, automatisch initialisieren
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "→ ~/ ist noch kein Git-Repository — initialisiere..."
    git init
    if [ -f "${HOME_DIR}/scripts/install-hooks.sh" ]; then
      bash "${HOME_DIR}/scripts/install-hooks.sh"
    fi
    echo "  ✓ Git-Repository und Hooks initialisiert."
    echo ""
  fi

  changed_paths=()
  while IFS= read -r -d '' path; do
    changed_paths+=("$path")
  done < <(python3 "$SYNC_HELPER" emit-changed --result "$SYNC_RESULT")

  if [ -n "$(git status --porcelain -- .gitconfig)" ]; then
    changed_paths+=(".gitconfig")
  fi

  commit_paths=()
  # Bash 3.2 treats an empty array expansion as an unbound variable under
  # `set -u`. Guard the loop so a real no-op remains a successful no-op.
  if [ "${#changed_paths[@]}" -gt 0 ]; then
    for path in "${changed_paths[@]}"; do
      if [ -e "${HOME_DIR}/${path}" ] || git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
        git add -A -- "$path"
        if ! git diff --cached --quiet -- "$path"; then
          commit_paths+=("$path")
        fi
      fi
    done
  fi

  if [ "${#commit_paths[@]}" -eq 0 ]; then
    echo "→ Keine verwalteten Änderungen in ~/ — kein Commit nötig."
  else
    REMOTE_SHA=$(git -C "${REPO_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unbekannt")
    git commit --only -m "chore: sync mit home-baseline @ ${REMOTE_SHA}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" -- "${commit_paths[@]}"
    echo "→ Commit in ~/ erstellt."
  fi
fi

echo ""
echo "✓ sync-home abgeschlossen."
