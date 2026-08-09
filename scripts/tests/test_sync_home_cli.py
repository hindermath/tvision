#!/usr/bin/env python3
"""Exercise the sync-home CLI no-op path with the platform Bash version."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[2]
SCRIPT = REPOSITORY / "scripts" / "sync-home.sh"


@unittest.skipIf(os.name == "nt", "The Bash CLI test runs on macOS and Linux.")
class SyncHomeCliTests(unittest.TestCase):
    def run_runtime_only(self, home: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["HOME"] = str(home)
        return subprocess.run(
            ["bash", str(SCRIPT), "--runtime-only", *arguments],
            cwd=REPOSITORY,
            env=environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def test_runtime_only_has_no_git_side_effects_and_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            first = self.run_runtime_only(home)
            self.assertEqual(first.returncode, 0, first.stdout)
            self.assertTrue((home / "scripts" / "sync-home.sh").is_file())
            self.assertFalse((home / ".git").exists())
            self.assertFalse((home / ".gitconfig").exists())
            self.assertFalse((home / ".gitconfig.d").exists())
            self.assertFalse((home / "LICENSE").exists())
            self.assertFalse((home / ".specify" / "presets").exists())

            second = self.run_runtime_only(home)
            self.assertEqual(second.returncode, 0, second.stdout)
            self.assertIn("Managed home files are current", second.stdout)

    def test_runtime_only_rejects_force_and_local_conflicts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            rejected = self.run_runtime_only(home, "--force")
            self.assertEqual(rejected.returncode, 2, rejected.stdout)

            self.assertEqual(self.run_runtime_only(home).returncode, 0)
            target = home / "AGENTS.md"
            target.write_text("local override\n", encoding="utf-8")
            conflict = self.run_runtime_only(home)
            self.assertEqual(conflict.returncode, 1, conflict.stdout)
            self.assertEqual(target.read_text(encoding="utf-8"), "local override\n")

    def test_runtime_only_preview_modes_are_read_only(self) -> None:
        for mode, expected_status in (("--dry-run", 0), ("--check-only", 1)):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                completed = self.run_runtime_only(home, mode)
                self.assertEqual(completed.returncode, expected_status, completed.stdout)
                self.assertEqual(list(home.iterdir()), [])

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell 7 is not installed.")
    def test_powershell_runtime_only_matches_bash_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            completed = subprocess.run(
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "sync-home.ps1"),
                    "-RuntimeOnly",
                ],
                cwd=REPOSITORY,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            self.assertTrue((home / "scripts" / "sync-home.ps1").is_file())
            self.assertFalse((home / ".git").exists())
            self.assertFalse((home / ".gitconfig").exists())

    def test_second_real_sync_is_a_successful_no_op(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            for key, value in (
                ("user.name", "Home Sync Test"),
                ("user.email", "home-sync@example.invalid"),
            ):
                subprocess.run(
                    ["git", "config", "--global", key, value],
                    env=environment,
                    check=True,
                )

            first = subprocess.run(
                ["bash", str(SCRIPT), "--no-pull"],
                cwd=REPOSITORY,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(first.returncode, 0, first.stdout)

            second = subprocess.run(
                ["bash", str(SCRIPT), "--no-pull"],
                cwd=REPOSITORY,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(second.returncode, 0, second.stdout)
            self.assertIn("kein Commit nötig", second.stdout)
            status = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=home,
                text=True,
                stdout=subprocess.PIPE,
                check=True,
            )
            self.assertEqual(status.stdout, "")


if __name__ == "__main__":
    unittest.main()
