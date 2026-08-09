#!/usr/bin/env bash
# setup-gitlab-release.sh — Installiert GitLab Release-Automation in ein bestehendes Repo
#
# Usage:
#   bash scripts/setup-gitlab-release.sh [TARGET_REPO] [--gitlab-url URL] [--skip-project-settings] [--force]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

TARGET_REPO="$PWD"
OPT_GITLAB_URL=""
OPT_SKIP_PROJECT_SETTINGS=false
OPT_FORCE=false

usage() {
  cat <<'EOF'
USAGE:
  bash scripts/setup-gitlab-release.sh [TARGET_REPO] [OPTIONS]

OPTIONS:
  --gitlab-url URL         GitLab base URL, for example https://gitlab-ce.gwdg.de
  --skip-project-settings  Do not enable ci_push_repository_for_job_token_allowed
  --force                  Overwrite release-gitlab.sh and CHANGELOG.md if present
  -h, --help               Show this help
EOF
}

short_path() {
  printf '%s' "${1/#$HOME/~}"
}

normalize_repo_path() {
  local path="$1"
  path="${path/#\~/$HOME}"
  printf '%s' "${path%/}"
}

repo_path_from_remote() {
  case "$1" in
    https://*)
      printf '%s' "${1#https://}" | sed -E 's#^[^/]+/##; s#\.git$##'
      ;;
    git@*:*)
      printf '%s' "$1" | sed -E 's#^git@[^:]+:##; s#\.git$##'
      ;;
    ssh://git@*/*)
      printf '%s' "$1" | sed -E 's#^ssh://git@[^/]+/##; s#\.git$##'
      ;;
    *)
      printf '%s' ""
      ;;
  esac
}

repo_host_from_remote() {
  case "$1" in
    https://*)
      printf '%s' "${1#https://}" | cut -d/ -f1
      ;;
    git@*:*)
      printf '%s' "$1" | sed -E 's#^git@([^:]+):.*#\1#'
      ;;
    ssh://git@*/*)
      printf '%s' "$1" | sed -E 's#^ssh://git@([^/]+)/.*#\1#'
      ;;
    *)
      printf '%s' ""
      ;;
  esac
}

ensure_release_stage() {
  local ci_file="$1"
  local tmp_file

  if grep -Eq '^stages:[[:space:]]*\[[^]]*\brelease\b[^]]*\]' "$ci_file" \
    || grep -Eq '^[[:space:]]*-[[:space:]]*release[[:space:]]*$' "$ci_file"; then
    return 0
  fi

  tmp_file="$(mktemp)"
  if grep -Eq '^stages:[[:space:]]*\[.*\]' "$ci_file"; then
    awk '
      BEGIN { done = 0 }
      {
        if (!done && $0 ~ /^stages:[[:space:]]*\[.*\][[:space:]]*$/) {
          sub(/\][[:space:]]*$/, ", release]")
          done = 1
        }
        print
      }
    ' "$ci_file" > "$tmp_file"
  elif grep -Eq '^stages:[[:space:]]*$' "$ci_file"; then
    awk '
      BEGIN { in_stages = 0; inserted = 0 }
      /^stages:[[:space:]]*$/ {
        print
        in_stages = 1
        next
      }
      {
        if (in_stages && $0 !~ /^[[:space:]]*-[[:space:]]+/) {
          print "  - release"
          inserted = 1
          in_stages = 0
        }
        print
      }
      END {
        if (in_stages && !inserted) {
          print "  - release"
        }
      }
    ' "$ci_file" > "$tmp_file"
  else
    {
      printf 'stages:\n  - release\n\n'
      cat "$ci_file"
    } > "$tmp_file"
  fi

  mv "$tmp_file" "$ci_file"
}

