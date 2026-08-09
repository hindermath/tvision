#!/usr/bin/env bash
# Audits the Antigravity migration across Level-0/1/2 repositories.
set -euo pipefail

HOME_DIR="$HOME"
OUTPUT_JSON=false
FAIL_ON_OPEN=false
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/resolve-home-baseline-source.sh
source "${SCRIPT_DIR}/lib/resolve-home-baseline-source.sh"
LEVEL0_SOURCE="$(resolve_hb_source_repository "${BASH_SOURCE[0]}" 1)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --home-dir) HOME_DIR="${2:?--home-dir requires a path}"; shift ;;
    --json) OUTPUT_JSON=true ;;
    --fail-on-open) FAIL_ON_OPEN=true ;;
    -h|--help)
      echo "USAGE: audit-antigravity-migration.sh [--home-dir PATH] [--json] [--fail-on-open]"
      exit 0
      ;;
    *) echo "Fehler / Error: unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

python3 - "$HOME_DIR" "$OUTPUT_JSON" "$FAIL_ON_OPEN" "$LEVEL0_SOURCE" <<'PY'
import json
import pathlib
import re
import subprocess
import sys

home = pathlib.Path(sys.argv[1]).expanduser().resolve()
output_json = sys.argv[2].lower() == "true"
fail_on_open = sys.argv[3].lower() == "true"
level0_source = pathlib.Path(sys.argv[4]).expanduser().resolve()


def is_repo(path):
    return (path / ".git").exists() and (path / ".specify").is_dir()


def discover():
    repos = []
    level0 = level0_source
    if is_repo(level0):
        repos.append((0, level0))
    for workspace in sorted(home.iterdir()):
        if workspace == level0 or not workspace.is_dir():
            continue
        if is_repo(workspace):
            repos.append((1, workspace))
            for project in sorted(workspace.iterdir()):
                if project.is_dir() and is_repo(project):
                    repos.append((2, project))
    return repos


def tracked_files(repo):
    result = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "-z"],
        check=False,
        capture_output=True,
    )
    return [item.decode("utf-8", "surrogateescape") for item in result.stdout.split(b"\0") if item]


def active_gemini_references(repo):
    patterns = (
        re.compile(r"(?m)^\s*(?:\$\s*)?gemini(?:\s|$)"),
        re.compile(r"--integration(?:=|\s+)gemini\b"),
        re.compile(r"setup-gemini-settings"),
    )
    excluded = (
        "CHANGELOG.md",
        "docs/project-statistics.md",
        "docs/maintenance/",
        "docs/bug-reports/",
        "docs/learning-units/dist/",
        "specs/",
        "scripts/audit-antigravity-migration.",
    )
    hits = []
    for relative in tracked_files(repo):
        if pathlib.PurePosixPath(relative).name.startswith("Lastenheft"):
            continue
        if relative.startswith("scripts/audit-antigravity-migration."):
            continue
        if relative in excluded or any(relative.startswith(prefix) for prefix in excluded if prefix.endswith("/")):
            continue
        path = repo / relative
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if any(pattern.search(text) for pattern in patterns):
            hits.append(relative)
    return sorted(set(hits))


results = []
for level, repo in discover():
    findings = []
    agy_manifest = repo / ".specify/integrations/agy.manifest.json"
    gemini_manifest = repo / ".specify/integrations/gemini.manifest.json"
    gemini_commands = repo / ".gemini/commands"
    skill_root = repo / ".agents/skills"
    if not agy_manifest.is_file():
        findings.append("missing agy integration manifest")
    if gemini_manifest.exists():
        findings.append("legacy gemini integration manifest present")
    if gemini_commands.exists():
        findings.append("legacy .gemini/commands present")
    if not skill_root.is_dir() or not any(skill_root.glob("speckit-*")):
        findings.append("missing .agents/skills/speckit-*")
    gitignore = repo / ".gitignore"
    if gitignore.is_file():
        ignore_text = gitignore.read_text(encoding="utf-8", errors="replace")
        if ".agents/*" not in ignore_text or "!.agents/skills/" not in ignore_text:
            findings.append("unsafe or incomplete .agents gitignore allowlist")
    else:
        findings.append("missing .gitignore")
    tracked_mcp = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "--error-unmatch", ".agents/mcp_config.json"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if tracked_mcp.returncode == 0:
        findings.append("tracked .agents/mcp_config.json")
    for relative in active_gemini_references(repo):
        findings.append("active Gemini CLI reference: " + relative)
    results.append({
        "level": level,
        "repository": str(repo),
        "status": "PASS" if not findings else "FAIL",
        "findings": findings,
    })

summary = {
    "repositories": len(results),
    "passed": sum(item["status"] == "PASS" for item in results),
    "failed": sum(item["status"] == "FAIL" for item in results),
    "openFindings": sum(len(item["findings"]) for item in results),
}
report = {"summary": summary, "results": results}
if output_json:
    print(json.dumps(report, indent=2, ensure_ascii=True))
else:
    print("Antigravity Migration Audit")
    for item in results:
        print(f"[{item['status']}] Level-{item['level']} {item['repository']}")
        for finding in item["findings"]:
            print("  - " + finding)
    print(
        "Summary: repositories={repositories} passed={passed} failed={failed} open={openFindings}".format(
            **summary
        )
    )
if fail_on_open and summary["openFindings"]:
    raise SystemExit(2)
PY
