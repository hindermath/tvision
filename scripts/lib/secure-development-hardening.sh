#!/usr/bin/env bash
# Shared helpers for secure-development hardening intake preparation.

SDH_PREPARE_RESULT=""
SDH_PREPARE_REASON=""
SDH_DETECTED_LANGUAGE=""

sdh_log() {
  printf '%s\n' "$*"
}

sdh_normalize_language() {
  printf '%s' "${1:-}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[[:space:]_+-]\+//g; s#/# #g' \
    | tr -d '.'
}

sdh_is_msl_language() {
  local normalized
  normalized="$(sdh_normalize_language "$1")"
  case "$normalized" in
    csharp|cs|c#|dotnet|net|fsharp|fs|f#|rust|swift|java|kotlin|scala|go|golang|dart|python|py|ruby|javascript|js|typescript|ts|haskell|ocaml|erlang|elixir|ada|spark)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

sdh_is_known_non_msl_language() {
  local normalized
  normalized="$(sdh_normalize_language "$1")"
  case "$normalized" in
    c|cpp|cxx|cplusplus|objectivec|objc|assembly|asm|cc65|zig|nim|d)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

sdh_detect_language_from_constitution() {
  local repo="$1"
  local project_name="$2"
  local file line language

  for file in "$repo/constitution.md" "$repo/.specify/memory/constitution.md"; do
    [ -f "$file" ] || continue
    line="$(awk -F'|' -v project="$project_name" '
      index($0, project) > 0 && NF >= 4 { gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3; exit }
    ' "$file")"
    if [ -n "$line" ]; then
      language="$line"
      case "$language" in
        *C#*|*.NET*|*dotnet*) printf '%s\n' "C#"; return 0 ;;
        *Rust*) printf '%s\n' "Rust"; return 0 ;;
        *Swift*) printf '%s\n' "Swift"; return 0 ;;
        *JavaScript*|*TypeScript*) printf '%s\n' "TypeScript"; return 0 ;;
        *Java*) printf '%s\n' "Java"; return 0 ;;
        *Kotlin*) printf '%s\n' "Kotlin"; return 0 ;;
        *Go*) printf '%s\n' "Go"; return 0 ;;
        *Python*) printf '%s\n' "Python"; return 0 ;;
        *C/C89*|*C89*|*C++*|*Assembly*|*Zig*) printf '%s\n' "$language"; return 0 ;;
      esac
    fi
  done

  return 1
}

sdh_detect_language_from_project_name() {
  local project_name
  project_name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  case "$project_name" in
    *-csharp|*_csharp|*.csharp|*-c#|*_c#|*.c#) printf '%s\n' "C#" ;;
    *-fsharp|*_fsharp|*.fsharp|*-f#|*_f#|*.f#) printf '%s\n' "F#" ;;
    *-rust|*_rust|*.rust) printf '%s\n' "Rust" ;;
    *-swift|*_swift|*.swift) printf '%s\n' "Swift" ;;
    *-java|*_java|*.java) printf '%s\n' "Java" ;;
    *-kotlin|*_kotlin|*.kotlin) printf '%s\n' "Kotlin" ;;
    *-go|*_go|*.go) printf '%s\n' "Go" ;;
    *-python|*_python|*.python) printf '%s\n' "Python" ;;
    *-typescript|*_typescript|*.typescript) printf '%s\n' "TypeScript" ;;
    *-javascript|*_javascript|*.javascript) printf '%s\n' "JavaScript" ;;
    *) return 1 ;;
  esac
}

sdh_find_first() {
  local repo="$1"
  shift
  find "$repo" -maxdepth 4 "$@" -print -quit 2>/dev/null
}

