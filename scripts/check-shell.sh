#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is not installed. Install shellcheck and rerun scripts/check-shell.sh." >&2
  exit 1
fi

shellcheck \
  "$project_root/git-ghostty-codex-launchpad.sh" \
  "$project_root/start-git-ghostty-codex-launchpad.sh" \
  "$project_root/open-git-ghostty-codex-launchpad.command" \
  "$project_root/scripts/check-commit-helper-doc-map.sh" \
  "$project_root/scripts/check-prompt-drift.sh" \
  "$project_root/scripts/codex-commit.sh" \
  "$project_root/scripts/render-prompt-docs.sh"

echo "Shell check passed."
