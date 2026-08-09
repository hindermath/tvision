#!/usr/bin/env bash
# Tracks changes in agent-managed files and correlates them with local agent logs.
# macOS/Linux -- counterpart: audit-agent-changes.ps1
#
# Usage:
#   bash scripts/audit-agent-changes.sh snapshot
#   bash scripts/audit-agent-changes.sh report
#   bash scripts/audit-agent-changes.sh report --refresh-baseline

set -euo pipefail

ACTION=""
HOME_DIR="${HOME}"
STATE_DIR="${HOME}/.home-baseline/agent-audit"
WINDOW_HOURS=4
OUTPUT_JSON=false
REFRESH_BASELINE=false

print_usage() {
  cat <<'EOF'
USAGE:
  bash scripts/audit-agent-changes.sh snapshot [--home DIR] [--state-dir DIR]
  bash scripts/audit-agent-changes.sh report   [--home DIR] [--state-dir DIR] [--window-hours N] [--json] [--refresh-baseline]

DESCRIPTION:
  snapshot           Create a baseline snapshot of agent-managed files below HOME.
  report             Compare current state with the saved baseline, store a JSON report,
                     and correlate changes with recent Codex, Claude, Copilot, and Continue logs.

OPTIONS:
  --home DIR             Override the home directory to inspect.
  --state-dir DIR        Override the local audit state directory.
  --window-hours N       Correlation window around changed file timestamps (default: 4).
  --json                 Print the full JSON report instead of the human summary.
  --refresh-baseline     After report creation, accept current state as the new baseline.
  -h, --help             Show this help text.
EOF
}

if [ $# -eq 0 ]; then
  print_usage
  exit 1
fi

ACTION="$1"
shift

case "$ACTION" in
  snapshot|report) ;;
  -h|--help)
    print_usage
    exit 0
    ;;
  *)
    printf "Fehler / Error: unknown action: %s\n" "$ACTION" >&2
    print_usage >&2
    exit 1
    ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --home)
      if [ -z "${2:-}" ]; then
        echo "Fehler / Error: --home requires a value." >&2
        exit 1
      fi
      HOME_DIR="$2"
      shift
      ;;
    --state-dir)
      if [ -z "${2:-}" ]; then
        echo "Fehler / Error: --state-dir requires a value." >&2
        exit 1
      fi
      STATE_DIR="$2"
      shift
      ;;
    --window-hours)
      if [ -z "${2:-}" ]; then
        echo "Fehler / Error: --window-hours requires a value." >&2
        exit 1
      fi
      WINDOW_HOURS="$2"
      shift
      ;;
    --json)
      OUTPUT_JSON=true
      ;;
    --refresh-baseline)
      REFRESH_BASELINE=true
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      printf "Fehler / Error: unknown argument: %s\n" "$1" >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "Fehler / Error: python3 wird benoetigt / is required." >&2
  exit 1
fi

python3 - "$ACTION" "$HOME_DIR" "$STATE_DIR" "$WINDOW_HOURS" "$OUTPUT_JSON" "$REFRESH_BASELINE" <<'PYEOF'
import datetime as dt
import hashlib
import json
import os
import pathlib
import re
import sys
from typing import Dict, Iterable, List, Tuple

ACTION = sys.argv[1]
HOME_DIR = pathlib.Path(sys.argv[2]).expanduser().resolve()
STATE_DIR = pathlib.Path(sys.argv[3]).expanduser().resolve()
WINDOW_HOURS = int(sys.argv[4])
OUTPUT_JSON = sys.argv[5].lower() == "true"
REFRESH_BASELINE = sys.argv[6].lower() == "true"

BASELINE_FILE = STATE_DIR / "baseline.json"
SNAPSHOT_DIR = STATE_DIR / "snapshots"
REPORT_DIR = STATE_DIR / "reports"

MONITORED_SPECS = [
    ("tree", ".agents"),
    ("tree", ".github/agents"),
    ("tree", ".github/prompts"),
    ("tree", ".claude/commands"),
    ("file", ".gemini/antigravity-cli/settings.json"),
    ("file", ".codex/config.toml"),
    ("file", ".claude/settings.json"),
    ("file", ".copilot/config.json"),
    ("file", ".continue/config.yaml"),
    ("file", ".continue/config.json"),
]

