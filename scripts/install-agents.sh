#!/usr/bin/env bash
# Usage (Git Bash): bash scripts/install-agents.sh [path-to-agency-agents-clone]
# Installs the company's curated roster from msitarzewski/agency-agents into ~/.claude/agents
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$HOME/agency-agents}"
if [ ! -d "$SRC" ]; then git clone https://github.com/msitarzewski/agency-agents.git "$SRC"; else git -C "$SRC" pull --ff-only; fi
cd "$SRC"
./scripts/install.sh --tool claude-code --agents-file "$HERE/setup/agency-roster.txt" --no-interactive
echo "Installed. In Claude Code run /agents to see them."
