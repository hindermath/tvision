#!/usr/bin/env bash
# propagate-learning-series.sh
# Propagiert Lernreihen-Material aus Level-0 (~/home-baseline-source/docs/learning-units)
# in die zugehoerigen Level-1- und Level-2-Repos einer Lernreihe.
#
# Propagates learning-series material from Level-0 into the matching Level-1 and
# Level-2 repositories of a learning series.
#
# Kernprinzipien / Core principles:
#   - Registry-gesteuerte Repo-Erkennung ueber ~/.home-baseline/level2-repository-registry.json;
#     Filter per Serien-Praefix (Standard: SecureCaseTracker). Keine hartcodierten Repo-Pfade.
#   - Serien-gebundene Quell-Auswahl: nur Dateien der gewaehlten Serie werden kopiert;
#     andere Reihen (z. B. Secure InventoryHub) bleiben unberuehrt.
#   - Level-2 haelt Root-Intakes UND docs/learning-units/ synchron; Level-1 nur docs/learning-units/.
#   - Idempotent: Kopie ueberschreibt inhaltsgleich, nur echte Aenderungen erzeugen Git-Commits.
#   - Nicht destruktiv: es werden keine Zieldateien geloescht.
#   - Dry-Run: --dry-run zeigt alle geplanten Aenderungen ohne zu schreiben.
#
# Verwendung / Usage:
#   bash ~/scripts/propagate-learning-series.sh --dry-run
#   bash ~/scripts/propagate-learning-series.sh
#   bash ~/scripts/propagate-learning-series.sh --no-push
#   bash ~/scripts/propagate-learning-series.sh --series SecureCaseTracker --home-dir ~
#
# Sichere-Entwicklung-Kurzregeln (Bash): Variablen gequotet, `--` End-of-Options,
# kein `eval` auf nicht vertrauenswuerdigem Input, `set -euo pipefail`.

set -euo pipefail

# --- Konfiguration / Configuration --------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LEVEL0_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_UNITS="${LEVEL0_DIR}/docs/learning-units"

HOME_DIR="$(cd -- ~ && pwd)"
SERIES="SecureCaseTracker"        # Registry-/Verzeichnis-Token (ohne Bindestrich)
FILE_SERIES=""                    # Datei-Praefix (mit Bindestrich); leer => aus SERIES ableiten
REGISTRY="${HOME_DIR}/.home-baseline/level2-repository-registry.json"

DRY_RUN=0
NO_PUSH=0
VERBOSE=0
REPOS_CHANGED=0
REPOS_TOTAL=0
FILES_CHANGED=0
FILES_SKIPPED_NEWER=0
REPOS_SKIPPED=0
PUSH_FAILURES=0

# --- Parameter / Arguments ----------------------------------------------------

while [ $# -gt 0 ]; do
  case "${1:-}" in
    --dry-run)   DRY_RUN=1 ;;
    --no-push)   NO_PUSH=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --series)    SERIES="${2:?--series benoetigt einen Wert}"; shift ;;
    --file-prefix) FILE_SERIES="${2:?--file-prefix benoetigt einen Wert}"; shift ;;
    --home-dir)  HOME_DIR="$(cd -- "${2:?--home-dir benoetigt einen Wert}" && pwd)"; shift ;;
    --registry)  REGISTRY="${2:?--registry benoetigt einen Wert}"; shift ;;
    --help|-h)
      cat <<USAGE
Verwendung / Usage: $(basename -- "$0") [OPTIONEN]

  --dry-run        Vorschau ohne Schreiben / Preview without writing
  --no-push        Committen ohne Push / Commit without pushing
  --series NAME    Serien-Praefix (Standard: SecureCaseTracker)
  --home-dir DIR   Basisverzeichnis fuer Repos (Standard: ~)
  --registry PFAD  Registry-Datei (Standard: ~/.home-baseline/level2-repository-registry.json)
  --verbose,-v     Ausfuehrliche Ausgabe / Verbose output