APP_SOURCES = {
    "Antigravity": [".gemini/antigravity-cli/history", ".gemini/antigravity-cli/logs"],
    "Codex": [".codex/history.jsonl", ".codex/log/codex-tui.log"],
    "Claude": [".claude/history.jsonl", ".claude/projects", ".claude/file-history"],
    "Copilot": [".copilot/command-history-state.json", ".copilot/logs"],
    "Continue": [".continue/input_history.json", ".continue/logs"],
}

STOP_TERMS = {
    "agents",
    "skills",
    "commands",
    "github",
    "prompts",
    "config",
    "settings",
    "templates",
    "scripts",
    "file",
    "json",
    "yaml",
    "yml",
    "toml",
    "md",
    "ps1",
    "sh",
}


def iso(ts: float) -> str:
    return dt.datetime.fromtimestamp(ts, tz=dt.timezone.utc).astimezone().isoformat()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def iter_monitored_files(home_dir: pathlib.Path) -> Iterable[pathlib.Path]:
    for kind, rel in MONITORED_SPECS:
        abs_path = home_dir / rel
        if kind == "file":
            if abs_path.is_file():
                yield abs_path
            continue

        if not abs_path.is_dir():
            continue

        for current_root, dirnames, filenames in os.walk(abs_path):
            dirnames[:] = sorted(dirnames)
            for filename in sorted(filenames):
                candidate = pathlib.Path(current_root) / filename
                if candidate.is_file():
                    yield candidate


def collect_snapshot(home_dir: pathlib.Path) -> Dict[str, object]:
    files: List[Dict[str, object]] = []
    for path in sorted(iter_monitored_files(home_dir)):
        stat = path.stat()
        files.append(
            {
                "path": path.relative_to(home_dir).as_posix(),
                "size": stat.st_size,
                "mtime": iso(stat.st_mtime),
                "sha256": sha256_file(path),
            }
        )

    return {
        "generatedAt": iso(dt.datetime.now(tz=dt.timezone.utc).timestamp()),
        "homeDir": str(home_dir),
        "monitoredSpecs": [{"kind": kind, "path": rel} for kind, rel in MONITORED_SPECS],
        "fileCount": len(files),
        "files": files,
    }


