#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
canonical_launcher="/Users/bensuo/ghostty-codex-launchpad/git-ghostty-codex-launchpad.sh"

expected_roles=(BUILDER BACKEND CRITIC DEBUGGER)

collect_doc_roles() {
  awk '/^### / { print $2 }' "$project_root/docs/prompt-source.md"
}

collect_launcher_roles() {
  [ -f "$canonical_launcher" ] || {
    echo "Missing canonical launcher: $canonical_launcher" >&2
    return 1
  }

  python3 - <<'PY' "$canonical_launcher"
import re
import sys

path = sys.argv[1]
text = open(path, "r", encoding="utf-8").read()
match = re.search(r'roles=\(([^)]*)\)', text)
if not match:
    sys.exit(1)
for token in match.group(1).split():
    print(token.strip('"\''))
PY
}

has_unexpected_queue_manager() {
  local path
  local -a scan_paths=(
    "$project_root/README.md"
    "$project_root/AGENTS.md"
    "$project_root/docs/prompt-source.md"
    "$project_root/docs/generated-prompts.md"
    "$project_root/docs/generated-launcher-contract.md"
  )

  for path in "${scan_paths[@]}"; do
    [ -f "$path" ] || continue
    if rg -n 'QUEUE-MANAGER' "$path" >/dev/null 2>&1; then
      echo "Unexpected QUEUE-MANAGER reference found in $(basename "$path")." >&2
      rg -n 'QUEUE-MANAGER' "$path" >&2 || true
      return 0
    fi
  done

  return 1
}

check_exact_role_list() {
  local source_name=$1
  shift
  local -a actual_roles=("$@")
  local role expected found

  if [ "${#actual_roles[@]}" -ne "${#expected_roles[@]}" ]; then
    echo "$source_name role count mismatch: expected ${#expected_roles[@]}, got ${#actual_roles[@]}." >&2
    printf '%s roles:' "$source_name" >&2
    printf ' %s' "${actual_roles[@]}" >&2
    printf '\n' >&2
    return 1
  fi

  for role in "${actual_roles[@]}"; do
    found=0
    for expected in "${expected_roles[@]}"; do
      if [ "$role" = "$expected" ]; then
        found=1
        break
      fi
    done

    if [ "$found" -eq 0 ]; then
      echo "$source_name contains unexpected role: $role." >&2
      return 1
    fi
  done

  for expected in "${expected_roles[@]}"; do
    found=0
    for role in "${actual_roles[@]}"; do
      if [ "$role" = "$expected" ]; then
        found=1
        break
      fi
    done

    if [ "$found" -eq 0 ]; then
      echo "$source_name is missing required role: $expected." >&2
      return 1
    fi
  done
}

doc_roles=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  doc_roles+=("$line")
done < <(collect_doc_roles)

launcher_roles=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  launcher_roles+=("$line")
done < <(collect_launcher_roles)

check_exact_role_list "docs/prompt-source.md" "${doc_roles[@]}"
check_exact_role_list "canonical launcher" "${launcher_roles[@]}"

if has_unexpected_queue_manager; then
  exit 1
fi

echo "Role set check passed."
