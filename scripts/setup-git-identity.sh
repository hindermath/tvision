#!/usr/bin/env bash
# setup-git-identity.sh
# Prüft und richtet die globale Git-Identität ein (Name + E-Mail).
# Erkennt Platzhalter-Werte und hilft beim automatischen oder interaktiven Einrichten.
#
# Git-Commits mit Platzhalter-Autor ("Your Name <your@email.example>") entstehen,
# wenn ~/.gitconfig nicht angepasst wurde. Dieses Skript behebt das dauerhaft.
#
# Verwendung / Usage:
#   bash ~/scripts/setup-git-identity.sh              # interaktiv, mit Auto-Erkennung
#   bash ~/scripts/setup-git-identity.sh --check-only # nur prüfen; Exit 1 bei Platzhalter
#   bash ~/scripts/setup-git-identity.sh --auto       # automatisch; kein Dialog
#   bash ~/scripts/setup-git-identity.sh --dry-run    # Vorschau ohne Schreiben
#
# Exit-Codes / Exit codes:
#   0  Identität konfiguriert (oder im --check-only-Modus: OK)
#   1  Platzhalter erkannt (--check-only) oder Einrichtung fehlgeschlagen
#   2  Ungültige Optionen

set -euo pipefail

PLACEHOLDER_NAME="Your Name"
PLACEHOLDER_EMAIL="your@email.example"

MODE="interactive"  # interactive | check-only | auto | dry-run

# --- Parameter parsen / Parse arguments ----------------------------------------

while [ $# -gt 0 ]; do
  case "${1:-}" in
    --check-only) MODE="check-only" ;;
    --auto)       MODE="auto" ;;
    --dry-run)    MODE="dry-run" ;;
    --help|-h)
      echo "Verwendung: $(basename "$0") [--check-only|--auto|--dry-run]"
      echo ""
      echo "Optionen / Options:"
      echo "  --check-only  Nur prüfen; Exit 1 wenn Platzhalter erkannt"
      echo "                Check only; exit 1 if placeholder detected"
      echo "  --auto        Automatische Erkennung ohne Dialog"
      echo "                Auto-detect identity without interactive prompt"
      echo "  --dry-run     Vorschau aller Änderungen ohne Schreiben"
      echo "                Preview all changes without writing"
      echo ""
      echo "Erkennungsquellen / Detection sources (in priority order):"
      echo "  1. gh api user  (GitHub-Profil-Name und E-Mail)"
      echo "  2. dscl / getent (macOS/Linux System-Benutzername)"
      echo "  3. git log       (Name/E-Mail aus vorhandenen Commits)"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    --*)
      echo "Fehler: Unbekannte Option: $1" >&2
      echo "Error: Unknown option: $1" >&2
      exit 2
      ;;
    *)
      echo "Fehler: Unerwartetes Argument: $1" >&2
      echo "Error: Unexpected argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

# --- Aktuelle Werte lesen / Read current values --------------------------------

current_name="$(git config --global user.name 2>/dev/null || true)"
current_email="$(git config --global user.email 2>/dev/null || true)"

# --- Platzhalter-Prüfung / Placeholder detection -------------------------------

is_placeholder=0
[ "$current_name" = "$PLACEHOLDER_NAME" ]  && is_placeholder=1
[ -z "$current_name" ]                     && is_placeholder=1
[ "$current_email" = "$PLACEHOLDER_EMAIL" ] && is_placeholder=1
[ -z "$current_email" ]                    && is_placeholder=1

if [ "$is_placeholder" -eq 0 ]; then
  echo "✓ Git-Identität konfiguriert: $current_name <$current_email>"
  exit 0
fi

if [ "$MODE" = "check-only" ]; then
  echo "✗ Git-Identität enthält Platzhalter:" >&2
  echo "    user.name  = ${current_name:-(leer / empty)}" >&2
  echo "    user.email = ${current_email:-(leer / empty)}" >&2
  echo "" >&2
  echo "  Behebung / Fix:" >&2
  echo "    bash ~/scripts/setup-git-identity.sh" >&2
  echo "" >&2
  echo "Error: Git identity is still at placeholder values." >&2
  exit 1
fi

echo "→ Git-Identität nicht konfiguriert oder enthält Platzhalter."

# --- Automatische Erkennung / Auto-detection -----------------------------------

detected_name=""
detected_email=""

# Quelle 1: gh API (zuverlässigste Quelle für GitHub-Nutzer)
# Source 1: gh API (most reliable source for GitHub users)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh_name="$(gh api user --jq '.name // ""' 2>/dev/null || true)"
  gh_email="$(gh api user --jq '.email // ""' 2>/dev/null || true)"
  [ -n "$gh_name" ]  && detected_name="$gh_name"
  # E-Mail kann in GitHub-Privatsphäre-Einstellungen verborgen sein
  # Email may be hidden by GitHub privacy settings
  if [ -n "$gh_email" ]; then
    detected_email="$gh_email"
  else
    # GitHub no-reply-Adresse als Fallback
    gh_id="$(gh api user --jq '.id' 2>/dev/null || true)"
    gh_login="$(gh api user --jq '.login' 2>/dev/null || true)"
    if [ -n "$gh_id" ] && [ -n "$gh_login" ]; then
      detected_email="${gh_id}+${gh_login}@users.noreply.github.com"
    fi
  fi