sdh_detect_language_from_files() {
  local repo="$1"

  if [ -n "$(sdh_find_first "$repo" \( -name '*.sln' -o -name '*.csproj' -o -name '*.fsproj' \))" ]; then
    printf '%s\n' "C#"
  elif [ -f "$repo/Cargo.toml" ] || [ -n "$(sdh_find_first "$repo" -name Cargo.toml)" ]; then
    printf '%s\n' "Rust"
  elif [ -f "$repo/go.mod" ] || [ -n "$(sdh_find_first "$repo" -name go.mod)" ]; then
    printf '%s\n' "Go"
  elif [ -f "$repo/Package.swift" ] || [ -n "$(sdh_find_first "$repo" -name Package.swift)" ]; then
    printf '%s\n' "Swift"
  elif [ -f "$repo/tsconfig.json" ] || [ -n "$(sdh_find_first "$repo" -name tsconfig.json)" ]; then
    printf '%s\n' "TypeScript"
  elif [ -f "$repo/package.json" ] || [ -n "$(sdh_find_first "$repo" -name package.json)" ]; then
    printf '%s\n' "JavaScript"
  elif [ -f "$repo/pyproject.toml" ] || [ -n "$(sdh_find_first "$repo" -name pyproject.toml)" ]; then
    printf '%s\n' "Python"
  elif [ -n "$(sdh_find_first "$repo" \( -name 'pom.xml' -o -name 'build.gradle' -o -name 'build.gradle.kts' \))" ]; then
    printf '%s\n' "Java"
  else
    return 1
  fi
}

sdh_detect_language() {
  local repo="$1"
  local project_name="$2"
  local explicit_language="${3:-}"
  local detected=""

  if [ -n "$explicit_language" ]; then
    printf '%s\n' "$explicit_language"
    return 0
  fi

  detected="$(sdh_detect_language_from_constitution "$repo" "$project_name" 2>/dev/null || true)"
  if [ -n "$detected" ]; then
    printf '%s\n' "$detected"
    return 0
  fi

  detected="$(sdh_detect_language_from_project_name "$project_name" 2>/dev/null || true)"
  if [ -n "$detected" ]; then
    printf '%s\n' "$detected"
    return 0
  fi

  detected="$(sdh_detect_language_from_files "$repo" 2>/dev/null || true)"
  if [ -n "$detected" ]; then
    printf '%s\n' "$detected"
    return 0
  fi

  return 1
}