Quelle / Source: ${SRC_UNITS}
USAGE
      exit 0
      ;;
    --) shift; break ;;
    --*) echo "Fehler / Error: Unbekannte Option / Unknown option: $1" >&2; exit 2 ;;
    *)  echo "Fehler / Error: Unerwartetes Argument / Unexpected argument: $1" >&2; exit 2 ;;
  esac
  shift
done

# Datei-Praefix aus SERIES ableiten, falls nicht gesetzt (SecureX -> Secure-X).
# Repos heissen z. B. "SecureCaseTracker", die Dateien "Secure-CaseTracker".
if [ -z "$FILE_SERIES" ]; then
  case "$SERIES" in
    Secure-*) FILE_SERIES="$SERIES" ;;
    Secure?*) FILE_SERIES="Secure-${SERIES#Secure}" ;;
    *)        FILE_SERIES="$SERIES" ;;
  esac
fi

# --- Vorabpruefungen / Prerequisite checks ------------------------------------

if [ ! -d "$SRC_UNITS" ]; then
  echo "Fehler / Error: Quelle nicht gefunden / source not found: $SRC_UNITS" >&2
  exit 1
fi
if [ ! -f "$REGISTRY" ]; then
  echo "Fehler / Error: Registry nicht gefunden / registry not found: $REGISTRY" >&2
  exit 1
fi
for tool in python3 git; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Fehler / Error: $tool erforderlich / required." >&2; exit 1; }
done

# --- Ausgabe-Hilfen / Output helpers ------------------------------------------

info() { echo "→ $*"; }
ok()   { echo "✓ $*"; }
warn() { echo "⚠ $*"; }
plan() { if [ "$DRY_RUN" -eq 1 ]; then echo "  [DRY-RUN] $*"; else echo "  [OK] $*"; fi; }

# --- Quell-Dateimengen der Serie / Series source file sets --------------------
# Gibt relative Pfade (unter docs/learning-units) der zur Serie gehoerenden
# Dateien aus. InventoryHub bzw. andere Reihen sind ausgeschlossen, weil das
# Praefixmuster strikt an ${SERIES} bindet.

series_unit_files() {
  # Ausgeschlossen: dist/, presentations/ (unveraenderte Paketierungs-/Folienpfade)
  # Eingeschlossen: das gemeinsame Secure-Trader-Universum (Systemlandschaft) und
  # der geteilte Datensatz-Baum datasets/** (Generator + CSVs + schema.sql), damit
  # das Lernwerkzeug in jedem Level-1/Level-2-Repo lauffaehig vorliegt.
  # datasets/* + datasets/*/* deckt den zweistufigen datasets-Baum ab
  # (bash-3-kompatibel, ohne globstar).
  ( cd -- "$SRC_UNITS" && {
      shopt -s nullglob
      local f
      for f in Lastenheft_"${FILE_SERIES}"*.md "${FILE_SERIES}"*.md \
               Rahmenlehrplan-Lernfeld-Mapping.md \
               IT-Berufe-"${FILE_SERIES}"-Mapping.md \
               Secure-Trader-*.md \
               START-HERE-FUER-LERNENDE.md \
               GIT-START-FUER-LERNENDE.md \
               INSTITUTIONELLES-GIT-HOSTING.md \
               lernbegleiter/"${FILE_SERIES}"*.Lernbegleiter.md \
               templates/*.md \
               datasets/* datasets/*/*; do
        [ -f "$f" ] && printf '%s\n' "$f"
      done
    } )
}

shared_root_guides() {
  printf '%s\n' START-HERE-FUER-LERNENDE.md GIT-START-FUER-LERNENDE.md INSTITUTIONELLES-GIT-HOSTING.md
}

# Nur die Root-Intakes (fuer Level-2 zusaetzlich in die Repo-Wurzel gespiegelt)
series_root_intakes() {
  ( cd -- "$SRC_UNITS" && {
      shopt -s nullglob
      local f
      for f in Lastenheft_"${FILE_SERIES}"*.md; do
        [ -f "$f" ] && printf '%s\n' "$f"
      done
    } )
}

