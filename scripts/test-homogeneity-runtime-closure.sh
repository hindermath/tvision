#!/usr/bin/env bash
# Validates fail-closed loading and a complete Homogeneity runtime package.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd -- "${SCRIPT_DIR}/.." && pwd)}"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_ROOT"' EXIT

mkdir -p "${TEMP_ROOT}/scripts/lib"
cp "${SCRIPT_DIR}/check-homogeneity.sh" "${TEMP_ROOT}/scripts/check-homogeneity.sh"
cp "${SCRIPT_DIR}/lib/hg-stats.sh" "${TEMP_ROOT}/scripts/lib/hg-stats.sh"

set +e
partial_output="$(bash "${TEMP_ROOT}/scripts/check-homogeneity.sh" --dry-run --no-patch "$REPO_ROOT" 2>&1)"
partial_exit=$?
set -e
if [ "$partial_exit" -ne 2 ]; then
  printf 'FAIL: Unvollstaendiges Hilfspaket lieferte Exit %s statt 2.\n' "$partial_exit" >&2
  exit 1
fi
if ! grep -q 'incomplete helper package' <<<"$partial_output"; then
  echo 'FAIL: Eindeutige Diagnose fuer das unvollstaendige Hilfspaket fehlt.' >&2
  exit 1
fi

complete_output="${TEMP_ROOT}/complete-output.txt"
set +e
bash "${SCRIPT_DIR}/check-homogeneity.sh" --dry-run --no-patch "$REPO_ROOT" \
  >"$complete_output" 2>&1
complete_exit=$?
set -e
if [ "$complete_exit" -eq 2 ]; then
  echo 'FAIL: Vollstaendiges Hilfspaket wurde als fatal unvollstaendig bewertet.' >&2
  cat "$complete_output" >&2
  exit 1
fi
if grep -Eq 'command not found|incomplete helper package' "$complete_output"; then
  echo 'FAIL: Vollstaendiger Lauf enthaelt einen Hilfspaketfehler.' >&2
  exit 1
fi

pair_root="${TEMP_ROOT}/language pair"
mkdir -p "$pair_root"
printf '# Einstieg\n\n[English](Guide.en.md)\n' >"${pair_root}/Guide.md"
printf '# Entry\n\n[Deutsch](Guide.md)\n' >"${pair_root}/Guide.en.md"
. "${SCRIPT_DIR}/lib/hg-bilingual.sh"
for pair_file in "${pair_root}/Guide.md" "${pair_root}/Guide.en.md"; do
  pair_output="$(hg_check_bilingual "$pair_file")"
  if [[ "$pair_output" != PASS*'|bilingual-language-pair' ]]; then
    printf 'FAIL: Sprachpartner wurde nicht bidirektional erkannt: %s\n' "$pair_output" >&2
    exit 1
  fi
done

printf '# Einstieg\n\n[English](Guide.EN.MD)\n' >"${pair_root}/Guide.MD"
printf '# Entry\n\n[Deutsch](Guide.MD)\n' >"${pair_root}/Guide.EN.MD"
for pair_file in "${pair_root}/Guide.MD" "${pair_root}/Guide.EN.MD"; do
  pair_output="$(hg_check_bilingual "$pair_file")"
  if [[ "$pair_output" != PASS*'|bilingual-language-pair' ]]; then
    printf 'FAIL: Grossgeschriebener Sprachpartner wurde nicht erkannt: %s\n' "$pair_output" >&2
    exit 1
  fi
done

echo 'PASS: Homogeneity-Runtime-Abschluss (Bash) ist fail-closed und vollstaendig.'
