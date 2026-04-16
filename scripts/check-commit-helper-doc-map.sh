#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"

expected_repo="picturesuo/git-ghostty-codex-launchpad"

match="$(
  rg --no-filename -o -N '(github\.com[:/]|https://github\.com/)[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' \
    "$project_root/README.md" \
    "$project_root/AGENTS.md" \
    "$project_root/docs/knowledge.md" 2>/dev/null || true
)" 

match="$(
  printf '%s\n' "$match" | \
    sed -E 's#(https://github\.com/|github\.com[:/])##; s/\.git$//' | \
    head -n1
)"

if [ -z "$match" ]; then
  match="$(
    rg --no-filename -o -N '(GitHub repo:|Canonical GitHub repo slug is) `[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+`' \
      "$project_root/README.md" \
      "$project_root/docs/knowledge.md" 2>/dev/null || true
  )"

  match="$(
    printf '%s\n' "$match" | \
      sed -E 's/.*`([^`]+)`.*/\1/' | \
      head -n1
  )"
fi

if [ -z "$match" ]; then
  echo "No GitHub repo mapping found in repo docs." >&2
  exit 1
fi

if [ "$match" != "$expected_repo" ]; then
  echo "Doc-mapped repo mismatch: expected $expected_repo, found $match" >&2
  exit 1
fi

if command -v gh >/dev/null 2>&1; then
  gh repo view "$match" --json nameWithOwner --jq '.nameWithOwner' >/dev/null
fi

echo "Commit helper doc-map check passed: $match"