# --- Registry-Erkennung / Registry discovery ----------------------------------
# Gibt "LEVEL<TAB>ABS_PFAD<TAB>EXPECTED_REMOTE" fuer passende Repos aus.
# Level-1 zuerst, dann Level-2.

discover_repos() {
  python3 - "$REGISTRY" "$SERIES" "$HOME_DIR" <<'PYEOF'
import json, sys, os
reg, series, home = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(reg, encoding="utf-8"))
repos = data.get("repositories", []) if isinstance(data, dict) else data
rows = []
level1_slugs = {
    "securecasetracker": "secure-casetracker-baseline",
    "secureorderdesk": "secure-orderdesk-baseline",
    "secureserviceharvester": "secure-serviceharvester",
}
for e in repos:
    if not isinstance(e, dict):
        continue
    path = e.get("path", "")
    if series.lower() not in path.lower():
        continue
    level = e.get("level", 0)
    abspath = path if os.path.isabs(path) else os.path.join(home, path)
    if int(level) == 1:
        slug = level1_slugs.get(series.lower(), "")
    else:
        slug = os.path.basename(abspath).lower()
    if not slug:
        continue
    expected = f"https://github.com/hindermath/{slug}.git"
    rows.append((int(level), abspath, expected))
rows.sort(key=lambda r: (r[0], r[1]))
for level, abspath, expected in rows:
    print(f"{level}\t{abspath}\t{expected}")
PYEOF
}

normalize_github_remote() {
  local remote="${1%/}"
  remote="${remote%.git}"
  case "$remote" in
    git@github.com:*) remote="https://github.com/${remote#git@github.com:}" ;;
    ssh://git@github.com/*) remote="https://github.com/${remote#ssh://git@github.com/}" ;;
  esac
  printf '%s\n' "$remote" | tr '[:upper:]' '[:lower:]'
}

source_epoch_for() {
  local rel="$1"
  if ! git -C "$LEVEL0_DIR" ls-files --error-unmatch "docs/learning-units/${rel}" >/dev/null 2>&1 \
      || ! git -C "$LEVEL0_DIR" diff --quiet -- "docs/learning-units/${rel}"; then
    date +%s
  else
    git -C "$LEVEL0_DIR" log -1 --format=%ct -- "docs/learning-units/${rel}" 2>/dev/null || printf '0\n'
  fi
}

target_is_newer() {
  local rel="$1" repo="$2" target_rel="$3" dst="$4"
  local source_epoch target_epoch
  [ -f "$dst" ] || return 1
  cmp -s -- "${SRC_UNITS}/${rel}" "$dst" && return 1
  source_epoch="$(source_epoch_for "$rel")"
  target_epoch="$(git -C "$repo" log -1 --format=%ct -- "$target_rel" 2>/dev/null || printf '0')"
  source_epoch="${source_epoch:-0}"
  target_epoch="${target_epoch:-0}"
  [ "$target_epoch" -gt "$source_epoch" ]
}

preflight_newer_targets() {
  local level="$1" repo="$2" rel newer=0
  while IFS= read -r rel; do
    if target_is_newer "$rel" "$repo" "docs/learning-units/${rel}" "${repo}/docs/learning-units/${rel}"; then
      warn "Uebersprungen (Zieldatei neuer) / skipped (target newer): $(basename -- "$repo")/docs/learning-units/${rel}"
      newer=$((newer + 1))
    fi
  done < <(series_unit_files)
  if [ "$level" = "2" ]; then
    while IFS= read -r rel; do
      if target_is_newer "$rel" "$repo" "$rel" "${repo}/${rel}"; then
        warn "Uebersprungen (Zieldatei neuer) / skipped (target newer): $(basename -- "$repo")/${rel}"
        newer=$((newer + 1))
      fi
    done < <(series_root_intakes)
  fi
  while IFS= read -r rel; do
    if target_is_newer "$rel" "$repo" "$rel" "${repo}/${rel}"; then
      warn "Uebersprungen (Zieldatei neuer) / skipped (target newer): $(basename -- "$repo")/${rel}"
      newer=$((newer + 1))
    fi
  done < <(shared_root_guides)
  FILES_SKIPPED_NEWER=$((FILES_SKIPPED_NEWER + newer))
  [ "$newer" -eq 0 ]
}

