#!/usr/bin/env python3
"""Apply the tracked home-sync manifest with conflict and provenance checks."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
from typing import Any


STATE_SCHEMA_VERSION = 2
SUPPORTED_STATE_SCHEMA_VERSIONS = {1, STATE_SCHEMA_VERSION}
SUPPORTED_GIT_MODES = {"100644", "100755"}


class HomeSyncError(RuntimeError):
    """Raised for an unsafe or invalid sync state."""


def run_git(repository: Path, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        ["git", "-C", str(repository), *arguments],
        check=check,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise HomeSyncError(f"Invalid JSON file {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise HomeSyncError(f"JSON root must be an object: {path}")
    return value


def validate_relative_path(value: str, field: str) -> str:
    path = Path(value)
    if not value or path.is_absolute() or ".." in path.parts or "\0" in value:
        raise HomeSyncError(f"Unsafe path in {field}: {value!r}")
    return value.replace("\\", "/")


def string_list(manifest: dict[str, Any], name: str) -> list[str]:
    value = manifest.get(name)
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise HomeSyncError(f"Manifest field {name} must be a string array")
    return [validate_relative_path(item, name) for item in value]


def load_selector(value: Any, name: str) -> dict[str, list[str]]:
    if not isinstance(value, dict):
        raise HomeSyncError(f"Manifest field {name} must be an object")
    required = (
        "rootFiles",
        "rootGlobs",
        "trackedPrefixes",
        "trackedGlobs",
        "excludePaths",
        "excludePrefixes",
        "excludeGlobs",
    )
    return {field: string_list(value, field) for field in required}


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = load_json(path)
    schema_version = manifest.get("schemaVersion")
    if schema_version == 1:
        required = (
            "rootFiles",
            "rootGlobs",
            "trackedPrefixes",
            "trackedGlobs",
            "excludePaths",
            "excludePrefixes",
            "excludeGlobs",
        )
        normalized = {name: string_list(manifest, name) for name in required}
    elif schema_version == 2:
        normalized = load_selector(manifest.get("homeRuntime"), "homeRuntime")
        load_selector(manifest.get("sourceOnly"), "sourceOnly")
        load_selector(manifest.get("machineLocal"), "machineLocal")
        if manifest.get("retiredPathPolicy") != "preserve":
            raise HomeSyncError("home-sync v2 retiredPathPolicy must be 'preserve'")
    else:
        raise HomeSyncError("home-sync manifest schemaVersion must be 1 or 2")
    normalized["legacyCleanupPaths"] = string_list(manifest, "legacyCleanupPaths")
    normalized["schemaVersion"] = schema_version
    return normalized


def tracked_files(repository: Path) -> dict[str, str]:
    result = run_git(repository, "ls-files", "--stage", "-z")
    files: dict[str, str] = {}
    for raw_record in result.stdout.split(b"\0"):
        if not raw_record:
            continue
        try:
            metadata, raw_path = raw_record.split(b"\t", 1)
            mode = metadata.split(b" ", 1)[0].decode("ascii")
            relative_path = raw_path.decode("utf-8")
        except (ValueError, UnicodeDecodeError) as exc:
            raise HomeSyncError("Unable to parse git ls-files output") from exc
        validate_relative_path(relative_path, "git ls-files")
        if mode not in SUPPORTED_GIT_MODES:
            continue
        files[relative_path] = mode
    return files


def matches_manifest(path: str, manifest: dict[str, Any]) -> bool:
    root_match = "/" not in path and (
        path in manifest["rootFiles"]
        or any(fnmatch.fnmatchcase(path, pattern) for pattern in manifest["rootGlobs"])
    )
    included = root_match or any(path.startswith(prefix) for prefix in manifest["trackedPrefixes"])
    included = included or any(fnmatch.fnmatchcase(path, pattern) for pattern in manifest["trackedGlobs"])
    if not included:
        return False
    if path in manifest["excludePaths"]:
        return False
    if any(path.startswith(prefix) for prefix in manifest["excludePrefixes"]):
        return False
    return not any(fnmatch.fnmatchcase(path, pattern) for pattern in manifest["excludeGlobs"])


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_identity(path: Path) -> dict[str, str] | None:
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        return None
    if stat.S_ISLNK(metadata.st_mode):
        return {
            "sha256": hashlib.sha256(os.readlink(path).encode("utf-8")).hexdigest(),
            "mode": "120000",
        }
    if not stat.S_ISREG(metadata.st_mode):
        return {"sha256": "", "mode": "unsupported"}
    mode = "100755" if metadata.st_mode & 0o111 else "100644"
    return {"sha256": sha256_file(path), "mode": mode}


def identities_equal(left: dict[str, str] | None, right: dict[str, str] | None) -> bool:
    if left is None or right is None:
        return left is right
    if left.get("sha256") != right.get("sha256"):
        return False
    return os.name == "nt" or left.get("mode") == right.get("mode")


def load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"schemaVersion": STATE_SCHEMA_VERSION, "files": {}, "releasedPaths": []}
    state = load_json(path)
    if state.get("schemaVersion") not in SUPPORTED_STATE_SCHEMA_VERSIONS or not isinstance(state.get("files"), dict):
        raise HomeSyncError(f"Unsupported home-sync state: {path}")
    for relative_path, identity in state["files"].items():
        validate_relative_path(relative_path, "state files")
        if not isinstance(identity, dict) or set(identity) != {"sha256", "mode"}:
            raise HomeSyncError(f"Invalid state identity for {relative_path}")
    released_paths = state.get("releasedPaths", [])
    if not isinstance(released_paths, list) or not all(isinstance(item, str) for item in released_paths):
        raise HomeSyncError(f"Invalid releasedPaths in home-sync state: {path}")
    state["releasedPaths"] = [validate_relative_path(item, "releasedPaths") for item in released_paths]
    return state


def safe_target(home: Path, relative_path: str) -> Path:
    target = home / relative_path
    resolved_home = home.resolve()
    resolved_parent = target.parent.resolve(strict=False)
    try:
        resolved_parent.relative_to(resolved_home)
    except ValueError as exc:
        raise HomeSyncError(f"Target parent escapes HOME through a symlink: {relative_path}") from exc
    return target


def clean_tracked_home_path(home: Path, relative_path: str) -> bool:
    inside = run_git(home, "rev-parse", "--is-inside-work-tree", check=False)
    if inside.returncode != 0:
        return False
    tracked = run_git(home, "ls-files", "--error-unmatch", "--", relative_path, check=False)
    if tracked.returncode != 0:
        return False
    status_result = run_git(home, "status", "--porcelain", "--", relative_path)
    return not status_result.stdout.strip()


def source_files(repository: Path, manifest: dict[str, Any]) -> dict[str, dict[str, str]]:
    selected: dict[str, dict[str, str]] = {}
    for relative_path, mode in tracked_files(repository).items():
        if not matches_manifest(relative_path, manifest):
            continue
        source = repository / relative_path
        if not source.is_file() or source.is_symlink():
            raise HomeSyncError(f"Managed source is not a regular file: {relative_path}")
        selected[relative_path] = {"sha256": sha256_file(source), "mode": mode}
    return dict(sorted(selected.items()))


def build_plan(
    repository: Path,
    home: Path,
    manifest: dict[str, Any],
    previous: dict[str, Any],
    force: bool,
) -> dict[str, Any]:
    sources = source_files(repository, manifest)
    previous_files: dict[str, dict[str, str]] = previous["files"]
    actions: list[dict[str, Any]] = []
    conflicts: list[dict[str, str]] = []
    preserved: list[dict[str, str]] = []
    released: list[dict[str, str]] = []

    for relative_path, source_identity in sources.items():
        target = safe_target(home, relative_path)
        current = file_identity(target)
        if current is None:
            actions.append({"action": "copy", "path": relative_path, "reason": "missing", "expected": None})
        elif identities_equal(current, source_identity):
            continue
        elif relative_path in previous_files and identities_equal(current, previous_files[relative_path]):
            actions.append(
                {"action": "copy", "path": relative_path, "reason": "source-updated", "expected": current}
            )
        elif force:
            actions.append({"action": "copy", "path": relative_path, "reason": "forced", "expected": current})
        else:
            reason = "initial-target-differs" if relative_path not in previous_files else "locally-modified"
            conflicts.append({"path": relative_path, "reason": reason})

    for relative_path, old_identity in sorted(previous_files.items()):
        if relative_path in sources:
            continue
        target = safe_target(home, relative_path)
        current = file_identity(target)
        if current is None:
            continue
        if relative_path in manifest["legacyCleanupPaths"]:
            if identities_equal(current, old_identity) or force:
                actions.append(
                    {"action": "delete", "path": relative_path, "reason": "explicit-legacy-cleanup", "expected": current}
                )
            else:
                conflicts.append({"path": relative_path, "reason": "legacy-cleanup-locally-modified"})
        else:
            # Ein engeres Manifest gibt alte Ziele frei, statt sie zu loeschen.
            # A narrower manifest releases former targets instead of deleting them.
            released.append({"path": relative_path, "reason": "retired-from-home-runtime"})

    action_paths = {entry["path"] for entry in actions}
    for relative_path in manifest["legacyCleanupPaths"]:
        if relative_path in sources or relative_path in previous_files or relative_path in action_paths:
            continue
        target = safe_target(home, relative_path)
        if file_identity(target) is None:
            continue
        if clean_tracked_home_path(home, relative_path):
            actions.append(
                {
                    "action": "delete",
                    "path": relative_path,
                    "reason": "clean-legacy",
                    "expected": file_identity(target),
                }
            )
        else:
            preserved.append({"path": relative_path, "reason": "legacy-local-or-untracked"})

    return {
        "sources": sources,
        "actions": sorted(actions, key=lambda item: (item["path"], item["action"])),
        "conflicts": sorted(conflicts, key=lambda item: item["path"]),
        "preserved": sorted(preserved, key=lambda item: item["path"]),
        "released": sorted(released, key=lambda item: item["path"]),
    }


def print_plan(plan: dict[str, Any]) -> None:
    labels = {"copy": "COPY", "delete": "DELETE"}
    for action in plan["actions"]:
        print(f"  [{labels[action['action']]}] {action['path']} ({action['reason']})")
    for conflict in plan["conflicts"]:
        print(f"  [CONFLICT] {conflict['path']} ({conflict['reason']})")
    for preserved in plan["preserved"]:
        print(f"  [KEEP] {preserved['path']} ({preserved['reason']})")
    for released in plan["released"]:
        print(f"  [RELEASE] {released['path']} ({released['reason']})")
    if not plan["actions"] and not plan["conflicts"] and not plan["preserved"] and not plan["released"]:
        print("  [OK] Managed home files are current / Verwaltete Home-Dateien sind aktuell")


def atomic_json_write(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as stream:
            json.dump(value, stream, ensure_ascii=True, indent=2, sort_keys=True)
            stream.write("\n")
        os.replace(temporary_name, path)
    except BaseException:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def atomic_copy(source: Path, target: Path, mode: str) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(prefix=f".{target.name}.home-sync-", dir=target.parent)
    os.close(file_descriptor)
    temporary_path = Path(temporary_name)
    try:
        shutil.copyfile(source, temporary_path)
        if os.name != "nt":
            temporary_path.chmod(0o755 if mode == "100755" else 0o644)
        os.replace(temporary_path, target)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def apply_plan(repository: Path, home: Path, plan: dict[str, Any]) -> list[str]:
    changed: list[str] = []
    for action in plan["actions"]:
        relative_path = action["path"]
        target = safe_target(home, relative_path)
        if not identities_equal(file_identity(target), action["expected"]):
            raise HomeSyncError(f"Target changed after preflight: {relative_path}")
        if action["action"] == "copy":
            source = repository / relative_path
            planned_identity = plan["sources"][relative_path]
            current_source = {"sha256": sha256_file(source), "mode": planned_identity["mode"]}
            if not identities_equal(current_source, planned_identity):
                raise HomeSyncError(f"Source changed after preflight: {relative_path}")
            atomic_copy(source, target, planned_identity["mode"])
        else:
            target.unlink()
        changed.append(relative_path)
    return changed


def write_state(
    state_path: Path,
    result_path: Path,
    repository: Path,
    home: Path,
    source_commit: str,
    sources: dict[str, dict[str, str]],
    changed_paths: list[str],
    manifest_schema_version: int,
    released_paths: list[str],
) -> None:
    for relative_path, expected in sources.items():
        if not identities_equal(file_identity(safe_target(home, relative_path)), expected):
            raise HomeSyncError(f"Post-sync verification failed: {relative_path}")
    timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    state = {
        "schemaVersion": STATE_SCHEMA_VERSION,
        "sourcePath": str(repository.resolve()),
        "sourceCommit": source_commit,
        "syncedAt": timestamp,
        "manifestSchemaVersion": manifest_schema_version,
        "files": sources,
        "releasedPaths": sorted(set(released_paths)),
    }
    atomic_json_write(state_path, state)
    atomic_json_write(
        result_path,
        {
            "schemaVersion": STATE_SCHEMA_VERSION,
            "sourceCommit": source_commit,
            "completedAt": timestamp,
            "changedPaths": sorted(set(changed_paths)),
            "releasedPaths": sorted(set(released_paths)),
        },
    )


def sync_command(arguments: argparse.Namespace) -> int:
    repository = Path(arguments.repo).expanduser().resolve()
    home = Path(arguments.home).expanduser().resolve()
    manifest_path = Path(arguments.manifest).expanduser().resolve()
    state_path = Path(arguments.state).expanduser().resolve()
    result_path = Path(arguments.result).expanduser().resolve()
    if not repository.is_dir() or not home.is_dir():
        raise HomeSyncError("Repository and HOME must exist as directories")

    manifest = load_manifest(manifest_path)
    previous = load_state(state_path)
    source_commit = run_git(repository, "rev-parse", "HEAD").stdout.decode("ascii").strip()
    plan = build_plan(repository, home, manifest, previous, arguments.force)
    print_plan(plan)
    has_drift = bool(plan["actions"] or plan["conflicts"] or plan["preserved"] or plan["released"])

    if arguments.check_only:
        return 1 if has_drift else 0
    if arguments.dry_run:
        return 0
    if plan["conflicts"]:
        print("Sync aborted before writing; use --force only after reviewing conflicts.", file=sys.stderr)
        return 1

    changed_paths = apply_plan(repository, home, plan)
    write_state(
        state_path,
        result_path,
        repository,
        home,
        source_commit,
        plan["sources"],
        changed_paths,
        manifest["schemaVersion"],
        previous["releasedPaths"] + [item["path"] for item in plan["released"]],
    )
    return 0


def emit_changed_command(arguments: argparse.Namespace) -> int:
    result = load_json(Path(arguments.result).expanduser().resolve())
    paths = result.get("changedPaths")
    if not isinstance(paths, list) or not all(isinstance(path, str) for path in paths):
        raise HomeSyncError("Invalid home-sync result file")
    for relative_path in paths:
        validate_relative_path(relative_path, "changedPaths")
        sys.stdout.buffer.write(relative_path.encode("utf-8") + b"\0")
    return 0


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    sync_parser = subparsers.add_parser("sync", help="check, preview, or apply managed files")
    sync_parser.add_argument("--repo", required=True)
    sync_parser.add_argument("--home", required=True)
    sync_parser.add_argument("--manifest", required=True)
    sync_parser.add_argument("--state", required=True)
    sync_parser.add_argument("--result", required=True)
    mode = sync_parser.add_mutually_exclusive_group()
    mode.add_argument("--check-only", action="store_true")
    mode.add_argument("--dry-run", action="store_true")
    sync_parser.add_argument("--force", action="store_true")

    emit_parser = subparsers.add_parser("emit-changed", help="emit changed paths as NUL records")
    emit_parser.add_argument("--result", required=True)
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    try:
        if arguments.command == "emit-changed":
            return emit_changed_command(arguments)
        return sync_command(arguments)
    except (HomeSyncError, OSError, subprocess.CalledProcessError) as exc:
        print(f"home-sync error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