def write_json(path: pathlib.Path, payload: Dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")


def save_snapshot(snapshot: Dict[str, object]) -> pathlib.Path:
    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    target = SNAPSHOT_DIR / f"snapshot-{timestamp}.json"
    write_json(target, snapshot)
    write_json(BASELINE_FILE, snapshot)
    return target


def load_baseline() -> Dict[str, object]:
    if not BASELINE_FILE.is_file():
        raise SystemExit(
            "Fehler / Error: no baseline found. Run `bash scripts/audit-agent-changes.sh snapshot` first."
        )
    return json.loads(BASELINE_FILE.read_text(encoding="utf-8"))


def file_map(snapshot: Dict[str, object]) -> Dict[str, Dict[str, object]]:
    return {entry["path"]: entry for entry in snapshot.get("files", [])}


def entry_change_mtime(current_entry: Dict[str, object], old_entry: Dict[str, object]) -> str:
    if current_entry:
        return current_entry["mtime"]
    return old_entry["mtime"]


def compare_snapshots(old: Dict[str, object], new: Dict[str, object]) -> Dict[str, List[Dict[str, object]]]:
    old_map = file_map(old)
    new_map = file_map(new)
    added = []
    modified = []
    deleted = []

    for path in sorted(new_map.keys() - old_map.keys()):
        added.append({"path": path, "current": new_map[path], "previous": None, "mtime": new_map[path]["mtime"]})

    for path in sorted(old_map.keys() - new_map.keys()):
        deleted.append({"path": path, "current": None, "previous": old_map[path], "mtime": old_map[path]["mtime"]})

    for path in sorted(new_map.keys() & old_map.keys()):
        if new_map[path]["sha256"] == old_map[path]["sha256"]:
            continue
        modified.append(
            {
                "path": path,
                "current": new_map[path],
                "previous": old_map[path],
                "mtime": entry_change_mtime(new_map[path], old_map[path]),
            }
        )

    return {"added": added, "modified": modified, "deleted": deleted}


def parse_iso(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(value)


def build_terms(changes: Dict[str, List[Dict[str, object]]]) -> List[str]:
    terms: List[str] = []
    seen = set()
    for bucket in ("added", "modified", "deleted"):
        for entry in changes[bucket]:
            relpath = entry["path"]
            basename = pathlib.Path(relpath).name
            candidates = [relpath, basename]
            for part in re.split(r"[\\/._-]+", relpath):
                if len(part) < 3:
                    continue
                lowered = part.lower()
                if lowered in STOP_TERMS:
                    continue
                candidates.append(part)
            for candidate in candidates:
                lowered = candidate.lower()
                if lowered in seen:
                    continue
                seen.add(lowered)
                terms.append(candidate)
    return terms[:24]


def log_candidates(home_dir: pathlib.Path, source_rel: str, window_start: dt.datetime, window_end: dt.datetime) -> List[pathlib.Path]:
    source = home_dir / source_rel
    if source.is_file():
        return [source]
    if not source.is_dir():
        return []

    items: List[Tuple[float, pathlib.Path]] = []
    for current_root, dirnames, filenames in os.walk(source):
        dirnames[:] = sorted(dirnames)
        for filename in sorted(filenames):
            candidate = pathlib.Path(current_root) / filename
            if not candidate.is_file():
                continue
            try:
                mtime = dt.datetime.fromtimestamp(candidate.stat().st_mtime, tz=dt.timezone.utc).astimezone()
            except OSError:
                continue
            if window_start <= mtime <= window_end:
                items.append((candidate.stat().st_mtime, candidate))
    if items:
        return [candidate for _, candidate in sorted(items, reverse=True)[:6]]

    fallback: List[Tuple[float, pathlib.Path]] = []
    for current_root, dirnames, filenames in os.walk(source):
        dirnames[:] = sorted(dirnames)
        for filename in sorted(filenames):
            candidate = pathlib.Path(current_root) / filename
            if candidate.is_file():
                try:
                    fallback.append((candidate.stat().st_mtime, candidate))
                except OSError:
                    pass
    return [candidate for _, candidate in sorted(fallback, reverse=True)[:3]]


def search_terms_in_file(path: pathlib.Path, terms: List[str]) -> List[str]:
    if not terms or not path.is_file():
        return []
    hits: List[str] = []
    term_map = [term.lower() for term in terms]
    try:
        with path.open("r", encoding="utf-8", errors="ignore") as handle:
            for line_no, line in enumerate(handle, start=1):
                lowered = line.lower()
                if any(term in lowered for term in term_map):
                    excerpt = line.strip()
                    if len(excerpt) > 180:
                        excerpt = excerpt[:177] + "..."
                    hits.append(f"{path}:{line_no}: {excerpt}")
                    if len(hits) >= 3:
                        break
    except OSError:
        return hits
    return hits


def app_signals(home_dir: pathlib.Path, terms: List[str], window_start: dt.datetime, window_end: dt.datetime) -> List[Dict[str, object]]:
    signals: List[Dict[str, object]] = []
    for app_name, sources in APP_SOURCES.items():
        recent_sources: List[Dict[str, str]] = []
        hits: List[str] = []
        latest_seen = None
        for source_rel in sources:
            source = home_dir / source_rel
            if not source.exists():
                continue
            try:
                stat = source.stat()
                source_mtime = dt.datetime.fromtimestamp(stat.st_mtime, tz=dt.timezone.utc).astimezone()
            except OSError:
                continue
            if latest_seen is None or source_mtime > latest_seen:
                latest_seen = source_mtime
            if window_start <= source_mtime <= window_end:
                recent_sources.append({"path": source_rel, "mtime": source_mtime.isoformat()})

            for candidate in log_candidates(home_dir, source_rel, window_start, window_end):
                candidate_hits = search_terms_in_file(candidate, terms)
                for hit in candidate_hits:
                    if hit not in hits:
                        hits.append(hit)
                    if len(hits) >= 3:
                        break
                if len(hits) >= 3:
                    break

        signals.append(
            {
                "app": app_name,
                "score": len(hits) * 10 + len(recent_sources),
                "recentSources": recent_sources,
                "matchingHits": hits,
                "latestSeen": latest_seen.isoformat() if latest_seen else None,
            }
        )

    return sorted(signals, key=lambda item: (-item["score"], item["app"]))


def render_human_report(report: Dict[str, object]) -> str:
    lines: List[str] = []
    lines.append("Agent-Audit Report")
    lines.append(f"Home: {report['homeDir']}")
    lines.append(f"Baseline: {report['baselineFile']}")
    lines.append(f"Report: {report['reportFile']}")
    lines.append("")

    summary = report["summary"]
    lines.append(
        "Aenderungen / Changes: "
        f"{summary['added']} hinzugefuegt / added, "
        f"{summary['modified']} geaendert / modified, "
        f"{summary['deleted']} geloescht / deleted"
    )
    lines.append("")

    for label, bucket in (("ADDED", "added"), ("MODIFIED", "modified"), ("DELETED", "deleted")):
        entries = report["changes"][bucket]
        if not entries:
            continue
        lines.append(label)
        for entry in entries:
            lines.append(f"  {entry['path']}  [{entry['mtime']}]")
        lines.append("")

    lines.append("Kandidaten / Candidate app signals")
    signal_found = False
    for signal in report["appSignals"]:
        if signal["score"] <= 0 and not signal["latestSeen"]:
            continue
        signal_found = True
        lines.append(
            f"- {signal['app']}: score={signal['score']}, latest={signal['latestSeen'] or 'n/a'}"
        )
        if signal["recentSources"]:
            for source in signal["recentSources"]:
                lines.append(f"    recent: {source['path']} ({source['mtime']})")
        if signal["matchingHits"]:
            for hit in signal["matchingHits"]:
                lines.append(f"    hit: {hit}")
    if not signal_found:
        lines.append("- Keine zuordenbaren Agent-Log-Signale gefunden / No attributable app signals found.")

    if report.get("baselineRefreshed"):
        lines.append("")
        lines.append(f"Neue Baseline / New baseline: {report['newBaselineFile']}")

    return "\n".join(lines) + "\n"


def main() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    current_snapshot = collect_snapshot(HOME_DIR)

    if ACTION == "snapshot":
        saved_snapshot = save_snapshot(current_snapshot)
        result = {
            "action": "snapshot",
            "homeDir": str(HOME_DIR),
            "baselineFile": str(BASELINE_FILE),
            "snapshotFile": str(saved_snapshot),
            "fileCount": current_snapshot["fileCount"],
        }
        if OUTPUT_JSON:
            print(json.dumps(result, indent=2, ensure_ascii=True))
            return
        print("Agent-Audit Baseline erstellt / baseline created")
        print(f"Home: {HOME_DIR}")
        print(f"Dateien / Files: {current_snapshot['fileCount']}")
        print(f"Baseline: {BASELINE_FILE}")
        print(f"Snapshot: {saved_snapshot}")
        return

    baseline = load_baseline()
    changes = compare_snapshots(baseline, current_snapshot)
    change_times = [parse_iso(entry["mtime"]) for bucket in changes.values() for entry in bucket]
    if change_times:
        window_start = min(change_times) - dt.timedelta(hours=WINDOW_HOURS)
        window_end = max(change_times) + dt.timedelta(hours=WINDOW_HOURS)
    else:
        now = dt.datetime.now().astimezone()
        window_start = now - dt.timedelta(hours=WINDOW_HOURS)
        window_end = now + dt.timedelta(hours=WINDOW_HOURS)

    terms = build_terms(changes)
    signals = app_signals(HOME_DIR, terms, window_start, window_end)

    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    report_file = REPORT_DIR / f"report-{timestamp}.json"
    report = {
        "action": "report",
        "generatedAt": iso(dt.datetime.now(tz=dt.timezone.utc).timestamp()),
        "homeDir": str(HOME_DIR),
        "stateDir": str(STATE_DIR),
        "baselineFile": str(BASELINE_FILE),
        "reportFile": str(report_file),
        "summary": {
            "added": len(changes["added"]),
            "modified": len(changes["modified"]),
            "deleted": len(changes["deleted"]),
        },
        "window": {
            "hours": WINDOW_HOURS,
            "start": window_start.isoformat(),
            "end": window_end.isoformat(),
        },
        "searchTerms": terms,
        "changes": changes,
        "appSignals": signals,
        "baselineRefreshed": False,
    }

    write_json(report_file, report)
    write_json(REPORT_DIR / "latest-report.json", report)

    if REFRESH_BASELINE:
        saved_snapshot = save_snapshot(current_snapshot)
        report["baselineRefreshed"] = True
        report["newBaselineFile"] = str(saved_snapshot)
        write_json(report_file, report)
        write_json(REPORT_DIR / "latest-report.json", report)

    if OUTPUT_JSON:
        print(json.dumps(report, indent=2, ensure_ascii=True))
        return

    print(render_human_report(report), end="")


if __name__ == "__main__":
    main()
PYEOF
