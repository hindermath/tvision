#!/usr/bin/env python3
"""Validate Home Sync v2 selection, migration, and conflict behavior."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[1] / "lib" / "home-sync-files.py"


def identity(path: Path) -> dict[str, str]:
    return {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "mode": "100644"}


class HomeSyncFilesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repository = self.root / "source"
        self.home = self.root / "home"
        self.repository.mkdir()
        self.home.mkdir()
        subprocess.run(["git", "init", "-q", "-b", "main"], cwd=self.repository, check=True)
        subprocess.run(["git", "config", "user.name", "Home Sync Test"], cwd=self.repository, check=True)
        subprocess.run(["git", "config", "user.email", "home-sync@example.invalid"], cwd=self.repository, check=True)
        (self.repository / "runtime.txt").write_text("runtime\n", encoding="utf-8")
        (self.repository / "source-only.txt").write_text("source only\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=self.repository, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "fixture"], cwd=self.repository, check=True)
        self.manifest = self.root / "manifest.json"
        self.state = self.home / ".home-baseline" / "home-sync-state.json"
        self.result = self.home / ".home-baseline" / "home-sync-result.json"
        self.write_manifest()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def selector(root_files: list[str]) -> dict[str, object]:
        return {
            "rootFiles": root_files,
            "rootGlobs": [],
            "trackedPrefixes": [],
            "trackedGlobs": [],
            "excludePaths": [],
            "excludePrefixes": [],
            "excludeGlobs": [],
        }

    def write_manifest(self, legacy_cleanup: list[str] | None = None) -> None:
        value = {
            "schemaVersion": 2,
            "retiredPathPolicy": "preserve",
            "homeRuntime": self.selector(["runtime.txt"]),
            "sourceOnly": self.selector(["source-only.txt"]),
            "machineLocal": self.selector([]),
            "legacyCleanupPaths": legacy_cleanup or [],
        }
        self.manifest.write_text(json.dumps(value), encoding="utf-8")

    def run_sync(self, *mode: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                str(HELPER),
                "sync",
                "--repo",
                str(self.repository),
                "--home",
                str(self.home),
                "--manifest",
                str(self.manifest),
                "--state",
                str(self.state),
                "--result",
                str(self.result),
                *mode,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_initial_sync_copies_only_home_runtime(self) -> None:
        completed = self.run_sync()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual((self.home / "runtime.txt").read_text(encoding="utf-8"), "runtime\n")
        self.assertFalse((self.home / "source-only.txt").exists())
        state = json.loads(self.state.read_text(encoding="utf-8"))
        self.assertEqual(state["schemaVersion"], 2)
        self.assertEqual(state["manifestSchemaVersion"], 2)
        self.assertEqual(set(state["files"]), {"runtime.txt"})

    def test_v1_state_releases_retired_path_without_deleting_it(self) -> None:
        (self.home / "docs").mkdir()
        retired = self.home / "docs" / "old.md"
        retired.write_text("local documentation\n", encoding="utf-8")
        (self.home / "runtime.txt").write_text("runtime\n", encoding="utf-8")
        self.state.parent.mkdir(parents=True)
        self.state.write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "files": {
                        "runtime.txt": identity(self.home / "runtime.txt"),
                        "docs/old.md": identity(retired),
                    },
                }
            ),
            encoding="utf-8",
        )
        original_state = self.state.read_bytes()

        checked = self.run_sync("--check-only")
        self.assertEqual(checked.returncode, 1)
        self.assertIn("[RELEASE] docs/old.md", checked.stdout)
        self.assertEqual(self.state.read_bytes(), original_state)

        completed = self.run_sync()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(retired.read_text(encoding="utf-8"), "local documentation\n")
        state = json.loads(self.state.read_text(encoding="utf-8"))
        self.assertEqual(set(state["files"]), {"runtime.txt"})
        self.assertEqual(state["releasedPaths"], ["docs/old.md"])
        self.assertEqual(self.run_sync("--check-only").returncode, 0)

        (self.repository / "runtime.txt").write_text("runtime updated\n", encoding="utf-8")
        subprocess.run(["git", "add", "runtime.txt"], cwd=self.repository, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "update runtime"], cwd=self.repository, check=True)
        self.assertEqual(self.run_sync().returncode, 0)
        state = json.loads(self.state.read_text(encoding="utf-8"))
        self.assertEqual(state["releasedPaths"], ["docs/old.md"])

    def test_locally_modified_runtime_file_remains_a_conflict(self) -> None:
        self.assertEqual(self.run_sync().returncode, 0)
        (self.home / "runtime.txt").write_text("local override\n", encoding="utf-8")
        completed = self.run_sync()
        self.assertEqual(completed.returncode, 1)
        self.assertIn("[CONFLICT] runtime.txt", completed.stdout)
        self.assertEqual((self.home / "runtime.txt").read_text(encoding="utf-8"), "local override\n")

    def test_target_parent_cannot_escape_home_through_symlink(self) -> None:
        outside = self.root / "outside"
        outside.mkdir()
        (self.repository / "managed").mkdir()
        (self.repository / "managed" / "runtime.txt").write_text("runtime\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=self.repository, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "nested runtime"], cwd=self.repository, check=True)
        self.write_manifest()
        manifest = json.loads(self.manifest.read_text(encoding="utf-8"))
        manifest["homeRuntime"]["trackedPrefixes"] = ["managed/"]
        self.manifest.write_text(json.dumps(manifest), encoding="utf-8")
        (self.home / "managed").symlink_to(outside, target_is_directory=True)

        completed = self.run_sync()
        self.assertEqual(completed.returncode, 2)
        self.assertIn("escapes HOME through a symlink", completed.stderr)
        self.assertEqual(list(outside.iterdir()), [])

    def test_explicit_cleanup_rejects_modified_retired_path(self) -> None:
        retired = self.home / "retired.txt"
        retired.write_text("old managed value\n", encoding="utf-8")
        self.state.parent.mkdir(parents=True)
        old_identity = identity(retired)
        self.state.write_text(
            json.dumps({"schemaVersion": 1, "files": {"retired.txt": old_identity}}),
            encoding="utf-8",
        )
        retired.write_text("local override\n", encoding="utf-8")
        self.write_manifest(["retired.txt"])

        completed = self.run_sync()
        self.assertEqual(completed.returncode, 1)
        self.assertIn("legacy-cleanup-locally-modified", completed.stdout)
        self.assertTrue(retired.exists())


if __name__ == "__main__":
    unittest.main()
