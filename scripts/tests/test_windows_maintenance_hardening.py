#!/usr/bin/env python3
"""Exercise Windows maintenance safety contracts without machine mutation."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


REPOSITORY = Path(__file__).resolve().parents[2]
MODULE = REPOSITORY / "scripts" / "lib" / "windows-maintenance-hardening.psm1"


def run_pwsh(script: str, *, cwd: Path = REPOSITORY) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["pwsh", "-NoProfile", "-NonInteractive", "-Command", script],
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def run_json(script: str) -> object:
    completed = run_pwsh(
        f"Import-Module '{MODULE}' -Force; {script} | ConvertTo-Json -Depth 10 -Compress"
    )
    if completed.returncode != 0:
        raise AssertionError(completed.stdout)
    return json.loads(completed.stdout)


@unittest.skipUnless(os.name == "nt", "Windows-specific process contracts")
class WindowsMaintenanceHardeningTests(unittest.TestCase):
    def test_mode_projection_is_mutually_exclusive(self) -> None:
        result = run_json(
            "@("
            "(Get-HBMaintenanceMode),"
            "(Get-HBMaintenanceMode -CheckOnly),"
            "(Get-HBMaintenanceMode -Preview)"
            ")"
        )
        self.assertEqual(
            [item["Name"] for item in result],
            ["Update", "CheckOnly", "Preview"],
        )
        self.assertEqual(
            [item["HomeSyncSwitch"] for item in result],
            ["N/A", "CheckOnly", "WhatIf"],
        )
        invalid = run_pwsh(
            f"Import-Module '{MODULE}' -Force; "
            "Get-HBMaintenanceMode -CheckOnly -Preview"
        )
        self.assertNotEqual(invalid.returncode, 0)

    def test_python_launcher_uses_bounded_executable_probe(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            invalid = root / "invalid.ps1"
            valid = root / "valid.ps1"
            py_valid = root / "py-valid.ps1"
            invalid.write_text("exit 9009\n", encoding="utf-8")
            valid.write_text(
                "if ($args[-1] -match 'version_info') { '3'; exit 0 }; exit 2\n",
                encoding="utf-8",
            )
            py_valid.write_text(
                "if ($args[0] -eq '-3' -and $args[-1] -match 'version_info') "
                "{ '3'; exit 0 }; exit 2\n",
                encoding="utf-8",
            )
            result = run_json(
                "$candidates=@("
                f"[pscustomobject]@{{Label='python3';FilePath='pwsh';Arguments=@('-NoProfile','-File','{invalid}')}},"
                f"[pscustomobject]@{{Label='python';FilePath='pwsh';Arguments=@('-NoProfile','-File','{valid}')}}"
                "); Resolve-HBPythonLauncher -Candidates $candidates -TimeoutMilliseconds 2000"
            )
            self.assertEqual(result["Label"], "python")
            self.assertEqual(result["MajorVersion"], 3)
            self.assertNotIn(str(root), result["Display"])
            py_result = run_json(
                "$candidates=@("
                f"[pscustomobject]@{{Label='python3';FilePath='pwsh';Arguments=@('-NoProfile','-File','{invalid}')}},"
                f"[pscustomobject]@{{Label='python';FilePath='pwsh';Arguments=@('-NoProfile','-File','{invalid}')}},"
                f"[pscustomobject]@{{Label='py -3';FilePath='pwsh';Arguments=@('-NoProfile','-File','{py_valid}','-3')}}"
                "); Resolve-HBPythonLauncher -Candidates $candidates -TimeoutMilliseconds 2000"
            )
            self.assertEqual(py_result["Label"], "py -3")
            self.assertEqual(py_result["PrefixArguments"][-1], "-3")
            self.assertNotIn(str(root), py_result["Display"])

    def test_retry_is_bounded_and_non_transient_errors_are_not_retried(self) -> None:
        transient = run_json(
            "$script:n=0; "
            "Invoke-HBWithRetry -MaximumAttempts 3 -BaseDelayMilliseconds 1 "
            "-Operation { $script:n++; "
            "if($script:n -lt 3){[pscustomobject]@{Succeeded=$false;Summary='operation timed out'}}"
            "else{[pscustomobject]@{Succeeded=$true;Summary='ok'}} }"
        )
        self.assertTrue(transient["Succeeded"])
        self.assertEqual(transient["Attempts"], 3)
        terminal = run_json(
            "$script:n=0; "
            "Invoke-HBWithRetry -MaximumAttempts 3 -BaseDelayMilliseconds 1 "
            "-Operation { $script:n++; "
            "[pscustomobject]@{Succeeded=$false;Summary='authentication failed'} }"
        )
        self.assertFalse(terminal["Succeeded"])
        self.assertEqual(terminal["Attempts"], 1)

    def test_bounded_process_times_out_and_cleans_the_tree(self) -> None:
        started = time.monotonic()
        result = run_json(
            "Invoke-HBBoundedProcess -FilePath 'pwsh' "
            "-Arguments @('-NoProfile','-Command','Start-Sleep -Seconds 30') "
            "-TimeoutMilliseconds 250 -CleanupMilliseconds 3000"
        )
        self.assertEqual(result["Status"], "TimedOut")
        self.assertTrue(result["ProcessTreeCleaned"])
        self.assertLess(time.monotonic() - started, 8)

    def test_resume_evidence_requires_exact_hashes_and_known_dirty_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            file = root / "managed.txt"
            file.write_text("before\n", encoding="utf-8")
            evidence = root / "resume.json"
            script = (
                f"$root='{root}'; $file='{file}'; $evidence='{evidence}'; "
                "$before=Get-HBFileSha256 -Path $file; "
                "Set-Content -LiteralPath $file -Value 'after'; "
                "$after=Get-HBFileSha256 -Path $file; "
                "$states=@([pscustomobject]@{Path='managed.txt';BeforeSha256=$before;AfterSha256=$after}); "
                "$null=Write-HBResumeEvidence -Path $evidence -RunId ([guid]::NewGuid().ToString()) "
                "-Phase 'propagation' -Files $states -Status Applied -NextAction 'resume'; "
                "$valid=Test-HBResumeEvidence -Path $evidence -Root $root "
                "-DirtyPaths @('managed.txt'); "
                "Set-Content -LiteralPath $file -Value 'changed'; "
                "$changed=Test-HBResumeEvidence -Path $evidence -Root $root "
                "-DirtyPaths @('managed.txt'); "
                "[pscustomobject]@{Valid=$valid.Valid;Changed=$changed.Valid}"
            )
            result = run_json(script)
            self.assertTrue(result["Valid"])
            self.assertFalse(result["Changed"])

    def test_git_normalized_hash_separates_93_raw_from_3_actionable_differences(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / ".gitattributes").write_text("* text eol=lf\n", encoding="utf-8")
            sources = root / "sources"
            targets = root / "targets"
            sources.mkdir()
            targets.mkdir()
            for index in range(93):
                source_text = f"managed {index}\n"
                target_text = (
                    f"changed {index}\r\n"
                    if index >= 90
                    else source_text.replace("\n", "\r\n")
                )
                (sources / f"{index:02}.txt").write_text(
                    source_text, encoding="utf-8", newline=""
                )
                (targets / f"{index:02}.txt").write_text(
                    target_text, encoding="utf-8", newline=""
                )
            pairs = ",".join(
                (
                    "[pscustomobject]@{"
                    f"Source='{sources / f'{index:02}.txt'}';"
                    f"Target='{targets / f'{index:02}.txt'}';"
                    f"Path='managed/{index:02}.txt'"
                    "}"
                )
                for index in range(93)
            )
            result = run_json(
                f"$pairs=@({pairs}); $raw=0; $actionable=0; "
                "foreach($pair in $pairs){"
                "if((Get-FileHash $pair.Source).Hash -ne "
                "(Get-FileHash $pair.Target).Hash){$raw++};"
                "$a=Get-HBGitNormalizedHash -Repository "
                f"'{root}' -Path $pair.Source -RepositoryRelativePath $pair.Path;"
                "$b=Get-HBGitNormalizedHash -Repository "
                f"'{root}' -Path $pair.Target -RepositoryRelativePath $pair.Path;"
                "if($a -ne $b){$actionable++}"
                "}; [pscustomobject]@{RawDifferences=$raw;ActionableDrift=$actionable}"
            )
            self.assertEqual(result["RawDifferences"], 93)
            self.assertEqual(result["ActionableDrift"], 3)

    def test_package_results_are_unique_and_conflicts_win(self) -> None:
        result = run_json(
            "$items=@("
            "[pscustomobject]@{Id='Git.Git';Status='OK';Evidence='list'},"
            "[pscustomobject]@{Id='git.git';Status='MISSING';Evidence='summary'},"
            "[pscustomobject]@{Id='Python.Python.3.13';Status='OK';Evidence='list'}"
            "); @(Get-HBPackageResults -Observations $items)"
        )
        self.assertEqual(len(result), 2)
        git_result = next(item for item in result if item["CanonicalId"] == "git.git")
        self.assertEqual(git_result["FinalStatus"], "CONFLICT")

    def test_canonical_exitcodes_cover_terminal_classes(self) -> None:
        result = run_json(
            "@('SUCCESS','SUCCESS_WITH_WARNINGS','DRIFT','PARTIAL','BLOCKED',"
            "'FAILED','DEFERRED_ADMIN_REQUIRED') | ForEach-Object { "
            "[pscustomobject]@{Status=$_;Code=(Get-HBCanonicalExitCode -Status $_)} }"
        )
        by_status = {item["Status"]: item["Code"] for item in result}
        self.assertEqual(by_status["SUCCESS"], 0)
        self.assertEqual(by_status["SUCCESS_WITH_WARNINGS"], 0)
        self.assertEqual(by_status["DRIFT"], 1)
        self.assertEqual(by_status["PARTIAL"], 1)
        self.assertEqual(by_status["BLOCKED"], 1)
        self.assertEqual(by_status["DEFERRED_ADMIN_REQUIRED"], 1)
        self.assertEqual(by_status["FAILED"], 2)

    def test_public_scripts_integrate_hardening_contracts(self) -> None:
        workspace = (
            REPOSITORY / "scripts" / "maintain-agentic-workspace.ps1"
        ).read_text(encoding="utf-8")
        winget = (
            REPOSITORY / "scripts" / "maintain-agentic-winget-apps.ps1"
        ).read_text(encoding="utf-8")
        propagation = (
            REPOSITORY / "scripts" / "propagate-agentic-toolchain-maintenance.ps1"
        ).read_text(encoding="utf-8")
        for token in (
            "windows-maintenance-hardening.psm1",
            "Get-HBMaintenanceMode",
            "Resolve-HBPythonLauncher",
            "Test-HBResumeEvidence",
            "Get-HBCanonicalExitCode",
            "homeInvocationStatus",
            "& $syncScript -NoPull -CheckOnly -WhatIf:$false",
            "Start-Transcript -Path $logFile -Append -WhatIf:$false",
            "Stop-Transcript -WhatIf:$false",
            "Set-Content -LiteralPath (Join-Path $lockDir 'pid') -Value $PID -WhatIf:$false",
            "'lease-recover'",
            "'lease-create'",
            "'lease-release'",
            "$fleetReport.mutationBarrier.fleetReady",
            "'--level0-dir', $sourceRoot",
        ):
            self.assertIn(token, workspace)
        self.assertNotIn(
            "if ($LASTEXITCODE -notin @(0, $null)) { throw 'sync-home",
            workspace,
        )
        for token in (
            "Invoke-HBBoundedProcess",
            "DEFERRED_ADMIN_REQUIRED",
            "Get-HBPackageResults",
        ):
            self.assertIn(token, winget)
        for token in (
            "Get-HBGitNormalizedHash",
            "Get-HBPropagationExceptionReason",
            "raw_differences",
            "files.exceptions",
            "actionable_drift",
        ):
            self.assertIn(token, propagation)

    def test_preset_profile_count_is_data_driven_from_the_catalog(self) -> None:
        catalog = json.loads(
            (
                REPOSITORY / "scripts" / "config" / "spec-kit-preset-profiles.json"
            ).read_text(encoding="utf-8")
        )
        profile = "intake-sequencing-eleven-governance-presets"
        matrix = json.loads(
            (REPOSITORY / catalog["profiles"][profile]["presetConfig"]).read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(len(matrix["presets"]), 11)
        workspace = (
            REPOSITORY / "scripts" / "maintain-agentic-workspace.ps1"
        ).read_text(encoding="utf-8")
        self.assertNotIn("$fleetPresetCount -ne 11", workspace)
        self.assertIn("$profileCatalogData.defaultProfile", workspace)
        self.assertIn("'profile'", workspace)


if __name__ == "__main__":
    unittest.main()
