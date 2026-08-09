#!/usr/bin/env bash
# linux-test.sh — Sammelt System-Info und Testergebnisse auf Linux
# Ausgabe wird nach ~/home-baseline-source/linux-test-output.txt geschrieben
# und automatisch committet + gepusht.
#
# Verwendung: bash ~/home-baseline-source/scripts/linux-test.sh
set -euo pipefail

OUT="$HOME/home-baseline-source/linux-test-output.txt"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

{
  echo "Linux Test Output - ${DATE}"
  echo ""

  echo "=== System-Info ==="
  echo "OS:       $(uname -s) $(uname -r)"
  echo "Distro:   $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME}" || echo 'unbekannt')"
  echo "Arch:     $(uname -m)"
  echo "Shell:    ${SHELL}"
  echo "bash:     $(bash --version | head -1)"
  echo ""

  echo "=== Paketmanager ==="
  for pm in apt dnf yum pacman zypper brew; do
    command -v "$pm" > /dev/null 2>&1 && echo "  OK  $pm: $(${pm} --version 2>/dev/null | head -1)" || echo "  --- $pm: nicht installiert"
  done
  echo ""
  echo "=== Homebrew Top-Level Formulae ==="
  if command -v brew > /dev/null 2>&1; then
    brew leaves --installed-on-request 2>&1
  else
    echo "brew: nicht installiert"
  fi
  echo ""
  echo "=== apt Status ==="
  if command -v apt > /dev/null 2>&1; then
    apt list --upgradable 2>/dev/null | sed -n '1,80p'
  else
    echo "apt: nicht installiert"
  fi
  echo ""
  echo "=== Agentic Brew Registry Vergleich ==="
  if command -v brew > /dev/null 2>&1; then
    bash "$HOME/home-baseline-source/scripts/maintain-agentic-brew-apps.sh" --compare-only 2>&1
  else
    bash "$HOME/home-baseline-source/scripts/maintain-agentic-brew-apps.sh" --compare-only 2>&1 || true
  fi
  echo ""

  echo "=== PSScriptAnalyzer ==="
  if command -v pwsh > /dev/null 2>&1; then
    pwsh -NoProfile -File "$HOME/home-baseline-source/scripts/maintain-powershell-modules.ps1" -CompareOnly 2>&1
    pwsh -NoProfile -File "$HOME/home-baseline-source/scripts/invoke-psscriptanalyzer.ps1" 2>&1
  else
    echo "pwsh: nicht installiert"
  fi
  echo ""

  echo "=== Workspace Maintenance Check ==="
  bash "$HOME/home-baseline-source/scripts/maintain-agentic-workspace.sh" --check-only --scripts-only 2>&1 || true
  echo ""

  echo "=== VS Code / Helix ==="
  if command -v code > /dev/null 2>&1; then
    code --version 2>&1 || true
    code --list-extensions 2>&1 || true
  else
    echo "code: nicht installiert"
  fi
  if command -v hx > /dev/null 2>&1; then
    hx --version 2>&1 || true
  else
    echo "hx: nicht installiert"
  fi
  echo ""

  echo "=== Tools ==="
  for cmd in git gh glab rg gitleaks pwsh node npm uv python3 dotnet go java javac cargo rustc swift syft specify podman codex claude agy copilot code hx; do
    command -v "$cmd" > /dev/null 2>&1 && echo "  OK  $cmd" || echo "  --- $cmd: fehlt"
  done
  echo ""

  echo "=== sync-home ==="
  bash ~/home-baseline-source/scripts/sync-home.sh --no-pull 2>&1
  echo ""

  echo "=== check-homogeneity ==="
  bash ~/scripts/check-homogeneity.sh ~/ 2>&1

} | tee "$OUT"

cd ~/home-baseline-source
git pull --rebase --autostash origin main 2>&1 | cat
git add linux-test-output.txt
{
  git commit -m "test: Linux Test-Output (${DATE})" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
  git push origin HEAD:main
} 2>&1 | tee -a "$OUT"
echo "Gepusht." | tee -a "$OUT"