# --- Datei-Kopie / File copy --------------------------------------------------
# copy_one <rel-src-unter-SRC_UNITS> <ziel-basisdir> <repo> <ziel-relpfad>
# Legt Zielunterordner an, kopiert nur bei Inhaltsunterschied.

copy_one() {
  local rel="$1" destbase="$2" repo="$3" target_rel="$4"
  local src="${SRC_UNITS}/${rel}"
  local dst="${destbase}/${rel}"
  if [ -f "$dst" ] && cmp -s -- "$src" "$dst"; then
    return 1  # unveraendert
  fi

  if target_is_newer "$rel" "$repo" "$target_rel" "$dst"; then
    return 2
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p -- "$(dirname -- "$dst")"
    cp -- "$src" "$dst"
  fi
  return 0    # geaendert
}

ensure_readme_start_link() {
  local repo="$1"
  local readme="${repo}/README.md"
  local marker='<!-- home-baseline-learner-start -->'

  if [ -f "$readme" ] && grep -Fq "$marker" "$readme"; then
    return 1
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    cat >> "$readme" <<'EOF'

<!-- home-baseline-learner-start -->
## Start fuer Lernende / Start for Learners

Beginne mit [`START-HERE-FUER-LERNENDE.md`](START-HERE-FUER-LERNENDE.md), bevor
du Unit 00 oder einen KI-Agenten startest.

*Start with [`START-HERE-FUER-LERNENDE.md`](START-HERE-FUER-LERNENDE.md) before
starting unit 00 or an AI agent.*
EOF
  fi
  return 0
}

ensure_readme_guiding_principle() {
  local repo="$1"
  local readme="${repo}/README.md"
  local marker='<!-- include-everyone-guiding-principle -->'
  local block_file tmp_file

  [ -f "$readme" ] || return 1
  grep -Fq "$marker" "$readme" && return 1

  if [ "$DRY_RUN" -eq 0 ]; then
    block_file="$(mktemp)"
    tmp_file="$(mktemp)"
    cat > "$block_file" <<'EOF'
<!-- include-everyone-guiding-principle -->
> **Leitsatz:** `Programmierung #include<everyone>`.
>
> **Guiding principle:** `Programming #include<everyone>`.
>
> **DE:** Wir gestalten Software, Dokumentation und Lernwege inklusiv und
> barrierefrei. WCAG 2.2 AA, Tastaturbedienung, Screenreader- und
> Texttauglichkeit werden von Anfang an beruecksichtigt und geprueft.
>
> **EN:** We design software, documentation, and learning paths to be inclusive
> and accessible. WCAG 2.2 AA, keyboard operation, screen-reader support, and
> text usability are considered and verified from the start.
EOF

    if grep -Eq '^#[[:space:]]+' "$readme"; then
      awk -v block_file="$block_file" '
        !inserted && /^#[[:space:]]+/ {
          print
          print ""
          while ((getline line < block_file) > 0) print line
          close(block_file)
          inserted = 1
          next
        }
        { print }
      ' "$readme" > "$tmp_file"
    else
      cat "$block_file" > "$tmp_file"
      printf '\n' >> "$tmp_file"
      cat "$readme" >> "$tmp_file"
    fi

    mv "$tmp_file" "$readme"
    rm -f "$block_file"
  fi
  return 0
}

# --- Ein Repo verarbeiten / Process one repository ----------------------------

