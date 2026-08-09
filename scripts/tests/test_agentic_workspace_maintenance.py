#!/usr/bin/env python3
"""Exercise desired-state maintenance against local, disposable Git remotes."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[2]
ENGINE = REPOSITORY / "scripts" / "lib" / "agentic_workspace_fleet.py"


def bash_path(path: Path) -> str:
    """Translate an absolute Windows path for the installed Git-Bash surface."""
    resolved = path.resolve()
    if os.name != "nt":
        return str(resolved)
    drive = resolved.drive.rstrip(":").lower()
    remainder = resolved.as_posix().split(":", 1)[1].lstrip("/")
    return f"/mnt/{drive}/{remainder}"


def git(repository: Path | None, *arguments: str) -> str:
    command = ["git"]
    if repository is not None:
        command.extend(["-C", str(repository)])
    command.extend(arguments)
    return subprocess.check_output(command, text=True).strip()


class FleetFixture:
    def __init__(self, root: Path, default_branch: str = "main") -> None:
        self.root = root
        self.default_branch = default_branch
        self.home = root / "home"
        self.home.mkdir()
        self.remote = root / "remote.git"
        subprocess.run(["git", "init", "--bare", "-q", str(self.remote)], check=True)
        self.seed = root / "seed"
        subprocess.run(["git", "clone", "-q", str(self.remote), str(self.seed)], check=True)
        git(self.seed, "config", "user.name", "Fixture")
        git(self.seed, "config", "user.email", "fixture@example.invalid")
        git(self.seed, "switch", "-c", default_branch)
        (self.seed / "README.md").write_text("baseline\n", encoding="utf-8")
        git(self.seed, "add", "README.md")
        git(self.seed, "commit", "-q", "-m", "baseline")
        git(self.seed, "push", "-q", "-u", "origin", default_branch)
        subprocess.run(
            [
                "git",
                "--git-dir",
                str(self.remote),
                "symbolic-ref",
                "HEAD",
                f"refs/heads/{default_branch}",
            ],
            check=True,
        )

    def manifest(self, remote: str | None = None, path: str = "Fleet/Example") -> Path:
        content = {
            "schemaVersion": "1.0",
            "targets": [
                {
                    "id": "fleet",
                    "kind": "collection",
                    "level": 1,
                    "path": "Fleet",
                    "active": True,
                    "maintenanceClass": "canonical-fleet",
                    "memberDiscovery": "declared-targets",
                },
                {
                    "id": "example",
                    "kind": "git-repository",
                    "level": 2,
                    "path": path,
                    "active": True,
                    "maintenanceClass": "canonical-fleet",
                    "remote": remote or str(self.remote),
                    "forge": "generic-git",
                    "defaultBranch": self.default_branch,
                },
            ],
        }
        target = self.root / "manifest.json"
        target.write_text(json.dumps(content), encoding="utf-8")
        return target

    def run(
        self,
        mode: str,
        manifest: Path | None = None,
        allowed_dirty_paths: tuple[str, ...] = (),
        level0_dir: Path | None = None,
    ) -> tuple[subprocess.CompletedProcess[str], dict]:
        report = self.root / f"report-{mode}.json"
        log = self.root / f"run-{mode}.log"
        command = [
                "python3",
                str(ENGINE),
                "fleet",
                "--manifest",
                str(manifest or self.manifest()),
                "--home-dir",
                str(self.home),
                "--mode",
                mode,
                "--report",
                str(report),
                "--log",
                str(log),
            ]
        for path in allowed_dirty_paths:
            command.extend(["--allowed-dirty-path", path])
        if level0_dir is not None:
            command.extend(["--level0-dir", str(level0_dir)])
        completed = subprocess.run(
            command,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return completed, json.loads(report.read_text(encoding="utf-8"))


class AgenticWorkspaceMaintenanceTests(unittest.TestCase):
    def run_engine(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(ENGINE), *arguments],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def create_lease(
        self,
        fixture: FleetFixture,
        state_root: Path,
        lease: Path,
        worktree: Path,
        *,
        run_id: str = "fixture-run",
        owner_pid: int | None = None,
        owner_identity: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        checkout = fixture.home / "Fleet" / "Example"
        arguments = [
            "lease-create",
            "--state-root",
            str(state_root),
            "--lease",
            str(lease),
            "--run-id",
            run_id,
            "--owner-pid",
            str(owner_pid or os.getpid()),
            "--repository",
            str(checkout),
            "--remote-ref",
            f"refs/remotes/origin/{fixture.default_branch}",
            "--commit",
            git(checkout, "rev-parse", f"origin/{fixture.default_branch}"),
            "--worktree",
            str(worktree),
        ]
        if owner_identity is not None:
            arguments.extend(["--owner-process-identity", owner_identity])
        return self.run_engine(*arguments)

    def test_dirty_repository_fetches_before_it_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            local = checkout / "local.txt"
            local.write_text("keep me\n", encoding="utf-8")
            status_before = git(checkout, "status", "--porcelain=v1", "-uall")

            (fixture.seed / "README.md").write_text("remote update\n", encoding="utf-8")
            git(fixture.seed, "add", "README.md")
            git(fixture.seed, "commit", "-q", "-m", "remote update")
            git(fixture.seed, "push", "-q")
            remote_head = git(fixture.seed, "rev-parse", "HEAD")

            completed, report = fixture.run("check-only")

            self.assertEqual(completed.returncode, 1, completed.stdout)
            target = next(item for item in report["targets"] if item["targetId"] == "example")
            self.assertEqual(target["status"], "DIRTY")
            self.assertEqual(target["freshnessAttempt"]["status"], "Succeeded")
            self.assertEqual(git(checkout, "rev-parse", "origin/main"), remote_head)
            self.assertEqual(git(checkout, "status", "--porcelain=v1", "-uall"), status_before)

    def test_remote_symbolic_trunk_is_resolved_without_local_origin_head(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory), default_branch="trunk")
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            subprocess.run(
                ["git", "-C", str(checkout), "update-ref", "-d", "refs/remotes/origin/HEAD"],
                check=True,
            )

            completed, report = fixture.run("check-only")

            self.assertEqual(completed.returncode, 0, completed.stdout)
            target = next(item for item in report["targets"] if item["targetId"] == "example")
            self.assertEqual(target["defaultBranchEvidence"]["symbolicRef"], "refs/heads/trunk")
            self.assertEqual(target["defaultBranchEvidence"]["trackingRef"], "refs/remotes/origin/trunk")

    def test_default_head_failures_block_without_branch_name_guessing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            subprocess.run(
                ["git", "-C", str(checkout), "update-ref", "-d", "refs/remotes/origin/HEAD"],
                check=True,
            )
            subprocess.run(
                ["git", "--git-dir", str(fixture.remote), "symbolic-ref", "HEAD", "refs/heads/missing"],
                check=True,
            )

            completed, report = fixture.run("check-only")

            self.assertEqual(completed.returncode, 1, completed.stdout)
            target = next(item for item in report["targets"] if item["targetId"] == "example")
            self.assertEqual(target["status"], "REMOTE_HEAD_INVALID")
            self.assertIsNone(target["defaultBranchEvidence"])
            self.assertNotIn("main", target["nextAction"].lower())

    def test_remote_head_commit_mismatch_blocks_stale_tracking_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            subprocess.run(
                ["git", "-C", str(checkout), "update-ref", "-d", "refs/remotes/origin/HEAD"],
                check=True,
            )
            git(fixture.seed, "branch", "not-selected")
            git(fixture.seed, "push", "-q", "origin", "not-selected")
            git(
                checkout,
                "config",
                "remote.origin.fetch",
                "+refs/heads/not-selected:refs/remotes/origin/not-selected",
            )
            (fixture.seed / "README.md").write_text("new remote head\n", encoding="utf-8")
            git(fixture.seed, "add", "README.md")
            git(fixture.seed, "commit", "-q", "-m", "advance remote")
            git(fixture.seed, "push", "-q")

            completed, report = fixture.run("check-only")

            self.assertEqual(completed.returncode, 1, completed.stdout)
            target = next(item for item in report["targets"] if item["targetId"] == "example")
            self.assertEqual(target["status"], "REMOTE_HEAD_INVALID")
            self.assertEqual(target["findingCode"], "RemoteCommitMismatch")
            self.assertIsNone(target["defaultBranchEvidence"])

    def test_owned_worktree_lease_releases_normally_and_idempotently(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            state_root = fixture.root / "state"
            lease = state_root / "leases" / "normal.json"
            worktree = state_root / "worktrees" / "normal" / "worktree"
            created = self.create_lease(fixture, state_root, lease, worktree)
            self.assertEqual(created.returncode, 0, created.stdout)
            payload = json.loads(lease.read_text(encoding="utf-8"))
            self.assertEqual(set(payload), {
                "schemaVersion", "runId", "ownerPid", "ownerProcessStartedAt",
                "repository", "remoteRef", "commit", "worktreePath", "leasePath",
                "createdAt",
            })
            subprocess.run(
                ["git", "-C", str(checkout), "worktree", "add", "--detach", str(worktree), payload["commit"]],
                check=True,
                stdout=subprocess.DEVNULL,
            )

            released = self.run_engine(
                "lease-release", "--state-root", str(state_root),
                "--lease", str(lease), "--run-id", "fixture-run",
            )
            repeated = self.run_engine(
                "lease-release", "--state-root", str(state_root),
                "--lease", str(lease), "--run-id", "fixture-run",
            )

            self.assertEqual(released.returncode, 0, released.stdout)
            self.assertEqual(repeated.returncode, 0, repeated.stdout)
            self.assertFalse(lease.exists())
            self.assertFalse(worktree.exists())

    def test_orphaned_lease_recovers_once_but_active_and_pid_reuse_remain(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            state_root = fixture.root / "state"
            lease_dir = state_root / "leases"

            orphan = lease_dir / "orphan.json"
            orphan_worktree = state_root / "worktrees" / "orphan" / "worktree"
            self.assertEqual(
                self.create_lease(
                    fixture, state_root, orphan, orphan_worktree,
                    owner_pid=99999999, owner_identity="fixture-dead",
                ).returncode,
                0,
            )
            orphan_payload = json.loads(orphan.read_text(encoding="utf-8"))
            subprocess.run(
                ["git", "-C", str(checkout), "worktree", "add", "--detach",
                 str(orphan_worktree), orphan_payload["commit"]],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            recovered = self.run_engine(
                "lease-recover", "--state-root", str(state_root),
                "--lease-dir", str(lease_dir),
            )
            repeated = self.run_engine(
                "lease-recover", "--state-root", str(state_root),
                "--lease-dir", str(lease_dir),
            )
            self.assertEqual(recovered.returncode, 0, recovered.stdout)
            self.assertEqual(repeated.returncode, 0, repeated.stdout)
            self.assertFalse(orphan.exists())

            active = lease_dir / "active.json"
            active_worktree = state_root / "worktrees" / "active" / "worktree"
            self.assertEqual(
                self.create_lease(fixture, state_root, active, active_worktree).returncode,
                0,
            )
            active_payload = json.loads(active.read_text(encoding="utf-8"))
            subprocess.run(
                ["git", "-C", str(checkout), "worktree", "add", "--detach",
                 str(active_worktree), active_payload["commit"]],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            active_result = self.run_engine(
                "lease-recover", "--state-root", str(state_root),
                "--lease-dir", str(lease_dir),
            )
            self.assertEqual(active_result.returncode, 0, active_result.stdout)
            self.assertTrue(active.exists())
            self.assertTrue(active_worktree.exists())
            self.assertEqual(
                self.run_engine(
                    "lease-release", "--state-root", str(state_root),
                    "--lease", str(active), "--run-id", "fixture-run",
                ).returncode,
                0,
            )

            reused = lease_dir / "reused.json"
            reused_worktree = state_root / "worktrees" / "reused" / "worktree"
            self.assertEqual(
                self.create_lease(
                    fixture, state_root, reused, reused_worktree,
                    owner_identity="forged-start",
                ).returncode,
                0,
            )
            reused_payload = json.loads(reused.read_text(encoding="utf-8"))
            subprocess.run(
                ["git", "-C", str(checkout), "worktree", "add", "--detach",
                 str(reused_worktree), reused_payload["commit"]],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            reused_result = self.run_engine(
                "lease-recover", "--state-root", str(state_root),
                "--lease-dir", str(lease_dir),
            )
            self.assertEqual(reused_result.returncode, 1, reused_result.stdout)
            self.assertTrue(reused.exists())
            self.assertTrue(reused_worktree.exists())

    def test_lease_rejects_path_escape_foreign_repository_and_new_untracked_data(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            state_root = fixture.root / "state"
            escaped = self.create_lease(
                fixture, state_root, state_root / "leases" / "escape.json",
                fixture.root / "outside" / "worktree",
            )
            self.assertEqual(escaped.returncode, 2, escaped.stdout)

            lease = state_root / "leases" / "changed.json"
            worktree = state_root / "worktrees" / "changed" / "worktree"
            self.assertEqual(self.create_lease(fixture, state_root, lease, worktree).returncode, 0)
            payload = json.loads(lease.read_text(encoding="utf-8"))
            subprocess.run(
                ["git", "-C", str(checkout), "worktree", "add", "--detach",
                 str(worktree), payload["commit"]],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            (worktree / "new-evidence.txt").write_text("must survive\n", encoding="utf-8")
            release = self.run_engine(
                "lease-release", "--state-root", str(state_root),
                "--lease", str(lease), "--run-id", "fixture-run",
            )
            self.assertEqual(release.returncode, 1, release.stdout)
            self.assertTrue((worktree / "new-evidence.txt").exists())
            self.assertTrue(lease.exists())

            payload["repository"] = str(fixture.seed)
            payload["ownerPid"] = 99999999
            payload["ownerProcessStartedAt"] = "fixture-dead"
            lease.write_text(json.dumps(payload), encoding="utf-8")
            recovery = self.run_engine(
                "lease-recover", "--state-root", str(state_root),
                "--lease-dir", str(lease.parent),
            )
            self.assertEqual(recovery.returncode, 1, recovery.stdout)
            self.assertTrue((worktree / "new-evidence.txt").exists())

    def test_fleet_failure_does_not_skip_later_target_inventory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            content = json.loads(fixture.manifest().read_text(encoding="utf-8"))
            missing = dict(content["targets"][1])
            missing.update(
                {
                    "id": "missing",
                    "path": "Fleet/Missing",
                    "remote": str(fixture.root / "missing.git"),
                }
            )
            content["targets"].insert(1, missing)
            manifest = fixture.root / "multi-manifest.json"
            manifest.write_text(json.dumps(content), encoding="utf-8")

            completed, report = fixture.run("check-only", manifest)

            self.assertEqual(completed.returncode, 1, completed.stdout)
            self.assertEqual(
                [item["targetId"] for item in report["targets"]],
                ["fleet", "missing", "example"],
            )
            self.assertEqual(
                next(item for item in report["targets"] if item["targetId"] == "example")["status"],
                "CURRENT",
            )

    def test_orchestrators_place_domain_mutations_after_fleet_barrier(self) -> None:
        bash = (REPOSITORY / "scripts" / "maintain-agentic-workspace.sh").read_text(
            encoding="utf-8"
        )
        powershell = (
            REPOSITORY / "scripts" / "maintain-agentic-workspace.ps1"
        ).read_text(encoding="utf-8")
        self.assertLess(
            bash.index('CURRENT_STAGE="fleet"'),
            bash.index("Lokale Home-Baseline synchronisieren"),
        )
        self.assertLess(
            powershell.index("Soll-Flotte pruefen und sicher warten"),
            powershell.index("Lokale Home-Baseline synchronisieren"),
        )

    def test_target_repository_boundary_has_no_delivery_commands(self) -> None:
        engine = ENGINE.read_text(encoding="utf-8")
        for prohibited in (
            'run_git(repository, "commit"',
            'run_git(repository, "push"',
            'run_git(repository, "merge"',
            'run_git(repository, "checkout"',
            'run_git(repository, "switch"',
            '"pr", "create"',
        ):
            self.assertNotIn(prohibited, engine)
        bash = (REPOSITORY / "scripts" / "maintain-agentic-workspace.sh").read_text(
            encoding="utf-8"
        )
        powershell = (
            REPOSITORY / "scripts" / "maintain-agentic-workspace.ps1"
        ).read_text(encoding="utf-8")
        self.assertNotIn("git worktree remove --force", bash)
        self.assertNotIn("Remove-Item -LiteralPath $Target.Root -Recurse", powershell)

    def test_secure_casetracker_uses_the_declared_workspace_paths_only(self) -> None:
        manifest_path = REPOSITORY / "scripts" / "config" / "agentic-workspace-fleet.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        targets = {
            item["id"]: item["path"]
            for item in manifest["targets"]
            if item["id"].startswith("secure-casetracker")
        }
        self.assertEqual(
            targets,
            {
                "secure-casetracker-baseline": "SecureCaseTrackerProjects",
                "secure-casetracker-csharp": "SecureCaseTrackerProjects/SecureCaseTracker-CSharp",
                "secure-casetracker-go": "SecureCaseTrackerProjects/SecureCaseTracker-Go",
                "secure-casetracker-java": "SecureCaseTrackerProjects/SecureCaseTracker-Java",
                "secure-casetracker-python": "SecureCaseTrackerProjects/SecureCaseTracker-Python",
                "secure-casetracker-rust": "SecureCaseTrackerProjects/SecureCaseTracker-Rust",
                "secure-casetracker-swift": "SecureCaseTrackerProjects/SecureCaseTracker-Swift",
            },
        )
        self.assertFalse(
            any(
                path == "secure-casetracker-baseline"
                or path.startswith("secure-casetracker-baseline/")
                for path in targets.values()
            )
        )

    def test_clion_workspace_and_tvision_fork_are_declared(self) -> None:
        manifest_path = REPOSITORY / "scripts" / "config" / "agentic-workspace-fleet.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        targets = {item["id"]: item for item in manifest["targets"]}

        self.assertEqual(
            targets["clion-projects"],
            {
                "id": "clion-projects",
                "kind": "git-repository",
                "level": 1,
                "path": "CLionProjects",
                "active": True,
                "maintenanceClass": "canonical-fleet",
                "remote": "https://github.com/hindermath/clion-baseline.git",
                "forge": "github",
                "defaultBranch": "main",
            },
        )
        self.assertEqual(
            targets["tvision"],
            {
                "id": "tvision",
                "kind": "git-repository",
                "level": 2,
                "path": "CLionProjects/tvision",
                "active": True,
                "maintenanceClass": "canonical-fleet",
                "remote": "https://github.com/hindermath/tvision.git",
                "forge": "github",
                "defaultBranch": "master",
            },
        )

    @unittest.skipIf(os.name == "nt", "This local fixture invokes the installed PowerShell on Unix.")
    def test_powershell_surface_exposes_approved_cmdlet_and_manifest_parameter(self) -> None:
        completed = subprocess.run(
            [
                "pwsh",
                "-NoProfile",
                "-Command",
                ". ./scripts/maintain-agentic-workspace.ps1; "
                "$command = Get-Command Invoke-HBAgenticWorkspaceMaintenance; "
                "if (-not $command.Parameters.ContainsKey('ManifestPath')) { exit 1 }; "
                "if (-not $command.Parameters.ContainsKey('AllowAdminPrompts')) { exit 1 }",
            ],
            cwd=REPOSITORY,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stdout)

    def test_check_only_and_dry_run_do_not_create_missing_targets(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            for mode, expected_action in (("check-only", "CLONE_REQUIRED"), ("dry-run", "WOULD_CLONE")):
                completed, report = fixture.run(mode)
                self.assertEqual(completed.returncode, 1)
                self.assertFalse((fixture.home / "Fleet" / "Example").exists())
                target = next(item for item in report["targets"] if item["targetId"] == "example")
                self.assertEqual(target["action"], expected_action)

    def test_update_clones_once_and_second_run_is_current(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            first, first_report = fixture.run("update")
            self.assertEqual(first.returncode, 0, first.stdout)
            self.assertEqual(first_report["overallStatus"], "SUCCESS")
            barrier = first_report["mutationBarrier"]
            self.assertEqual(barrier["expectedGitTargets"], 1)
            self.assertEqual(barrier["completedGitTargets"], 1)
            self.assertEqual(barrier["collectionTargets"], 1)
            self.assertIs(barrier["allFetchAttemptsCompleted"], True)
            self.assertIs(barrier["fleetReady"], True)
            self.assertIs(barrier["domainMutationAllowed"], True)
            self.assertEqual(
                [item["kind"] for item in first_report["operations"]],
                ["inventory", "clone", "mutation-barrier"],
            )
            checkout = fixture.home / "Fleet" / "Example"
            self.assertTrue((checkout / ".git").exists())
            first_head = git(checkout, "rev-parse", "HEAD")

            second, second_report = fixture.run("update")
            self.assertEqual(second.returncode, 0, second.stdout)
            self.assertEqual(git(checkout, "rev-parse", "HEAD"), first_head)
            target = next(item for item in second_report["targets"] if item["targetId"] == "example")
            self.assertEqual(target["status"], "CURRENT")
            self.assertEqual(target["action"], "NONE")

    def test_behind_updates_but_dirty_and_path_conflict_remain_unchanged(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            (fixture.seed / "README.md").write_text("updated\n", encoding="utf-8")
            git(fixture.seed, "add", "README.md")
            git(fixture.seed, "commit", "-q", "-m", "update")
            git(fixture.seed, "push", "-q")
            updated_head = git(fixture.seed, "rev-parse", "HEAD")
            completed, report = fixture.run("update")
            self.assertEqual(completed.returncode, 0, completed.stdout)
            self.assertEqual(git(checkout, "rev-parse", "HEAD"), updated_head)
            self.assertEqual(
                next(item for item in report["targets"] if item["targetId"] == "example")["action"],
                "PULL",
            )

            local = checkout / "local.txt"
            local.write_text("dirty\n", encoding="utf-8")
            dirty, dirty_report = fixture.run("update")
            self.assertEqual(dirty.returncode, 1)
            self.assertTrue(local.exists())
            self.assertEqual(
                next(item for item in dirty_report["targets"] if item["targetId"] == "example")["status"],
                "DIRTY",
            )

        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            conflict = fixture.home / "Fleet" / "Example"
            conflict.parent.mkdir()
            conflict.write_text("do not remove\n", encoding="utf-8")
            completed, report = fixture.run("update")
            self.assertEqual(completed.returncode, 1)
            self.assertEqual(conflict.read_text(encoding="utf-8"), "do not remove\n")
            self.assertEqual(
                next(item for item in report["targets"] if item["targetId"] == "example")["status"],
                "PATH_CONFLICT",
            )

    def test_unsafe_repository_states_are_classified_without_repair(self) -> None:
        scenarios = ("BRANCH_MISMATCH", "DETACHED", "REMOTE_MISMATCH", "MISSING_UPSTREAM", "AHEAD", "DIVERGED")
        for expected in scenarios:
            with self.subTest(expected=expected), tempfile.TemporaryDirectory() as directory:
                fixture = FleetFixture(Path(directory))
                fixture.run("update")
                checkout = fixture.home / "Fleet" / "Example"
                git(checkout, "config", "user.name", "Fixture")
                git(checkout, "config", "user.email", "fixture@example.invalid")
                if expected == "BRANCH_MISMATCH":
                    git(checkout, "switch", "-c", "feature")
                elif expected == "DETACHED":
                    git(checkout, "checkout", "--detach", "HEAD")
                elif expected == "REMOTE_MISMATCH":
                    git(checkout, "remote", "set-url", "origin", str(fixture.root / "other.git"))
                elif expected == "MISSING_UPSTREAM":
                    git(checkout, "branch", "--unset-upstream")
                elif expected in {"AHEAD", "DIVERGED"}:
                    (checkout / "local.txt").write_text("local\n", encoding="utf-8")
                    git(checkout, "add", "local.txt")
                    git(checkout, "commit", "-q", "-m", "local")
                    if expected == "DIVERGED":
                        (fixture.seed / "remote.txt").write_text("remote\n", encoding="utf-8")
                        git(fixture.seed, "add", "remote.txt")
                        git(fixture.seed, "commit", "-q", "-m", "remote")
                        git(fixture.seed, "push", "-q")
                head_before = git(checkout, "rev-parse", "HEAD")
                completed, report = fixture.run("update")
                self.assertEqual(completed.returncode, 1)
                self.assertEqual(git(checkout, "rev-parse", "HEAD"), head_before)
                target = next(item for item in report["targets"] if item["targetId"] == "example")
                self.assertEqual(target["status"], expected)
                self.assertNotEqual(target["nextAction"], "N/A")

    def test_failed_clone_does_not_hide_independent_collection_or_leave_target(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            missing_remote = str(fixture.root / "missing.git")
            completed, report = fixture.run("update", fixture.manifest(remote=missing_remote))
            self.assertEqual(completed.returncode, 1)
            self.assertEqual(len(report["targets"]), 2)
            self.assertTrue((fixture.home / "Fleet").is_dir())
            self.assertFalse((fixture.home / "Fleet" / "Example").exists())
            self.assertEqual(report["overallStatus"], "PARTIAL")
            self.assertEqual(report["counts"]["failed"], 1)

    def test_stage_update_preserves_targets_and_changes_terminal_status(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            _, report = fixture.run("dry-run")
            report_path = fixture.root / "report-dry-run.json"
            target_hash = json.dumps(report["targets"], sort_keys=True)
            completed = subprocess.run(
                [
                    "python3",
                    str(ENGINE),
                    "stage",
                    "--report",
                    str(report_path),
                    "--stage-id",
                    "toolchain",
                    "--status",
                    "Blocked",
                    "--exit-code",
                    "1",
                    "--summary",
                    "fixture",
                    "--next-action",
                    "retry",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            updated = json.loads(report_path.read_text(encoding="utf-8"))
            self.assertEqual(json.dumps(updated["targets"], sort_keys=True), target_hash)
            self.assertEqual(updated["overallStatus"], "PARTIAL")
            self.assertEqual(updated["exitCode"], 1)

    def test_exact_resume_dirty_path_is_accepted_but_remains_visible(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            checkout = fixture.home / "Fleet" / "Example"
            (checkout / "README.md").write_text("managed repair\n", encoding="utf-8")
            completed, report = fixture.run(
                "update",
                allowed_dirty_paths=("Fleet/Example/README.md",),
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            target = next(item for item in report["targets"] if item["targetId"] == "example")
            self.assertEqual(target["status"], "CURRENT")
            self.assertTrue(target["resumeAccepted"])

    def test_public_surfaces_share_admin_deferral_and_report_contract(self) -> None:
        bash = (REPOSITORY / "scripts" / "maintain-agentic-workspace.sh").read_text(encoding="utf-8")
        powershell = (REPOSITORY / "scripts" / "maintain-agentic-workspace.ps1").read_text(encoding="utf-8")
        for token in (
            "DEFERRED_ADMIN_REQUIRED",
            "agentic_workspace_fleet.py",
            "agentic-workspace-fleet.json",
            "canonical-repositories",
            "maintenance package drift predicted",
        ):
            self.assertIn(token, bash)
            self.assertIn(token, powershell)

    def test_model_routing_result_is_not_parsed_as_toolchain_evidence(self) -> None:
        bash = (REPOSITORY / "scripts" / "maintain-agentic-workspace.sh").read_text(encoding="utf-8")
        model_routing_stage = bash[bash.index('CURRENT_STAGE="model-routing"'):bash.index(
            'CURRENT_STAGE="verification"'
        )]

        self.assertIn('MODEL_ROUTING_RESULT_FILE=', model_routing_stage)
        self.assertIsNone(
            re.search(
                r'^\s*"\$MODEL_ROUTING_RESULT_FILE"\s*$',
                model_routing_stage,
                flags=re.MULTILINE,
            )
        )
        self.assertEqual(bash.count('"$TOOLCHAIN_RESULT_FILE"'), 6)

    def test_canonical_repository_listing_ignores_unmanifested_preset_and_inactive_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            fixture.run("update")
            manifest = json.loads(fixture.manifest().read_text(encoding="utf-8"))
            manifest["targets"].extend(
                [
                    {
                        "id": "preset",
                        "kind": "git-repository",
                        "level": 2,
                        "path": "Fleet/Preset",
                        "active": True,
                        "maintenanceClass": "preset",
                        "remote": str(fixture.root / "preset.git"),
                        "forge": "generic-git",
                        "defaultBranch": "main",
                    },
                    {
                        "id": "inactive",
                        "kind": "git-repository",
                        "level": 2,
                        "path": "Fleet/Inactive",
                        "active": False,
                        "maintenanceClass": "canonical-fleet",
                        "remote": str(fixture.root / "inactive.git"),
                        "forge": "generic-git",
                        "defaultBranch": "main",
                    },
                ]
            )
            manifest_path = fixture.root / "listing-manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            for relative in ("Fleet/Preset", "Fleet/Inactive", "Legacy/Old"):
                repository = fixture.home / relative
                repository.mkdir(parents=True)
                subprocess.run(["git", "init", "-q", str(repository)], check=True)

            completed = subprocess.run(
                [
                    "python3",
                    str(ENGINE),
                    "canonical-repositories",
                    "--manifest",
                    str(manifest_path),
                    "--home-dir",
                    str(fixture.home),
                    "--existing-only",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertEqual(
                completed.stdout.strip(),
                f"2\t{(fixture.home / 'Fleet' / 'Example').resolve()}",
            )
            self.assertNotIn("Legacy", completed.stdout)
            self.assertNotIn("Preset", completed.stdout)
            self.assertNotIn("Inactive", completed.stdout)

    def test_propagation_surfaces_ignore_unregistered_legacy_repository(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / "home"
            canonical = home / "Fleet" / "Canonical"
            legacy = home / "Legacy" / "Old"
            guidance = (REPOSITORY / "AGENTS.md").read_text(encoding="utf-8")
            for repository in (canonical, legacy):
                repository.mkdir(parents=True)
                subprocess.run(["git", "init", "-q", str(repository)], check=True)
                (repository / "AGENTS.md").write_text(guidance, encoding="utf-8")
            registry = root / "registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "repositories": [{"path": "Fleet/Canonical", "level": 2}],
                    }
                ),
                encoding="utf-8",
            )
            manifest = root / "propagation-manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "files": [{"path": "AGENTS.md", "executable": False}],
                    }
                ),
                encoding="utf-8",
            )

            commands = [
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "propagate-agentic-toolchain-maintenance.ps1"),
                    "-HomeDir",
                    str(home),
                    "-Registry",
                    str(registry),
                    "-Manifest",
                    str(manifest),
                    "-CheckOnly",
                ],
            ]
            if os.name != "nt":
                commands.insert(
                    0,
                    [
                        "bash",
                        bash_path(REPOSITORY / "scripts" / "propagate-agentic-toolchain-maintenance.sh"),
                        "--home-dir",
                        bash_path(home),
                        "--registry",
                        bash_path(registry),
                        "--manifest",
                        bash_path(manifest),
                        "--check-only",
                    ],
                )
            for command in commands:
                with self.subTest(surface=command[0]):
                    completed = subprocess.run(
                        command,
                        text=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        check=False,
                    )
                    self.assertEqual(completed.returncode, 0, completed.stdout)
                    if os.name == "nt":
                        expected_canonical = str(Path("Fleet") / "Canonical")
                        unexpected_legacy = str(Path("Legacy") / "Old")
                    else:
                        expected_canonical = (
                            bash_path(canonical) if command[0] == "bash" else str(canonical)
                        )
                        unexpected_legacy = (
                            bash_path(legacy) if command[0] == "bash" else str(legacy)
                        )
                    normalized_output = completed.stdout.casefold()
                    self.assertIn(expected_canonical.casefold(), normalized_output)
                    self.assertNotIn(unexpected_legacy.casefold(), normalized_output)

    def test_propagation_surfaces_accept_only_clean_tracked_exact_exceptions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / "home"
            canonical = home / "Fleet" / "Canonical"
            canonical.mkdir(parents=True)
            subprocess.run(["git", "init", "-q", str(canonical)], check=True)
            git(canonical, "config", "user.name", "Fixture")
            git(canonical, "config", "user.email", "fixture@example.invalid")
            target = canonical / "AGENTS.md"
            target.write_text("project-specific guidance\n", encoding="utf-8")
            git(canonical, "add", "AGENTS.md")
            git(canonical, "commit", "-q", "-m", "project-specific variant")

            registry = root / "registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "repositories": [{"path": "Fleet/Canonical", "level": 2}],
                    }
                ),
                encoding="utf-8",
            )
            manifest = root / "propagation-manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "files": [{"path": "AGENTS.md", "executable": False}],
                        "exceptions": [
                            {
                                "repositoryPath": "Fleet/Canonical",
                                "path": "AGENTS.md",
                                "reason": "fixture-specific guidance",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )

            commands = [
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "propagate-agentic-toolchain-maintenance.ps1"),
                    "-HomeDir",
                    str(home),
                    "-Registry",
                    str(registry),
                    "-Manifest",
                    str(manifest),
                    "-CheckOnly",
                ],
            ]
            if os.name != "nt":
                commands.insert(
                    0,
                    [
                        "bash",
                        bash_path(REPOSITORY / "scripts" / "propagate-agentic-toolchain-maintenance.sh"),
                        "--home-dir",
                        bash_path(home),
                        "--registry",
                        bash_path(registry),
                        "--manifest",
                        bash_path(manifest),
                        "--check-only",
                    ],
                )

            for command in commands:
                with self.subTest(surface=command[0], state="clean-tracked"):
                    completed = subprocess.run(
                        command,
                        text=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        check=False,
                    )
                    self.assertEqual(completed.returncode, 0, completed.stdout)
                    self.assertIn("[EXCEPTED] AGENTS.md", completed.stdout)
                    self.assertIn("files.raw_differences: 1", completed.stdout)
                    self.assertIn("files.exceptions:      1", completed.stdout)
                    self.assertIn("files.actionable_drift: 0", completed.stdout)

            invalid_manifest = root / "invalid-propagation-manifest.json"
            invalid_manifest.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "files": [{"path": "AGENTS.md", "executable": False}],
                        "exceptions": [
                            {
                                "repositoryPath": "Fleet/Canonical",
                                "path": "CLAUDE.md",
                                "reason": "not a managed path",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            for command in commands:
                invalid_command = list(command)
                manifest_option = "--manifest" if command[0] == "bash" else "-Manifest"
                invalid_command[invalid_command.index(manifest_option) + 1] = str(
                    invalid_manifest
                )
                with self.subTest(surface=command[0], state="invalid-exception"):
                    completed = subprocess.run(
                        invalid_command,
                        text=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        check=False,
                    )
                    self.assertNotEqual(completed.returncode, 0, completed.stdout)
                    self.assertIn("exception", completed.stdout.casefold())

            target.write_text("uncommitted local change\n", encoding="utf-8")
            for command in commands:
                with self.subTest(surface=command[0], state="locally-modified"):
                    completed = subprocess.run(
                        command,
                        text=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        check=False,
                    )
                    self.assertEqual(completed.returncode, 2, completed.stdout)
                    self.assertIn("local managed-file change", completed.stdout)
                    self.assertNotIn("[EXCEPTED]", completed.stdout)

    def test_registry_rejects_preset_or_unknown_propagation_targets(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = FleetFixture(Path(directory))
            manifest = fixture.manifest()
            registry = fixture.root / "registry.json"
            registry.write_text(
                json.dumps({"repositories": [{"path": "Fleet/Example"}]}),
                encoding="utf-8",
            )
            command = [
                "python3", str(ENGINE), "registry",
                "--manifest", str(manifest), "--registry", str(registry),
            ]
            valid = subprocess.run(command, text=True, capture_output=True, check=False)
            self.assertEqual(valid.returncode, 0, valid.stdout)
            registry.write_text(
                json.dumps({"repositories": [{"path": "Fleet/Unexpected"}]}),
                encoding="utf-8",
            )
            invalid = subprocess.run(command, text=True, capture_output=True, check=False)
            self.assertEqual(invalid.returncode, 2, invalid.stdout)
            self.assertIn("non-canonical propagation target", invalid.stdout)


if __name__ == "__main__":
    unittest.main()
