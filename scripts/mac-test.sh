#!/usr/bin/env bash
# mac-test.sh - Mac Test Output Collector
set -euo pipefail
OUT="$HOME/home-baseline-source/mac-test-output.txt"
DATE=$(date "+%Y-%m-%d %H:%M:%S")
{
  echo "Mac Test Output - ${DATE}"
  echo "macOS: $(sw_vers -productVersion)"
  echo ""
  echo "=== Homebrew ==="
  brew --version 2>&1 || echo "brew: nicht gefunden"
  echo ""
  echo "=== Homebrew Top-Level Formulae ==="
  brew leaves --installed-on-request 2>&1 || echo "brew leaves: nicht verfuegbar"
  echo ""
  echo "=== Homebrew Casks ohne xquartz ==="
  brew list --cask 2>/dev/null | grep -Fvx 'xquartz' || true
  echo ""
  echo "=== Agentic Brew Registry Vergleich ==="
  bash "$HOME/home-baseline-source/scripts/maintain-agentic-brew-apps.sh" --compare-only 2>&1
  echo ""
  echo "=== PSScriptAnalyzer ==="
  pwsh -NoProfile -File "$HOME/home-baseline-source/scripts/maintain-powershell-modules.ps1" -CompareOnly 2>&1
  pwsh -NoProfile -File "$HOME/home-baseline-source/scripts/invoke-psscriptanalyzer.ps1" 2>&1
  echo ""
  echo "=== Workspace Maintenance Check ==="
  bash "$HOME/home-baseline-source/scripts/maintain-agentic-workspace.sh" --check-only --scripts-only 2>&1 || true
  echo ""
  echo "=== VS Code / Helix ==="
  if command -v code > /dev/null 2>&1; then
    code --version 2>&1 || true
    code --list-extensions 2>&1 || true
  else
    echo "code: nicht gefunden"
  fi
  if command -v hx > /dev/null 2>&1; then
    hx --version 2>&1 || true
  else
    echo "hx: nicht gefunden"
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
git add mac-test-output.txt
git commit -m "test: Mac Test-Output (${DATE})" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" 2>&1
git push origin HEAD:main 2>&1
echo "Gepusht."