enable_job_token_push() {
  local target_repo="$1"
  local remote_url gitlab_host repo_path encoded_path

  if $OPT_SKIP_PROJECT_SETTINGS; then
    echo "  INFO: GitLab project settings skipped"
    return 0
  fi

  if ! command -v glab >/dev/null 2>&1; then
    echo "  WARN: glab not installed — project setting not changed"
    return 0
  fi

  remote_url="$(git -C "$target_repo" remote get-url origin 2>/dev/null || true)"
  if [ -z "$remote_url" ]; then
    echo "  WARN: origin remote missing — project setting not changed"
    return 0
  fi

  repo_path="$(repo_path_from_remote "$remote_url")"
  if [ -z "$repo_path" ]; then
    echo "  WARN: could not derive GitLab project path from origin remote"
    return 0
  fi

  if [ -n "$OPT_GITLAB_URL" ]; then
    gitlab_host="${OPT_GITLAB_URL#https://}"
    gitlab_host="${gitlab_host%/}"
  else
    gitlab_host="$(repo_host_from_remote "$remote_url")"
  fi

  if [ -z "$gitlab_host" ]; then
    echo "  WARN: could not derive GitLab host from origin remote"
    return 0
  fi

  if ! GITLAB_HOST="$gitlab_host" glab auth status >/dev/null 2>&1; then
    echo "  WARN: not authenticated for GitLab host ${gitlab_host}"
    return 0
  fi

  encoded_path="${repo_path//\//%2F}"
  if GITLAB_HOST="$gitlab_host" glab api --method PUT \
    "projects/${encoded_path}?ci_push_repository_for_job_token_allowed=true" >/dev/null 2>&1; then
    echo "  OK: enabled ci_push_repository_for_job_token_allowed for ${repo_path}"
  else
    echo "  WARN: could not enable ci_push_repository_for_job_token_allowed for ${repo_path}"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --gitlab-url)
      OPT_GITLAB_URL="${2:-}"
      shift
      ;;
    --skip-project-settings)
      OPT_SKIP_PROJECT_SETTINGS=true
      ;;
    --force)
      OPT_FORCE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      TARGET_REPO="$1"
      ;;
  esac
  shift
done

TARGET_REPO="$(normalize_repo_path "$TARGET_REPO")"

for required in \
  "${TEMPLATES_DIR}/release-gitlab.sh.tmpl" \
  "${TEMPLATES_DIR}/gitlab-release-job.yml.tmpl" \
  "${TEMPLATES_DIR}/changelog-template.md"; do
  if [ ! -f "$required" ]; then
    echo "ERROR: missing template $(short_path "$required")" >&2
    exit 1
  fi
done

if [ ! -d "$TARGET_REPO/.git" ]; then
  echo "ERROR: target is not a git repository: $(short_path "$TARGET_REPO")" >&2
  exit 2
fi

echo "GitLab release automation"
echo "Target: $(short_path "$TARGET_REPO")"

mkdir -p "${TARGET_REPO}/scripts"
cp "${TEMPLATES_DIR}/release-gitlab.sh.tmpl" "${TARGET_REPO}/scripts/release-gitlab.sh"
chmod +x "${TARGET_REPO}/scripts/release-gitlab.sh"
echo "  OK: wrote scripts/release-gitlab.sh"

if [ ! -f "${TARGET_REPO}/CHANGELOG.md" ] || $OPT_FORCE; then
  cp "${TEMPLATES_DIR}/changelog-template.md" "${TARGET_REPO}/CHANGELOG.md"
  echo "  OK: wrote CHANGELOG.md"
else
  echo "  INFO: CHANGELOG.md already present"
fi

ci_file="${TARGET_REPO}/.gitlab-ci.yml"
job_template="$(cat "${TEMPLATES_DIR}/gitlab-release-job.yml.tmpl")"

if [ ! -f "$ci_file" ]; then
  {
    printf 'stages:\n  - release\n\n'
    printf '%s\n' "$job_template"
  } > "$ci_file"
  echo "  OK: created .gitlab-ci.yml"
else
  ensure_release_stage "$ci_file"
  if grep -q 'home-baseline gitlab release automation' "$ci_file"; then
    echo "  INFO: release job already present in .gitlab-ci.yml"
  else
    printf '\n%s\n' "$job_template" >> "$ci_file"
    echo "  OK: appended release job to .gitlab-ci.yml"
  fi
fi

enable_job_token_push "$TARGET_REPO"

echo "Done."