process_repo() {
  local level="$1" repo="$2" expected_remote="$3"
  REPOS_TOTAL=$((REPOS_TOTAL + 1))
  local name; name="$(basename -- "$repo")"

  if [ ! -d "$repo/.git" ]; then
    warn "Uebersprungen (kein Git-Repo) / skipped (not a git repo): $repo"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi

  # Leere/unborn Klone werden nicht automatisch ueberschrieben.
  if ! git -C "$repo" rev-parse --verify HEAD >/dev/null 2>&1; then
    warn "Uebersprungen (leerer/unborn Klon) / skipped (empty/unborn clone): $name"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi

  # Sauberkeit pruefen (nur ausserhalb Dry-Run relevant fuer Commit).
  if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
    warn "Uebersprungen (nicht sauberer Arbeitsbaum) / skipped (dirty tree): $name"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi
  # Nur ein bereits ausgechecktes main mit origin/main als Upstream ist erlaubt.
  local cur; cur="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
  if [ "$cur" != "main" ]; then
    warn "Uebersprungen (Branch ist nicht main) / skipped (branch is not main): $name ($cur)"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi
  local upstream; upstream="$(git -C "$repo" rev-parse --abbrev-ref 'main@{upstream}' 2>/dev/null || true)"
  if [ "$upstream" != "origin/main" ]; then
    warn "Uebersprungen (main folgt nicht origin/main) / skipped (main does not track origin/main): $name"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi
  local actual_remote
  actual_remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  if [ "$(normalize_github_remote "$actual_remote")" != "$(normalize_github_remote "$expected_remote")" ]; then
    warn "Uebersprungen (unerwartetes origin) / skipped (unexpected origin): $name ($actual_remote)"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    if ! git -C "$repo" fetch --dry-run origin >/dev/null 2>&1; then
      warn "Uebersprungen (Remote nicht erreichbar) / skipped (remote unavailable): $name"
      REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
      return
    fi
  else
    if ! git -C "$repo" fetch --quiet origin; then
      warn "Uebersprungen (fetch fehlgeschlagen) / skipped (fetch failed): $name"
      REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
      return
    fi
    if ! git -C "$repo" pull --ff-only --quiet origin main; then
      warn "Uebersprungen (kein Fast-forward) / skipped (not fast-forwardable): $name"
      REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
      return
    fi
  fi

  if ! preflight_newer_targets "$level" "$repo"; then
    warn "Uebersprungen (mindestens eine Zieldatei ist neuer) / skipped (at least one target file is newer): $name"
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
    return
  fi

  info "Repo (Level ${level}): ${name}"
  local changed=0 rel

  # 1) docs/learning-units/ synchronisieren (alle Ebenen)
  while IFS= read -r rel; do
    if copy_one "$rel" "${repo}/docs/learning-units" "$repo" "docs/learning-units/${rel}"; then
      changed=$((changed + 1)); FILES_CHANGED=$((FILES_CHANGED + 1))
      [ "$VERBOSE" -eq 1 ] && plan "docs/learning-units/${rel}"
    fi
  done < <(series_unit_files)

  # 2) Root-Intakes (nur Level-2)
  if [ "$level" = "2" ]; then
    while IFS= read -r rel; do
      if copy_one "$rel" "$repo" "$repo" "$rel"; then
        changed=$((changed + 1)); FILES_CHANGED=$((FILES_CHANGED + 1))
        [ "$VERBOSE" -eq 1 ] && plan "(root) ${rel}"
      fi
    done < <(series_root_intakes)
  fi

  # 3) Beide Einstiegsleitfaeden in die Repo-Wurzel spiegeln (Level 1 und 2).
  while IFS= read -r rel; do
    if copy_one "$rel" "$repo" "$repo" "$rel"; then
      changed=$((changed + 1)); FILES_CHANGED=$((FILES_CHANGED + 1))
      [ "$VERBOSE" -eq 1 ] && plan "(root) ${rel}"
    fi
  done < <(shared_root_guides)

  # 4) Root-README macht Leitsatz und Lernenden-Einstieg sichtbar, ohne Text zu ersetzen.
  if ensure_readme_guiding_principle "$repo"; then
    changed=$((changed + 1)); FILES_CHANGED=$((FILES_CHANGED + 1))
    [ "$VERBOSE" -eq 1 ] && plan "README.md (Leitsatz)"
  fi
  if ensure_readme_start_link "$repo"; then
    changed=$((changed + 1)); FILES_CHANGED=$((FILES_CHANGED + 1))
    [ "$VERBOSE" -eq 1 ] && plan "README.md (Lernenden-Einstieg)"
  fi

  if [ "$changed" -eq 0 ]; then
    ok "${name}: bereits aktuell / already up to date"
    return
  fi

  plan "${name}: ${changed} Datei(en) geaendert / file(s) changed"

  if [ "$DRY_RUN" -eq 1 ]; then
    return
  fi

  # Commit + Push
  git -C "$repo" add -A -- docs/learning-units >/dev/null 2>&1 || true
  [ "$level" = "2" ] && git -C "$repo" add -A -- 'Lastenheft_'"${FILE_SERIES}"'*.md' >/dev/null 2>&1 || true
  git -C "$repo" add -- README.md
  # Level-2 whitelist-style .gitignore files may ignore root Markdown by default.
  # Force only the canonical learner and hosting guides, never arbitrary ignored files.
  git -C "$repo" add -f -- START-HERE-FUER-LERNENDE.md GIT-START-FUER-LERNENDE.md INSTITUTIONELLES-GIT-HOSTING.md

  if git -C "$repo" diff --cached --quiet; then
    ok "${name}: keine Git-Aenderung nach Add / no staged change"
    return
  fi

  git -C "$repo" diff --cached --check
  git -C "$repo" commit -q -m "docs(learning-units): ${SERIES} Lernenden-Einstieg synchronisieren

Uebernimmt das kanonische ${SERIES}-Lernmaterial aus Level-0 (home-baseline),
einschliesslich Startanleitungen, Unit-00-Verweisen und Container-First-Gate."
  REPOS_CHANGED=$((REPOS_CHANGED + 1))
  ok "${name}: committet / committed"

  if [ "$NO_PUSH" -eq 1 ]; then
    info "${name}: Push uebersprungen (--no-push)"
  else
    if git -C "$repo" push --quiet origin main 2>/dev/null; then
      ok "${name}: gepusht / pushed"
    else
      warn "${name}: Push fehlgeschlagen / push failed"
      PUSH_FAILURES=$((PUSH_FAILURES + 1))
    fi
  fi
}

