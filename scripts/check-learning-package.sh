#!/usr/bin/env bash
# Prueft Struktur, Pruefsumme und Ausschlussregeln eines Lernreihen-ZIPs.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_SCRIPT="${SCRIPT_DIR}/package-learning-series.sh"
PACKAGE_PATH=""
CHECKSUM_PATH=""
SELF_TEST=0

usage() {
  cat <<'USAGE'
Usage: check-learning-package.sh [--checksum FILE] ZIP
       check-learning-package.sh --self-test

Prueft ein Lernreihen-ZIP auf genau einen Paket-Root, die Startanleitungen,
Manifest, SHA-256, ausgeschlossene Git-/Build-/IDE-Artefakte und offensichtliche
Secrets. --self-test erzeugt und prueft ein minimales Testpaket.

Options:
  --checksum FILE  Abweichende SHA-256-Datei; Standard: ZIP.sha256
  --self-test      Minimales Paket erzeugen und vollstaendig pruefen
  -h, --help       Hilfe anzeigen
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --checksum)
      [ "$#" -ge 2 ] || { echo "ERROR: --checksum braucht einen Wert" >&2; exit 2; }
      CHECKSUM_PATH="$2"
      shift 2
      ;;
    --self-test)
      SELF_TEST=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "ERROR: unbekannte Option: $1" >&2
      exit 2
      ;;
    *)
      [ -z "$PACKAGE_PATH" ] || { echo "ERROR: nur ein ZIP-Pfad ist erlaubt" >&2; exit 2; }
      PACKAGE_PATH="$1"
      shift
      ;;
  esac
done

require_tool() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: benoetigtes Werkzeug fehlt: $1" >&2; exit 1; }
}

check_package() {
  local package="$1" checksum="$2"
  local work_dir entries roots root manifest

  [ -f "$package" ] || { echo "ERROR: ZIP nicht gefunden: $package" >&2; return 1; }
  [ -f "$checksum" ] || { echo "ERROR: SHA-256-Datei nicht gefunden: $checksum" >&2; return 1; }

  (
    cd -- "$(dirname -- "$checksum")"
    shasum -a 256 -c "$(basename -- "$checksum")"
  )

  entries="$(unzip -Z1 "$package")"
  [ -n "$entries" ] || { echo "ERROR: ZIP ist leer" >&2; return 1; }
  if grep -Eq '(^/|(^|/)\.\.(/|$))' <<< "$entries"; then
    echo "ERROR: ZIP enthaelt unsichere absolute oder aufsteigende Pfade" >&2
    return 1
  fi

  roots="$(printf '%s\n' "$entries" | awk -F/ 'NF > 1 && $1 != "" {print $1}' | sort -u)"
  [ "$(printf '%s\n' "$roots" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ] || {
    echo "ERROR: ZIP muss genau einen Paket-Root enthalten" >&2
    return 1
  }
  root="$(printf '%s\n' "$roots" | sed -n '1p')"

  for required in START-HERE-FUER-LERNENDE.md GIT-START-FUER-LERNENDE.md INSTITUTIONELLES-GIT-HOSTING.md PACKAGING-MANIFEST.txt; do
    grep -Fxq "${root}/${required}" <<< "$entries" || {
      echo "ERROR: verbindliche Paketdatei fehlt: ${required}" >&2
      return 1
    }
  done

  if grep -Eq '(^|/)(\.git|bin|obj|build|node_modules|\.vs|\.idea)(/|$)|(^|/)settings\.local\.json$|(^|/)\.vscode/(settings\.json|c_cpp_properties\.json)$' <<< "$entries"; then
    echo "ERROR: ZIP enthaelt ausgeschlossene Git-, Build-, IDE- oder lokale Einstellungsartefakte" >&2
    return 1
  fi

  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' RETURN
  unzip -q "$package" -d "$work_dir"
  manifest="${work_dir}/${root}/PACKAGING-MANIFEST.txt"
  grep -Eq '^Git data included: no ' "$manifest" || { echo "ERROR: Manifest bestaetigt Git-Ausschluss nicht" >&2; return 1; }
  grep -Eq '^Original remotes included: no$' "$manifest" || { echo "ERROR: Manifest bestaetigt Remote-Ausschluss nicht" >&2; return 1; }
  grep -Eq '^Start here after extracting: START-HERE-FUER-LERNENDE\.md$' "$manifest" || { echo "ERROR: Manifest nennt die primaere Startdatei nicht" >&2; return 1; }
  grep -Eq '^Institutional hosting guide: INSTITUTIONELLES-GIT-HOSTING\.md$' "$manifest" || { echo "ERROR: Manifest nennt den Hosting-Leitfaden nicht" >&2; return 1; }

  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks_args=(dir "${work_dir}/${root}" --no-banner --redact)
    if [ -f "${SCRIPT_DIR}/templates/gitleaks.toml" ]; then
      gitleaks_args+=(--config "${SCRIPT_DIR}/templates/gitleaks.toml")
    fi
    gitleaks "${gitleaks_args[@]}" >/dev/null
  else
    echo "WARN: gitleaks nicht verfuegbar; Secret-Scan uebersprungen" >&2
  fi

  rm -rf "$work_dir"
  trap - RETURN
  echo "PASS: Lernpaket ist strukturell und gegen die Ausschlussregeln geprueft: $package"
}

self_test() {
  local work_dir source_dir output_dir package
  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' RETURN
  source_dir="${work_dir}/SecureExampleProjects"
  output_dir="${work_dir}/out"
  mkdir -p "${source_dir}/docs/learning-units" "${source_dir}/src"
  printf '# Start\n' > "${source_dir}/docs/learning-units/START-HERE-FUER-LERNENDE.md"
  printf '# Git Start\n' > "${source_dir}/docs/learning-units/GIT-START-FUER-LERNENDE.md"
  printf '# Institutional Git Hosting\n' > "${source_dir}/docs/learning-units/INSTITUTIONELLES-GIT-HOSTING.md"
  printf '# Example\n' > "${source_dir}/README.md"
  printf 'example\n' > "${source_dir}/src/example.txt"

  bash "$PACKAGE_SCRIPT" \
    --source-dir "$source_dir" \
    --series-name "Secure Example" \
    --output-dir "$output_dir"
  package="$(find "$output_dir" -maxdepth 1 -type f -name '*.zip' -print | sed -n '1p')"
  [ -n "$package" ] || { echo "ERROR: Self-Test hat kein ZIP erzeugt" >&2; return 1; }
  check_package "$package" "${package}.sha256"
  rm -rf "$work_dir"
  trap - RETURN
  echo "PASS: check-learning-package.sh --self-test"
}

require_tool shasum
require_tool unzip

if [ "$SELF_TEST" -eq 1 ]; then
  [ -z "$PACKAGE_PATH" ] || { echo "ERROR: --self-test akzeptiert keinen ZIP-Pfad" >&2; exit 2; }
  self_test
  exit 0
fi

[ -n "$PACKAGE_PATH" ] || { echo "ERROR: ZIP-Pfad oder --self-test erforderlich" >&2; usage >&2; exit 2; }
[ -n "$CHECKSUM_PATH" ] || CHECKSUM_PATH="${PACKAGE_PATH}.sha256"
check_package "$PACKAGE_PATH" "$CHECKSUM_PATH"