fi

# Quelle 2: macOS Verzeichnisdienst (RealName)
# Source 2: macOS Directory Service (RealName)
if [ -z "$detected_name" ] && command -v dscl >/dev/null 2>&1; then
  sys_name="$(dscl . read "/Users/$(whoami)" RealName 2>/dev/null | tail -1 | sed 's/^ //' || true)"
  [ -n "$sys_name" ] && detected_name="$sys_name"
fi

# Quelle 3: Linux GECOS-Feld (getent)
# Source 3: Linux GECOS field (getent)
if [ -z "$detected_name" ] && command -v getent >/dev/null 2>&1; then
  gecos="$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f5 | cut -d, -f1 || true)"
  [ -n "$gecos" ] && detected_name="$gecos"
fi

# Quelle 4: vorhandene Git-Commits (außerhalb des aktuellen Repos, falls vorhanden)
# Source 4: existing Git commits (excludes placeholder values)
if [ -z "$detected_name" ]; then
  # Suche in globalen git-config-gesetzten Werten über bestehende Repos (best-effort)
  # Dies funktioniert nur, wenn git log in einem Repo ausgeführt wird
  detected_name="$(git -C ~ log --format='%an' 2>/dev/null \
    | grep -v "^${PLACEHOLDER_NAME}$" \
    | grep -v "^$" \
    | head -1 || true)"
fi
if [ -z "$detected_email" ]; then
  detected_email="$(git -C ~ log --format='%ae' 2>/dev/null \
    | grep -v "^${PLACEHOLDER_EMAIL}$" \
    | grep -v "^$" \
    | head -1 || true)"
fi

# --- Auto-Modus: Abbruch wenn Erkennung unvollständig --------------------------

if [ "$MODE" = "auto" ]; then
  if [ -z "$detected_name" ] || [ -z "$detected_email" ]; then
    echo "Fehler: Git-Identität konnte nicht automatisch ermittelt werden." >&2
    echo "  Name : ${detected_name:-(nicht erkannt / not detected)}" >&2
    echo "  Email: ${detected_email:-(nicht erkannt / not detected)}" >&2
    echo "" >&2
    echo "  Tipp: 'gh auth login' ausführen oder Skript ohne --auto starten." >&2
    echo "Error: Could not auto-detect git identity. Run 'gh auth login' or use interactive mode." >&2
    exit 1
  fi
  new_name="$detected_name"
  new_email="$detected_email"
else
  # --- Interaktiver Dialog / Interactive prompt -----------------------------------
  echo ""
  if [ -n "$detected_name" ] || [ -n "$detected_email" ]; then
    echo "  Erkannte Werte / Detected values:"
    [ -n "$detected_name" ]  && printf "    Name : %s\n" "$detected_name"
    [ -n "$detected_email" ] && printf "    Email: %s\n" "$detected_email"
    echo ""
    echo "  Eingabe leer lassen = erkannten Wert übernehmen."
    echo "  Leave input empty to accept the detected value."
    echo ""
  fi

  if [ -n "$detected_name" ]; then
    printf "  Git-Name [%s]: " "$detected_name"
    read -r input_name
    new_name="${input_name:-$detected_name}"
  else
    printf "  Git-Name (Vor- und Nachname / full name): "
    read -r new_name
    while [ -z "$new_name" ]; do
      printf "  Name darf nicht leer sein / Name must not be empty: "
      read -r new_name
    done
  fi

  if [ -n "$detected_email" ]; then
    printf "  Git-E-Mail [%s]: " "$detected_email"
    read -r input_email
    new_email="${input_email:-$detected_email}"
  else
    printf "  Git-E-Mail: "
    read -r new_email
    while [ -z "$new_email" ]; do
      printf "  E-Mail darf nicht leer sein / Email must not be empty: "
      read -r new_email
    done
  fi
fi

# --- Vorschau / Schreiben / Preview and write ----------------------------------

echo ""
echo "  Git-Identität wird gesetzt / Setting git identity:"
printf "    user.name  = %s\n" "$new_name"
printf "    user.email = %s\n" "$new_email"
echo ""

if [ "$MODE" = "dry-run" ]; then
  echo "  [dry-run] Keine Änderungen vorgenommen / No changes made."
  exit 0
fi

git config --global user.name  "$new_name"
git config --global user.email "$new_email"

echo "✓ Globale Git-Identität gesetzt / Global git identity configured."
echo ""
echo "  Verifizierung / Verification:"
printf "    git config --global user.name  => %s\n" "$(git config --global user.name)"
printf "    git config --global user.email => %s\n" "$(git config --global user.email)"