sdh_find_source_dir() {
  local script_dir="$1"
  local repo_dir
  repo_dir="$(cd "$script_dir/.." 2>/dev/null && pwd)"

  for candidate in \
    "$repo_dir/docs/secure-development" \
    "$HOME/docs/secure-development" \
    "$HOME/home-baseline-source/docs/secure-development"; do
    if [ -d "$candidate" ] \
      && [ -f "$candidate/README.md" ] \
      && [ -f "$candidate/mitgeltende-dokumente/README.md" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

sdh_manifest_paths() {
  local manifest="$1"
  jq -r '
    ["baseline-manifest.json", .guideline.path, .compendium.path]
    + [.checklists[].path]
    + [.relatedDocuments[].path]
    + [.learningDocuments[].path]
    + .managedBinaryFiles
    + .managedReferenceFiles
    | unique[]
  ' "$manifest"
}

sdh_sync_baseline() {
  local source_dir="$1"
  local target_dir="$2"
  local dry_run="${3:-0}"
  local source_manifest="$source_dir/baseline-manifest.json"
  local target_manifest="$target_dir/baseline-manifest.json"
  local new_paths old_paths relative source_file target_file copied=0 removed=0

  command -v jq >/dev/null 2>&1 || { sdh_log "  Fehler: jq wird fuer die manifestgesteuerte Synchronisation benoetigt"; return 1; }
  [ -f "$source_manifest" ] || { sdh_log "  Fehler: Baseline-Manifest fehlt: $source_manifest"; return 1; }
  new_paths="$(mktemp)"
  old_paths="$(mktemp)"
  sdh_manifest_paths "$source_manifest" > "$new_paths"
  if [ -f "$target_manifest" ]; then
    sdh_manifest_paths "$target_manifest" > "$old_paths"
  else
    : > "$old_paths"
  fi

  while IFS= read -r relative; do
    [ -n "$relative" ] || continue
    case "$relative" in /*|*../*) sdh_log "  Fehler: unsicherer Manifestpfad: $relative"; rm -f "$new_paths" "$old_paths"; return 1 ;; esac
    if ! grep -Fqx "$relative" "$new_paths"; then
      target_file="$target_dir/$relative"
      if [ -f "$target_file" ]; then
        removed=$((removed + 1))
        [ "$dry_run" = "1" ] || rm -f "$target_file"
      fi
    fi
  done < "$old_paths"

  while IFS= read -r relative; do
    [ -n "$relative" ] || continue
    case "$relative" in /*|*../*) sdh_log "  Fehler: unsicherer Manifestpfad: $relative"; rm -f "$new_paths" "$old_paths"; return 1 ;; esac
    source_file="$source_dir/$relative"
    target_file="$target_dir/$relative"
    [ -f "$source_file" ] || { sdh_log "  Fehler: verwaltete Quelldatei fehlt: $relative"; rm -f "$new_paths" "$old_paths"; return 1; }
    if [ ! -f "$target_file" ] || ! cmp -s "$source_file" "$target_file"; then
      copied=$((copied + 1))
      if [ "$dry_run" != "1" ] && [ "$relative" != "baseline-manifest.json" ]; then
        mkdir -p "$(dirname "$target_file")"
        cp "$source_file" "$target_file"
      fi
    fi
  done < "$new_paths"

  if [ "$dry_run" != "1" ]; then
    mkdir -p "$target_dir"
    cp "$source_manifest" "$target_manifest"
    find "$target_dir" -depth -type d -empty -delete 2>/dev/null || true
  fi
  sdh_log "  Baseline-Sync: $copied aktualisiert, $removed veraltet entfernt"
  rm -f "$new_paths" "$old_paths"
}

sdh_find_template_file() {
  local script_dir="$1"
  local repo_dir
  repo_dir="$(cd "$script_dir/.." 2>/dev/null && pwd)"

  for candidate in \
    "$script_dir/templates/secure-development-hardening-lastenheft.md" \
    "$repo_dir/scripts/templates/secure-development-hardening-lastenheft.md" \
    "$HOME/scripts/templates/secure-development-hardening-lastenheft.md" \
    "$HOME/home-baseline-source/scripts/templates/secure-development-hardening-lastenheft.md"; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

sdh_render_template() {
  local template="$1"
  local output="$2"
  local project_name="$3"
  local today
  today="$(date +%Y-%m-%d)"

  sed \
    -e "s|{{PROJECT_NAME}}|${project_name}|g" \
    -e "s|{{DATE}}|${today}|g" \
    "$template" > "$output"
}

sdh_order_rank() {
  local name
  name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  case "$name" in
    *rl-se*checklist*selbstpruefung*|*checklist*selbstpruefung*) printf '%s\n' "45" ;;
    *gsdb*spec-kit*intensivpruefung*|*gsdb*intensiv*) printf '%s\n' "48" ;;
    *secure-development-hardening*) printf '%s\n' "50" ;;
    *constitution*|*governance*|*baseline*|*homogeneity*) printf '%s\n' "10" ;;
    *migration*|*build*|*ci*|*cicd*|*tool*|*terminalgui*|*rename*) printf '%s\n' "20" ;;
    *compiler*|*worker*|*service*|*database*|*db*|*sql*|*mongodb*|*postgres*|*sqlite*|*framework*|*core*|*controls*|*runtime*|*vm*|*clr*|*assembly*|*pl0*|*wave*) printf '%s\n' "30" ;;
    *ui*|*tui*|*ide*|*a11y*|*dokument*|*doc*|*l10n*|*didactic*|*comment*) printf '%s\n' "40" ;;
    *) printf '%s\n' "60" ;;
  esac
}

sdh_order_group() {
  case "$1" in
    10) printf '%s\n' "Governance/Baseline" ;;
    20) printf '%s\n' "Migration/Tooling" ;;
    30) printf '%s\n' "Kernlogik/Runtime" ;;
    40) printf '%s\n' "UI/A11Y/Dokumentation" ;;
    45) printf '%s\n' "RL-SE-/Checklist-Selbstpruefung" ;;
    48) printf '%s\n' "GSDB-Spec-Kit-Intensivpruefung" ;;
    50) printf '%s\n' "Secure-Development-Hardening" ;;
    *)  printf '%s\n' "Weitere Anforderungen" ;;
  esac
}

sdh_build_order_section() {
  local repo="$1"
  local tmp_items
  local file base rank group status count

  tmp_items="$(mktemp)"
  find "$repo" -maxdepth 1 -type f -name 'Lastenheft*.md' ! -name 'Lastenheft_Abarbeitungsreihenfolge.md' -print \
    | while IFS= read -r file; do
        base="$(basename "$file")"
        rank="$(sdh_order_rank "$base")"
        group="$(sdh_order_group "$rank")"
        status="aktiv / active"
        case "$base" in
          *.[0-9][0-9][0-9]*.md) status="archiviert oder abgeschlossen / archived or completed" ;;
        esac
        printf '%s|%s|%s|%s\n' "$rank" "$base" "$group" "$status"
      done | sort -t '|' -k1,1n -k2,2f > "$tmp_items"

  count="$(wc -l < "$tmp_items" | tr -d ' ')"

  cat <<'EOF'
<!-- secure-development-hardening-order:start -->
## Automatisch ermittelte Lastenheft-Reihenfolge / Automatically Detected Requirements Order

Diese Tabelle wird aus `Lastenheft*.md` im Repository-Root erzeugt. Sie ist eine Vorbereitung fuer spaetere Spec-Kit-Laeufe und startet selbst keinen Lauf. Manuelle Projektentscheidungen ausserhalb dieses markierten Abschnitts bleiben erhalten.

*This table is generated from `Lastenheft*.md` in the repository root. It prepares later Spec Kit runs and does not start a run. Manual project decisions outside this marked section remain preserved.*

| Rang | Lastenheft | Gruppe | Status |
|---:|---|---|---|
EOF

  if [ "$count" = "0" ]; then
    printf '| - | - | Keine Lastenhefte gefunden | - |\n'
  else
    awk -F'|' '{ printf "| %d | `%s` | %s | %s |\n", NR, $2, $3, $4 }' "$tmp_items"
  fi

  cat <<'EOF'
<!-- secure-development-hardening-order:end -->
EOF

  rm -f "$tmp_items"
}

sdh_update_order_file() {
  local repo="$1"
  local dry_run="$2"
  local order_file="$repo/Lastenheft_Abarbeitungsreihenfolge.md"
  local section_file tmp_file normalized_file

  section_file="$(mktemp)"
  tmp_file="$(mktemp)"
  normalized_file="$(mktemp)"
  sdh_build_order_section "$repo" > "$section_file"

  if [ -f "$order_file" ]; then
    if grep -q '<!-- secure-development-hardening-order:start -->' "$order_file" \
      && grep -q '<!-- secure-development-hardening-order:end -->' "$order_file"; then
      awk -v section_file="$section_file" '
        BEGIN {
          while ((getline line < section_file) > 0) section = section line "\n"
          in_generated = 0
        }
        /<!-- secure-development-hardening-order:start -->/ {
          printf "%s", section
          in_generated = 1
          next
        }
        /<!-- secure-development-hardening-order:end -->/ {
          in_generated = 0
          next
        }
        in_generated == 0 { print }
      ' "$order_file" > "$tmp_file"
    else
      {
        cat "$order_file"
        printf '\n\n'
        cat "$section_file"
      } > "$tmp_file"
    fi
  else
    cat > "$tmp_file" <<'EOF'
# Lastenheft-Abarbeitungsreihenfolge / Requirements Processing Order

Diese Datei haelt die sichtbare Abarbeitungsreihenfolge der vorhandenen Lastenhefte fest. Sie ist eine Vorbereitung fuer spaetere Spec-Kit-Laeufe und startet selbst keinen Lauf.

*This file records the visible processing order of existing requirements documents. It prepares later Spec Kit runs and does not start a run by itself.*

EOF
    cat "$section_file" >> "$tmp_file"
  fi

  awk '
    { lines[NR] = $0 }
    END {
      last = NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
      for (i = 1; i <= last; i++) print lines[i]
    }
  ' "$tmp_file" > "$normalized_file"
  mv "$normalized_file" "$tmp_file"

  if [ -f "$order_file" ] && cmp -s "$order_file" "$tmp_file"; then
    rm -f "$section_file" "$tmp_file" "$normalized_file"
    return 1
  fi

  if [ "$dry_run" = "1" ]; then
    rm -f "$section_file" "$tmp_file" "$normalized_file"
    return 0
  fi

  mv "$tmp_file" "$order_file"
  rm -f "$section_file" "$normalized_file"
  return 0
}

sdh_prepare_repo() {
  local repo="$1"
  local project_name="$2"
  local explicit_language="${3:-}"
  local dry_run="${4:-0}"
  local force="${5:-0}"
  local script_dir="${6:-}"
  local language source_dir template_file target_docs intake_file

  SDH_PREPARE_RESULT="skipped"
  SDH_PREPARE_REASON=""
  SDH_DETECTED_LANGUAGE=""

  if [ ! -d "$repo/.git" ]; then
    SDH_PREPARE_REASON="kein Git-Repository"
    return 0
  fi

  language="$(sdh_detect_language "$repo" "$project_name" "$explicit_language" 2>/dev/null || true)"
  if [ -z "$language" ]; then
    SDH_PREPARE_REASON="Primaersprache unklar; nutze --primary-language fuer automatische Vorbereitung"
    return 0
  fi
  SDH_DETECTED_LANGUAGE="$language"

  if ! sdh_is_msl_language "$language"; then
    if sdh_is_known_non_msl_language "$language"; then
      SDH_PREPARE_REASON="nicht-MSL erkannt: $language"
    else
      SDH_PREPARE_REASON="Sprache nicht auf MSL-Allowlist: $language"
    fi
    return 0
  fi

  script_dir="${script_dir:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"
  source_dir="$(sdh_find_source_dir "$script_dir" 2>/dev/null || true)"
  template_file="$(sdh_find_template_file "$script_dir" 2>/dev/null || true)"

  if [ -z "$source_dir" ]; then
    SDH_PREPARE_RESULT="error"
    SDH_PREPARE_REASON="docs/secure-development Quelle nicht gefunden"
    return 1
  fi
  if [ -z "$template_file" ]; then
    SDH_PREPARE_RESULT="error"
    SDH_PREPARE_REASON="Lastenheft-Template nicht gefunden"
    return 1
  fi

  target_docs="$repo/docs/secure-development"
  intake_file="$repo/Lastenheft_Secure-Development-Hardening.md"

  if [ "$dry_run" = "1" ]; then
    sdh_log "  [dry-run] docs/secure-development nach ${repo}/docs/secure-development synchronisieren"
  else
    sdh_sync_baseline "$source_dir" "$target_docs" 0
  fi

  if [ -f "$intake_file" ] && [ "$force" != "1" ]; then
    [ "$dry_run" = "1" ] && sdh_log "  [dry-run] Lastenheft vorhanden, wird nicht ueberschrieben: $(basename "$intake_file")"
  else
    if [ "$dry_run" = "1" ]; then
      sdh_log "  [dry-run] Lastenheft_Secure-Development-Hardening.md erzeugen"
    else
      sdh_render_template "$template_file" "$intake_file" "$project_name"
    fi
  fi

  if sdh_update_order_file "$repo" "$dry_run"; then
    [ "$dry_run" = "1" ] && sdh_log "  [dry-run] Lastenheft_Abarbeitungsreihenfolge.md aktualisieren"
  else
    [ "$dry_run" = "1" ] && sdh_log "  [dry-run] Lastenheft_Abarbeitungsreihenfolge.md unveraendert"
  fi

  SDH_PREPARE_RESULT="prepared"
  SDH_PREPARE_REASON="MSL erkannt: $language"
  return 0
}
