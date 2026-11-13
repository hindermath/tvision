#!/usr/bin/env python3
"""Validate maintenance registries and supported preset-profile contracts."""

from __future__ import annotations

import json
import importlib.util
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[2]
CONFIG = REPOSITORY / "scripts" / "config"
FLEET_ENGINE = REPOSITORY / "scripts" / "lib" / "agentic_workspace_fleet.py"


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run_git(repository: Path, *arguments: str) -> None:
    subprocess.run(
        ["git", *arguments],
        cwd=repository,
        check=True,
        stdout=subprocess.DEVNULL,
    )


def preset_helper_source() -> str:
    source = (REPOSITORY / "scripts" / "maintain-agentic-workspace.sh").read_text(
        encoding="utf-8"
    )
    cleanup_start = source.index("cleanup_preset_validation_target() {")
    cleanup_end = source.index("\nwhile [ $# -gt 0 ]; do", cleanup_start)
    start = source.index("resolve_default_remote_ref() {")
    end = source.index("\nhandle_preset_profiles() {", start)
    return source[cleanup_start:cleanup_end] + "\n" + source[start:end]


class MaintenanceContractTests(unittest.TestCase):
    @unittest.skipIf(os.name == "nt", "Native Windows uses PowerShell 7")
    def test_required_bash_probe_rejects_old_shell(self) -> None:
        tool = next(t for t in read_json(CONFIG / "required-cli-tools-registry.json")["tools"] if t["id"] == "bash")
        self.assertEqual(tool["platforms"], ["Darwin", "Linux"])
        current = shutil.which("bash")
        if current is None:
            self.skipTest("Bash unavailable on this platform")
        for shell in dict.fromkeys([current, "/bin/bash"]):
            if not Path(shell).exists():
                continue
            version = subprocess.check_output([shell, "--noprofile", "--norc", "-c", "printf '%s' \"$BASH_VERSION\""], text=True)
            result = subprocess.run([shell, *tool["args"]], capture_output=True, text=True)
            self.assertEqual(result.returncode == 0, int(version.split(".")[0]) >= 5)
            self.assertEqual(result.stdout.strip(), version)

    def test_ci_gate_wrapper_contract_is_cross_platform_and_fail_closed(self) -> None:
        bash_source = (REPOSITORY / "scripts/maintain-agentic-workspace.sh").read_text(encoding="utf-8")
        powershell_source = (REPOSITORY / "scripts/maintain-agentic-workspace.ps1").read_text(encoding="utf-8")
        self.assertIn("--ci-gate", bash_source)
        self.assertIn("--dry-run", bash_source)
        self.assertIn("-CiGate", powershell_source)
        self.assertIn("-WhatIf", powershell_source)
        self.assertIn("function Invoke-HBAgenticWorkspaceMaintenance", powershell_source)
        self.assertIn("$ciExitCode = $LASTEXITCODE", powershell_source)
        self.assertIn("exit $ciExitCode", powershell_source)
        self.assertNotIn("Invoke-Expression", powershell_source)
        self.assertNotIn("eval ", bash_source)

    def test_network_attempt_contract_distinguishes_success_failure_and_timeout(self) -> None:
        specification = importlib.util.spec_from_file_location(
            "fleet_engine_attempts", FLEET_ENGINE
        )
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        cases = ((0, "Succeeded"), (1, "Failed"), (124, "TimedOut"))
        for exit_code, expected in cases:
            with self.subTest(exit_code=exit_code):
                completed = subprocess.CompletedProcess(
                    ["git", "fetch"],
                    exit_code,
                    stdout="",
                    stderr="" if exit_code == 0 else "bounded failure",
                )
                result = module.network_attempt("fetch", completed, 2, 125)
                self.assertEqual(result["status"], expected)
                self.assertEqual(result["attemptCount"], 2)
                self.assertEqual(result["durationMs"], 125)
                self.assertEqual(result["exitCode"], exit_code)
                self.assertEqual(result["nextAction"] == "N/A", exit_code == 0)
        sensitive = subprocess.CompletedProcess(
            ["git", "fetch"],
            1,
            stdout="",
            stderr=(
                f"failure at {Path.home()}/private "
                "https://user:credential@example.invalid/repo.git token=value"
            ),
        )
        sanitized = module.network_attempt("fetch", sensitive, 1, 10)
        self.assertNotIn(str(Path.home()), sanitized["sanitizedEvidence"])
        self.assertNotIn("credential", sanitized["sanitizedEvidence"])
        self.assertNotIn("token=value", sanitized["sanitizedEvidence"])

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell 7 is required.")
    def test_powershell_rename_accepts_repository_root_filename(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            run_git(repository, "init", "-q")
            run_git(repository, "config", "user.name", "Fixture")
            run_git(repository, "config", "user.email", "fixture@example.invalid")
            source = repository / "Lastenheft_Foo.md"
            source.write_text("# Fixture\n", encoding="utf-8")
            run_git(repository, "add", source.name)
            run_git(repository, "commit", "-q", "-m", "fixture")

            completed = subprocess.run(
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "rename-lastenheft.ps1"),
                    "-File",
                    source.name,
                    "-BranchName",
                    "015-fixture",
                ],
                cwd=repository,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

            target = repository / "Lastenheft_Foo.015-fixture.md"
            self.assertEqual(completed.returncode, 0, completed.stdout)
            self.assertFalse(source.exists())
            self.assertTrue(target.is_file())
            subject = subprocess.check_output(
                ["git", "log", "-1", "--format=%s"],
                cwd=repository,
                text=True,
            ).strip()
            self.assertEqual(
                subject,
                "chore: rename Lastenheft to Lastenheft_Foo.015-fixture.md",
            )

    def test_fleet_manifest_has_exact_declared_cardinalities(self) -> None:
        specification = importlib.util.spec_from_file_location("fleet_engine", FLEET_ENGINE)
        self.assertIsNotNone(specification)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        manifest = module.load_manifest(CONFIG / "agentic-workspace-fleet.json")
        targets = manifest["targets"]
        self.assertEqual(len(targets), 49)
        self.assertEqual(sum(item["kind"] == "git-repository" for item in targets), 48)
        self.assertEqual(sum(item["kind"] == "collection" for item in targets), 1)
        self.assertEqual(
            sum(item["maintenanceClass"] == "canonical-fleet" for item in targets),
            36,
        )
        self.assertEqual(
            sum(
                item["kind"] == "git-repository"
                and item["maintenanceClass"] == "preset"
                for item in targets
            ),
            12,
        )
        self.assertEqual(
            1 + sum(item["kind"] == "git-repository" for item in targets),
            49,
            "Level 0 plus manifest Git targets define the freshness barrier.",
        )

    def test_fleet_preset_repositories_match_managed_twelve_preset_profile(self) -> None:
        manifest = read_json(CONFIG / "agentic-workspace-fleet.json")
        profile = read_json(CONFIG / "spec-kit-model-routing-governance-presets.json")

        collection = next(
            item for item in manifest["targets"] if item["id"] == "spec-kit-preset-projects"
        )
        self.assertEqual(collection["kind"], "collection")
        self.assertEqual(collection["path"], "SpecKitPresetProjects")
        self.assertEqual(collection["memberDiscovery"], "declared-targets")

        preset_targets = [
            item
            for item in manifest["targets"]
            if item["kind"] == "git-repository"
            and item["maintenanceClass"] == "preset"
            and item["active"]
        ]
        declared_remotes = {item["remote"].removesuffix(".git") for item in preset_targets}
        managed_remotes = {item["repository"].removesuffix(".git") for item in profile["presets"]}
        declared_paths = {item["path"] for item in preset_targets}
        managed_paths = {
            f'{collection["path"]}/{item["repository"].removesuffix(".git").rsplit("/", 1)[-1]}'
            for item in profile["presets"]
        }

        self.assertEqual(len(profile["presets"]), 12)
        self.assertEqual(declared_remotes, managed_remotes)
        self.assertEqual(declared_paths, managed_paths)

    def test_fleet_manifest_rejects_unsafe_semantics(self) -> None:
        specification = importlib.util.spec_from_file_location("fleet_engine_invalid", FLEET_ENGINE)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        base = {
            "schemaVersion": "1.0",
            "targets": [
                {
                    "id": "root",
                    "kind": "git-repository",
                    "level": 1,
                    "path": "Root",
                    "active": True,
                    "maintenanceClass": "canonical-fleet",
                    "remote": "https://example.invalid/root.git",
                    "forge": "generic-git",
                    "defaultBranch": "main",
                }
            ],
        }
        invalid_variants = []
        traversal = json.loads(json.dumps(base))
        traversal["targets"][0]["path"] = "../Root"
        invalid_variants.append(traversal)
        duplicate = json.loads(json.dumps(base))
        duplicate["targets"].append(dict(duplicate["targets"][0]))
        invalid_variants.append(duplicate)
        invalid_collection = json.loads(json.dumps(base))
        invalid_collection["targets"][0].update(
            {"kind": "collection", "memberDiscovery": "declared-targets"}
        )
        invalid_variants.append(invalid_collection)
        orphan = json.loads(json.dumps(base))
        orphan["targets"][0].update({"level": 2, "path": "Missing/Child"})
        invalid_variants.append(orphan)

        for index, content in enumerate(invalid_variants):
            with self.subTest(index=index), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "manifest.json"
                path.write_text(json.dumps(content), encoding="utf-8")
                with self.assertRaises(module.ContractError):
                    module.load_manifest(path)

    def test_preset_profile_catalog_resolves_exact_matrices(self) -> None:
        catalog = read_json(CONFIG / "spec-kit-preset-profiles.json")
        expected = {
            "standard-eight-governance-presets": 8,
            "intake-review-nine-governance-presets": 9,
            "intake-authoring-ten-governance-presets": 10,
            "intake-sequencing-eleven-governance-presets": 11,
            "model-routing-twelve-governance-presets": 12,
            "secure-development-assurance-thirteen-governance-presets": 13,
        }
        self.assertEqual(catalog["defaultProfile"], "standard-eight-governance-presets")
        self.assertIsNone(catalog["profiles"]["none"]["presetConfig"])
        for profile, count in expected.items():
            relative = catalog["profiles"][profile]["presetConfig"]
            matrix = read_json(REPOSITORY / relative)
            self.assertEqual(len(matrix["presets"]), count, profile)

        example = read_json(CONFIG / "level2-repository-registry.example.json")
        supported = set(catalog["profiles"])
        self.assertIn(example["defaultPresetProfile"], supported)
        for entry in example["repositories"]:
            self.assertIn(entry["presetProfile"], supported)

        current = subprocess.run(
            [
                "python3", str(FLEET_ENGINE), "profile",
                "--catalog", str(CONFIG / "spec-kit-preset-profiles.json"),
                "--source-root", str(REPOSITORY),
                "--profile", "intake-sequencing-eleven-governance-presets",
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(current.returncode, 0, current.stderr)
        self.assertEqual(json.loads(current.stdout)["presetCount"], 11)

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            matrix = root / "matrix.json"
            matrix.write_text(
                json.dumps({"presets": [{"id": f"fixture-{index}"} for index in range(12)]}),
                encoding="utf-8",
            )
            synthetic_catalog = root / "catalog.json"
            synthetic_catalog.write_text(
                json.dumps(
                    {
                        "defaultProfile": "synthetic",
                        "profiles": {"synthetic": {"presetConfig": "matrix.json"}},
                    }
                ),
                encoding="utf-8",
            )
            synthetic = subprocess.run(
                [
                    "python3", str(FLEET_ENGINE), "profile",
                    "--catalog", str(synthetic_catalog),
                    "--source-root", str(root),
                    "--profile", "synthetic",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(synthetic.returncode, 0, synthetic.stderr)
            self.assertEqual(json.loads(synthetic.stdout)["presetCount"], 12)

    def test_registry_reports_language_msl_conflicts_without_mutating_curated_data(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = root / "manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "schemaVersion": "1.0",
                        "targets": [
                            {
                                "id": "fleet", "kind": "collection", "level": 1,
                                "path": "Fleet", "active": True,
                                "maintenanceClass": "canonical-fleet",
                                "memberDiscovery": "declared-targets",
                            },
                            {
                                "id": "csharp", "kind": "git-repository", "level": 2,
                                "path": "Fleet/CSharp", "active": True,
                                "maintenanceClass": "canonical-fleet",
                                "remote": "https://example.invalid/csharp.git",
                                "forge": "generic-git", "defaultBranch": "main",
                            },
                            {
                                "id": "cc65", "kind": "git-repository", "level": 2,
                                "path": "Fleet/cc65", "active": True,
                                "maintenanceClass": "canonical-fleet",
                                "remote": "https://example.invalid/cc65.git",
                                "forge": "generic-git", "defaultBranch": "master",
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )
            registry = root / "registry.json"
            entries = {
                "repositories": [
                    {"path": "Fleet/CSharp", "primaryLanguage": "C#", "mslStatus": "msl"},
                    {"path": "Fleet/cc65", "primaryLanguage": "cc65", "mslStatus": "non-msl"},
                ]
            }
            registry.write_text(json.dumps(entries), encoding="utf-8")
            accepted_before = registry.read_bytes()
            accepted = subprocess.run(
                [
                    "python3", str(FLEET_ENGINE), "registry",
                    "--manifest", str(manifest), "--registry", str(registry),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(accepted.returncode, 0, accepted.stdout)
            self.assertEqual(registry.read_bytes(), accepted_before)

            entries["repositories"][0]["mslStatus"] = "non-msl"
            entries["repositories"][1]["mslStatus"] = "msl"
            registry.write_text(json.dumps(entries), encoding="utf-8")
            conflict_before = registry.read_bytes()
            conflict = subprocess.run(
                [
                    "python3", str(FLEET_ENGINE), "registry",
                    "--manifest", str(manifest), "--registry", str(registry),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(conflict.returncode, 1, conflict.stdout)
            self.assertEqual(conflict.stdout.count("LANGUAGE_MSL_CONFLICT"), 2)
            self.assertEqual(registry.read_bytes(), conflict_before)

    def test_bash_and_powershell_share_barrier_lease_and_status_terms(self) -> None:
        bash = (REPOSITORY / "scripts" / "maintain-agentic-workspace.sh").read_text(
            encoding="utf-8"
        )
        powershell = (
            REPOSITORY / "scripts" / "maintain-agentic-workspace.ps1"
        ).read_text(encoding="utf-8")
        for token in (
            "lease-recover",
            "lease-create",
            "lease-release",
            "fleetReady",
            "Blocked",
            "Passed",
            "Skipped",
            "N/A",
        ):
            self.assertIn(token, bash)
            self.assertIn(token, powershell)

    def test_brew_registry_classifies_local_formulae_and_formula_powershell(self) -> None:
        registry = read_json(CONFIG / "brew-apps-registry.json")
        formulae = {item["name"]: item for item in registry["formulae"]}
        for name in (
            "mongodb/brew/mongodb-community@8.0",
            "mono",
            "sqlite",
            "telnet",
        ):
            self.assertEqual(formulae[name]["scope"], "optional", name)
        self.assertNotIn("mongodb/brew/mongodb-community", formulae)
        self.assertEqual(formulae["powershell"]["scope"], "required")
        self.assertIs(formulae["powershell"]["ensureLinked"], True)
        self.assertEqual(formulae["powershell"]["linkCommands"], ["pwsh"])
        self.assertNotIn("powershell", {item["name"] for item in registry["casks"]})

    def test_vscode_registry_requires_exact_editor_extension_contract(self) -> None:
        registry = read_json(CONFIG / "vscode-extensions-registry.json")
        extensions = registry["extensions"]
        ids = [item["id"] for item in extensions]
        expected = {
            "ms-dotnettools.csdevkit",
            "golang.Go",
            "vscjava.vscode-java-pack",
            "ms-python.python",
            "rust-lang.rust-analyzer",
            "swiftlang.swift-vscode",
            "ms-vscode.powershell",
            "ms-azuretools.vscode-containers",
            "myriad-dreamin.tinymist",
        }

        self.assertEqual(len(ids), 9)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(set(ids), expected)
        self.assertTrue(all(item["scope"] == "required" for item in extensions))

        required_surfaces = (
            "AGENTS.md",
            "CLAUDE.md",
            "GEMINI.md",
            ".github/copilot-instructions.md",
            ".github/agents/copilot-instructions.md",
            "scripts/templates/AGENTS.md.tmpl",
            "scripts/templates/CLAUDE.md.tmpl",
            "scripts/templates/GEMINI.md.tmpl",
            "scripts/templates/copilot-instructions.tmpl",
            "docs/man/maintain-agentic-brew-apps.1.md",
            "docs/man/maintain-agentic-winget-apps.1.md",
        )
        for relative in required_surfaces:
            with self.subTest(surface=relative):
                content = (REPOSITORY / relative).read_text(encoding="utf-8")
                self.assertIn("ms-vscode.powershell", content)
                self.assertIn("myriad-dreamin.tinymist", content)

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell 7 is required.")
    def test_windows_document_tool_drift_distinguishes_required_and_optional(self) -> None:
        # Load the actual Windows comparison functions without invoking WinGet.
        # This portable proof complements native Windows process/install tests.
        source = REPOSITORY / "scripts/maintain-agentic-winget-apps.ps1"
        command = f"""
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$ast=[Management.Automation.Language.Parser]::ParseFile('{source}',[ref]$null,[ref]$null)
$ast.FindAll({{param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -in @('Get-HBCLITools','Compare-HBCLIScope','Compare-HBVSCodeRegistry')}},$false) |
    ForEach-Object {{ . ([scriptblock]::Create($_.Extent.Text)) }}
$cliRegistryData=Get-Content '{CONFIG / 'required-cli-tools-registry.json'}' -Raw | ConvertFrom-Json
function Test-HBCLITool {{ param($Tool) return ($Tool.id -notin $script:missingTools) }}
foreach ($case in @(
    @{{scope='required'; missing=@('pandoc'); failed=$true}},
    @{{scope='required'; missing=@('typst'); failed=$true}},
    @{{scope='optional'; missing=@('tinymist'); failed=$false}},
    @{{scope='required'; missing=@(); failed=$false}}
)) {{
    $script:RequiredDrift=$false; $script:missingTools=$case.missing
    Compare-HBCLIScope -Scope $case.scope -Label 'fixture'
    if ($script:RequiredDrift -ne $case.failed) {{ throw 'CLI drift scope mismatch' }}
}}
$SkipVSCodeExtensions=$false; $VSCodeRegistry='fixture'; $allVSCodeExtensionIds=@('myriad-dreamin.tinymist','fixture.optional')
$vscodeRegistryData=[pscustomobject]@{{extensions=@(
    [pscustomobject]@{{id='myriad-dreamin.tinymist';scope='required'}},
    [pscustomobject]@{{id='fixture.optional';scope='optional'}}
); deprecatedExtensions=@()}}
function Get-HBVSCodeCli {{ return $script:fixtureCli }}
function Get-HBVSCodeInstalledExtensionIds {{ param($Cli) return $script:fixtureInstalled }}
foreach ($case in @(
    @{{cli='fixture'; installed=@(); failed=$true}},
    @{{cli='fixture'; installed=@('myriad-dreamin.tinymist'); failed=$false}},
    @{{cli=$null; installed=@(); failed=$true}}
)) {{
    $script:RequiredDrift=$false; $script:fixtureCli=$case.cli; $script:fixtureInstalled=$case.installed
    Compare-HBVSCodeRegistry
    if ($script:RequiredDrift -ne $case.failed) {{ throw 'Extension drift scope mismatch' }}
}}
$script:RequiredDrift=$false; $SkipVSCodeExtensions=$true
Compare-HBVSCodeRegistry
if ($script:RequiredDrift) {{ throw 'Skipped extension check leaked drift' }}
Write-Output 'PASS'
"""
        completed = subprocess.run(["pwsh", "-NoProfile", "-Command", command],
            capture_output=True, text=True, timeout=30)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)
        self.assertIn("PASS", completed.stdout)

    def test_document_tools_have_matching_package_and_cli_scopes(self) -> None:
        brew = read_json(CONFIG / "brew-apps-registry.json")
        formulae = {item["name"]: item["scope"] for item in brew["formulae"]}
        apt = {item["name"]: item["scope"] for item in brew["aptFallback"]["packages"]}
        windows = {item["id"]: item["scope"] for item in read_json(CONFIG / "winget-apps-registry.json")["packages"]}
        cli = {item["id"]: item for item in read_json(CONFIG / "required-cli-tools-registry.json")["tools"]}
        for name, package, scope in (
            ("pandoc", "JohnMacFarlane.Pandoc", "required"),
            ("typst", "Typst.Typst", "required"),
            ("tinymist", "Myriad-Dreamin.Tinymist", "optional"),
        ):
            with self.subTest(tool=name):
                self.assertEqual(formulae[name], scope)
                self.assertEqual(windows[package], scope)
                self.assertEqual(cli[name]["scope"], scope)
                self.assertEqual(set(cli[name]["platforms"]), {"Darwin", "Linux", "Windows"})
                self.assertEqual(cli[name]["args"], ["--version"])
        self.assertEqual(apt["pandoc"], "required")

    def test_required_cli_registry_and_swift_platform_contract_are_closed(self) -> None:
        registry = read_json(CONFIG / "required-cli-tools-registry.json")
        tools = registry["tools"]
        ids = [item["id"] for item in tools]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(ids)
        allowed_platforms = {"Darwin", "Linux", "Windows"}
        for item in tools:
            self.assertIn(item.get("scope", "required"), {"required", "optional"})
            self.assertTrue(set(item["platforms"]))
            self.assertLessEqual(set(item["platforms"]), allowed_platforms)
            self.assertTrue(item["command"])
            self.assertIsInstance(item["args"], list)

        approved_spec_kit_revision = "464d57fe30c72e9a88d279cc49834539ec989c03"
        approved_spec_kit_source = (
            "git+https://github.com/github/spec-kit.git@" + approved_spec_kit_revision
        )
        specify = next(item for item in tools if item["id"] == "specify")
        self.assertEqual(
            specify["install"]["arguments"],
            ["tool", "install", "specify-cli", "--from", approved_spec_kit_source],
        )
        self.assertEqual(
            registry["policy"]["specKitInstallCommand"],
            "uv tool install specify-cli --from " + approved_spec_kit_source,
        )
        bash_maintainer = (REPOSITORY / "scripts/maintain-agentic-brew-apps.sh").read_text(encoding="utf-8")
        windows_maintainer = (REPOSITORY / "scripts/maintain-agentic-winget-apps.ps1").read_text(encoding="utf-8")
        for source in (bash_maintainer, windows_maintainer):
            self.assertIn(approved_spec_kit_revision, source)

        swift = next(item for item in tools if item["id"] == "swift")
        install = swift["install"]
        self.assertEqual(install["manager"], "swiftly")
        linux = install["linux"]
        self.assertEqual(linux["swiftlyVersion"], "1.1.2")
        self.assertEqual(linux["swiftVersion"], "latest-stable")
        self.assertEqual({item["id"] for item in registry["mslToolchains"]},
                         {"dotnet", "go", "java", "python", "rust", "swift"})
        self.assertEqual(
            linux["profiles"],
            {
                "ubuntu:22.04": "ubuntu2204",
                "ubuntu:24.04": "ubuntu2404",
            },
        )
        self.assertEqual(set(linux["artifacts"]), {"x86_64", "aarch64"})
        for architecture, artifact in linux["artifacts"].items():
            self.assertEqual(
                artifact["url"],
                "https://download.swift.org/swiftly/linux/"
                f"swiftly-1.1.2-{architecture}.tar.gz",
            )
            self.assertRegex(artifact["sha256"], r"^[0-9a-f]{64}$")

    @unittest.skipIf(os.name == "nt", "The Bash registration test runs on macOS and Linux.")
    def test_registration_rejects_unknown_preset_profile(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            repository = home / "ExampleProjects" / "ExampleService"
            repository.mkdir(parents=True)
            subprocess.run(["git", "init", "-q"], cwd=repository, check=True)
            registry = home / ".home-baseline" / "registry.json"
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            completed = subprocess.run(
                [
                    "bash",
                    str(REPOSITORY / "scripts" / "register-level2-repository.sh"),
                    "--repo",
                    str(repository),
                    "--level",
                    "2",
                    "--registry",
                    str(registry),
                    "--preset-profile",
                    "unsupported-profile",
                    "--dry-run",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertNotEqual(completed.returncode, 0, completed.stdout)
            self.assertIn("unknown preset profile", completed.stdout)

    @unittest.skipIf(os.name == "nt", "The Bash registration test runs on macOS and Linux.")
    def test_registration_preserves_explicit_cc65_non_msl_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            repository = home / "C64Projects" / "cc65"
            repository.mkdir(parents=True)
            subprocess.run(["git", "init", "-q"], cwd=repository, check=True)
            registry = home / ".home-baseline" / "registry.json"
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            subprocess.run(
                [
                    "bash",
                    str(REPOSITORY / "scripts" / "register-level2-repository.sh"),
                    "--repo",
                    str(repository),
                    "--level",
                    "2",
                    "--registry",
                    str(registry),
                    "--primary-language",
                    "cc65",
                    "--msl-status",
                    "non-msl",
                    "--gsdb-required",
                    "true",
                    "--preset-profile",
                    "intake-authoring-ten-governance-presets",
                ],
                env=environment,
                text=True,
                check=True,
            )
            entry = read_json(registry)["repositories"][0]
            self.assertEqual(entry["primaryLanguage"], "cc65")
            self.assertEqual(entry["mslStatus"], "non-msl")
            self.assertIs(entry["gsdbRequired"], True)
            self.assertEqual(
                entry["presetProfile"],
                "intake-authoring-ten-governance-presets",
            )

    @unittest.skipIf(os.name == "nt", "The isolated worktree test uses Bash.")
    def test_preset_check_uses_initialized_origin_default_without_touching_feature_branch(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            remote = root / "remote.git"
            repository = root / "cc65"
            home = root / "home"
            home.mkdir()
            subprocess.run(["git", "init", "--bare", "-q", str(remote)], check=True)
            subprocess.run(
                ["git", "clone", "-q", str(remote), str(repository)],
                check=True,
            )
            run_git(repository, "config", "user.name", "Fixture")
            run_git(repository, "config", "user.email", "fixture@example.invalid")
            run_git(repository, "switch", "-c", "master")
            (repository / "README.md").write_text("baseline\n", encoding="utf-8")
            run_git(repository, "add", "README.md")
            run_git(repository, "commit", "-q", "-m", "baseline")
            baseline = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=repository, text=True
            ).strip()
            run_git(repository, "push", "-q", "-u", "origin", "master")
            run_git(repository, "switch", "-c", "feature-old", baseline)
            run_git(repository, "switch", "master")
            registry = repository / ".specify" / "presets" / ".registry"
            registry.parent.mkdir(parents=True)
            registry.write_text('{"presets": {}}\n', encoding="utf-8")
            run_git(repository, "add", ".specify")
            run_git(repository, "commit", "-q", "-m", "initialize spec kit")
            run_git(repository, "push", "-q", "origin", "master")
            run_git(repository, "remote", "set-head", "origin", "master")
            run_git(repository, "switch", "feature-old")
            (repository / "local.dbg").write_text("local\n", encoding="utf-8")

            status_before = subprocess.check_output(
                ["git", "status", "--porcelain=v1", "-uall"],
                cwd=repository,
                text=True,
            )
            worktrees_before = subprocess.check_output(
                ["git", "worktree", "list", "--porcelain"],
                cwd=repository,
                text=True,
            )
            preset_helpers = preset_helper_source().replace(
                '--owner-pid "$$" \\\n',
                '--owner-pid "$$" \\\n'
                '      --owner-process-identity fixture-owner-process \\\n',
                1,
            )
            harness = f"""set -euo pipefail
SOURCE_ROOT=/not-the-fixture
HOME_DIR={shlex.quote(str(home))}
FLEET_ENGINE={shlex.quote(str(FLEET_ENGINE))}
STATE_DIR={shlex.quote(str(home / '.home-baseline'))}
PRESET_WORKTREE_LEASE_DIR={shlex.quote(str(home / '.home-baseline/preset-validation-leases'))}
PRESET_WORKTREE_STATE_DIR={shlex.quote(str(home / '.home-baseline/preset-validation-worktrees'))}
RUN_ID=fixture-run
PRESET_WORKTREE_REPO=''
PRESET_WORKTREE_PATH=''
PRESET_WORKTREE_ROOT=''
PRESET_WORKTREE_LEASE=''
PRESET_VALIDATION_TARGET=''
PRESET_VALIDATION_ISOLATED=0
warn() {{ :; }}
info() {{ :; }}
{preset_helpers}
prepare_preset_validation_target {shlex.quote(str(repository))}
[ "$PRESET_VALIDATION_ISOLATED" -eq 1 ]
[ -f "$PRESET_VALIDATION_TARGET/.specify/presets/.registry" ]
cleanup_preset_validation_target
"""
            subprocess.run(["bash", "-c", harness], check=True)

            self.assertEqual(
                subprocess.check_output(
                    ["git", "status", "--porcelain=v1", "-uall"],
                    cwd=repository,
                    text=True,
                ),
                status_before,
            )
            self.assertEqual(
                subprocess.check_output(
                    ["git", "worktree", "list", "--porcelain"],
                    cwd=repository,
                    text=True,
                ),
                worktrees_before,
            )

    @unittest.skipIf(os.name == "nt", "The isolated worktree test uses Bash.")
    def test_preset_check_rejects_uninitialized_origin_default(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repository = root / "repository"
            home = root / "home"
            home.mkdir()
            repository.mkdir()
            run_git(repository, "init", "-q", "-b", "master")
            run_git(repository, "config", "user.name", "Fixture")
            run_git(repository, "config", "user.email", "fixture@example.invalid")
            (repository / "README.md").write_text("baseline\n", encoding="utf-8")
            run_git(repository, "add", "README.md")
            run_git(repository, "commit", "-q", "-m", "baseline")
            run_git(repository, "remote", "add", "origin", str(root / "unused.git"))
            run_git(
                repository,
                "update-ref",
                "refs/remotes/origin/master",
                "HEAD",
            )
            run_git(
                repository,
                "symbolic-ref",
                "refs/remotes/origin/HEAD",
                "refs/remotes/origin/master",
            )

            harness = f"""set -euo pipefail
SOURCE_ROOT=/not-the-fixture
HOME_DIR={shlex.quote(str(home))}
FLEET_ENGINE={shlex.quote(str(FLEET_ENGINE))}
STATE_DIR={shlex.quote(str(home / '.home-baseline'))}
PRESET_WORKTREE_LEASE_DIR={shlex.quote(str(home / '.home-baseline/preset-validation-leases'))}
PRESET_WORKTREE_STATE_DIR={shlex.quote(str(home / '.home-baseline/preset-validation-worktrees'))}
RUN_ID=fixture-run
PRESET_WORKTREE_REPO=''
PRESET_WORKTREE_PATH=''
PRESET_WORKTREE_ROOT=''
PRESET_WORKTREE_LEASE=''
PRESET_VALIDATION_TARGET=''
PRESET_VALIDATION_ISOLATED=0
warn() {{ :; }}
info() {{ :; }}
{preset_helper_source()}
prepare_preset_validation_target {shlex.quote(str(repository))}
"""
            completed = subprocess.run(["bash", "-c", harness], check=False)
            self.assertNotEqual(completed.returncode, 0)

    @unittest.skipIf(os.name == "nt", "The isolated worktree test uses Bash.")
    def test_preset_check_rejects_ambiguous_default_refs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repository = root / "repository"
            home = root / "home"
            home.mkdir()
            repository.mkdir()
            run_git(repository, "init", "-q", "-b", "feature")
            run_git(repository, "config", "user.name", "Fixture")
            run_git(repository, "config", "user.email", "fixture@example.invalid")
            (repository / "README.md").write_text("baseline\n", encoding="utf-8")
            run_git(repository, "add", "README.md")
            run_git(repository, "commit", "-q", "-m", "baseline")
            for name in ("main", "master"):
                run_git(
                    repository,
                    "update-ref",
                    f"refs/remotes/origin/{name}",
                    "HEAD",
                )

            harness = f"""set -euo pipefail
SOURCE_ROOT=/not-the-fixture
HOME_DIR={shlex.quote(str(home))}
FLEET_ENGINE={shlex.quote(str(FLEET_ENGINE))}
STATE_DIR={shlex.quote(str(home / '.home-baseline'))}
PRESET_WORKTREE_LEASE_DIR={shlex.quote(str(home / '.home-baseline/preset-validation-leases'))}
PRESET_WORKTREE_STATE_DIR={shlex.quote(str(home / '.home-baseline/preset-validation-worktrees'))}
RUN_ID=fixture-run
PRESET_WORKTREE_REPO=''
PRESET_WORKTREE_PATH=''
PRESET_WORKTREE_ROOT=''
PRESET_WORKTREE_LEASE=''
PRESET_VALIDATION_TARGET=''
PRESET_VALIDATION_ISOLATED=0
warn() {{ :; }}
info() {{ :; }}
{preset_helper_source()}
prepare_preset_validation_target {shlex.quote(str(repository))}
"""
            completed = subprocess.run(["bash", "-c", harness], check=False)
            self.assertNotEqual(completed.returncode, 0)

    @unittest.skipIf(os.name == "nt", "The Bash bootstrap contract test runs on macOS and Linux.")
    def test_bash_bootstrap_resolves_registry_profile_and_constitution_version(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / "constitution.md").write_text(
                "# Constitution v1.20.0\n",
                encoding="utf-8",
            )
            registry_directory = home / ".home-baseline"
            registry_directory.mkdir()
            workspace = home / "workspace"
            workspace.mkdir()
            (registry_directory / "level2-repository-registry.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultPresetProfile": (
                            "intake-sequencing-eleven-governance-presets"
                        ),
                        "repositories": [],
                    }
                ),
                encoding="utf-8",
            )
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            completed = subprocess.run(
                [
                    "bash",
                    str(REPOSITORY / "scripts" / "bootstrap-project.sh"),
                    "Fixture",
                    str(workspace),
                    "--no-remote",
                    "--preview",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            self.assertIn("Constitution v1.20.0", completed.stdout)
            self.assertIn(
                "intake-sequencing-eleven-governance-presets",
                completed.stdout,
            )
            self.assertTrue(workspace.is_dir())
            self.assertFalse((workspace / "Fixture").exists())

    @unittest.skipIf(os.name == "nt", "The Bash bootstrap contract test runs on macOS and Linux.")
    def test_bash_bootstrap_rejects_missing_or_ambiguous_constitution_version(self) -> None:
        for content in (
            "# Constitution\n",
            "# Constitution v1.20.0\n# Constitution v1.21.0\n",
        ):
            with self.subTest(content=content), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                (home / "constitution.md").write_text(content, encoding="utf-8")
                workspace = home / "workspace"
                workspace.mkdir()
                environment = os.environ.copy()
                environment["HOME"] = str(home)
                completed = subprocess.run(
                    [
                        "bash",
                        str(REPOSITORY / "scripts" / "bootstrap-project.sh"),
                        "Fixture",
                        str(workspace),
                        "--no-remote",
                        "--preview",
                    ],
                    env=environment,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
                self.assertNotEqual(completed.returncode, 0, completed.stdout)
                self.assertIn("genau einmal", completed.stdout)
                self.assertTrue(workspace.is_dir())
                self.assertFalse((workspace / "Fixture").exists())

    @unittest.skipIf(os.name == "nt", "The Bash registration test runs on macOS and Linux.")
    def test_bash_registration_dry_run_creates_no_registry_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            repository = home / "Projects" / "Fixture"
            repository.mkdir(parents=True)
            run_git(repository, "init", "-q")
            registry = home / "state" / "nested" / "registry.json"
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            completed = subprocess.run(
                [
                    "bash",
                    str(REPOSITORY / "scripts" / "register-level2-repository.sh"),
                    "--repo",
                    str(repository),
                    "--level",
                    "2",
                    "--registry",
                    str(registry),
                    "--dry-run",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            self.assertFalse(registry.parent.exists())

    @unittest.skipIf(os.name == "nt", "The Bash registration test runs on macOS and Linux.")
    def test_bash_entry_profile_does_not_change_registry_default(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            repository = home / "Projects" / "Fixture"
            repository.mkdir(parents=True)
            run_git(repository, "init", "-q")
            registry = home / "state" / "registry.json"
            registry.parent.mkdir()
            registry.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultPresetProfile": "standard-eight-governance-presets",
                        "updatedAt": "2026-07-31",
                        "repositories": [],
                    }
                ),
                encoding="utf-8",
            )
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            completed = subprocess.run(
                [
                    "bash",
                    str(REPOSITORY / "scripts" / "register-level2-repository.sh"),
                    "--repo",
                    str(repository),
                    "--level",
                    "2",
                    "--registry",
                    str(registry),
                    "--preset-profile",
                    "intake-sequencing-eleven-governance-presets",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            data = read_json(registry)
            self.assertEqual(
                data["defaultPresetProfile"],
                "standard-eight-governance-presets",
            )
            self.assertEqual(
                data["repositories"][0]["presetProfile"],
                "intake-sequencing-eleven-governance-presets",
            )

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell 7 is required.")
    def test_powershell_bootstrap_and_registration_preserve_profile_contracts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / "constitution.md").write_text(
                "# Constitution v1.20.0\n",
                encoding="utf-8",
            )
            registry_directory = home / ".home-baseline"
            registry_directory.mkdir()
            workspace = home / "workspace"
            workspace.mkdir()
            registry = registry_directory / "level2-repository-registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultPresetProfile": "standard-eight-governance-presets",
                        "updatedAt": "2026-07-31",
                        "repositories": [],
                    }
                ),
                encoding="utf-8",
            )
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            preview = subprocess.run(
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "bootstrap-project.ps1"),
                    "-ProjectName",
                    "Fixture",
                    "-TargetWorkspace",
                    str(workspace),
                    "-NoRemote",
                    "-PresetProfile",
                    "intake-sequencing-eleven-governance-presets",
                    "-Preview",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(preview.returncode, 0, preview.stdout)
            self.assertIn("Constitution v1.20.0", preview.stdout)
            self.assertIn(
                "intake-sequencing-eleven-governance-presets",
                preview.stdout,
            )
            self.assertTrue(workspace.is_dir())
            self.assertFalse((workspace / "Fixture").exists())

            dry_run_registry = home / "dry-run" / "nested" / "registry.json"
            dry_run_repository = home / "DryRunProjects" / "Fixture"
            dry_run_repository.mkdir(parents=True)
            run_git(dry_run_repository, "init", "-q")
            dry_run = subprocess.run(
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "register-level2-repository.ps1"),
                    "-Repo",
                    str(dry_run_repository),
                    "-Level",
                    "2",
                    "-Registry",
                    str(dry_run_registry),
                    "-WhatIf",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(dry_run.returncode, 0, dry_run.stdout)
            self.assertFalse(dry_run_registry.parent.exists())

            repository = home / "Projects" / "Fixture"
            repository.mkdir(parents=True)
            run_git(repository, "init", "-q")
            registration = subprocess.run(
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(REPOSITORY / "scripts" / "register-level2-repository.ps1"),
                    "-Repo",
                    str(repository),
                    "-Level",
                    "2",
                    "-Registry",
                    str(registry),
                    "-PresetProfile",
                    "intake-sequencing-eleven-governance-presets",
                ],
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(registration.returncode, 0, registration.stdout)
            data = read_json(registry)
            self.assertEqual(
                data["defaultPresetProfile"],
                "standard-eight-governance-presets",
            )
            self.assertEqual(
                data["repositories"][0]["presetProfile"],
                "intake-sequencing-eleven-governance-presets",
            )


if __name__ == "__main__":
    unittest.main()