# --- Hauptlauf / Main run -----------------------------------------------------

echo "Lernreihen-Propagation / Learning-series propagation"
echo "Serie / Series:   ${SERIES}"
echo "Quelle / Source:  ${SRC_UNITS}"
echo "Registry:         ${REGISTRY}"
[ "$DRY_RUN" -eq 1 ] && echo "Modus / Mode:     DRY-RUN (keine Aenderungen / no changes)"
echo

file_count="$(series_unit_files | wc -l | tr -d ' ')"
lb_count="$(series_unit_files | grep -c '^lernbegleiter/' || true)"
info "Quell-Dateien der Serie / series source files: ${file_count} (davon Lernbegleiter / of which companions: ${lb_count})"
echo

found=0
while IFS=$'\t' read -r level repo expected_remote; do
  [ -z "${level:-}" ] && continue
  found=$((found + 1))
  process_repo "$level" "$repo" "$expected_remote"
  echo
done < <(discover_repos)

if [ "$found" -eq 0 ]; then
  warn "Keine Repos fuer Serie '${SERIES}' in der Registry gefunden."
  exit 1
fi

echo "---------------------------------------------"
echo "Repos gesamt / total:      ${REPOS_TOTAL}"
echo "Repos geaendert / changed: ${REPOS_CHANGED}"
echo "Repos uebersprungen / skipped: ${REPOS_SKIPPED}"
echo "Dateien geaendert / files: ${FILES_CHANGED}"
echo "Neuere Zieldateien bewahrt / newer target files preserved: ${FILES_SKIPPED_NEWER}"
echo "Push-Fehler / push failures: ${PUSH_FAILURES}"
[ "$DRY_RUN" -eq 1 ] && echo "(DRY-RUN: nichts geschrieben / nothing written)"
if [ "$REPOS_SKIPPED" -gt 0 ] || [ "$PUSH_FAILURES" -gt 0 ]; then
  warn "Lauf mit uebersprungenen Repos oder Push-Fehlern beendet / completed with skipped repos or push failures"
  exit 1
fi
ok "Fertig / Done."
