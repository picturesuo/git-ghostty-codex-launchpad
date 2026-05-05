#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"

source "$project_root/git-ghostty-codex-launchpad.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

assert_eq() {
  local expected=$1
  local actual=$2
  local label=$3

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL %s\nexpected: %s\nactual:   %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

test_saved_state_round_trip_with_empty_fields() {
  local project_dir="$tmp_root/state-project"
  local session_file="$tmp_root/shared-context.md"
  local state_file="$tmp_root/last-session.md"

  mkdir -p "$project_dir/docs"
  printf '# Queue\n\n## Now\n- [ ] Test queue\n' > "$project_dir/docs/queue.md"
  printf '# Knowledge\n' > "$project_dir/docs/knowledge.md"
  printf '# Shared\n- Project name: Demo\n- Project directory: %s\n- Target file: README.md\n- Active task artifact ID: README.md\n- Session ID: abc12345\n' "$project_dir" > "$session_file"

  LAUNCHPAD_LAST_SESSION_FILE="$state_file"
  store_last_launch_state "Demo" "$project_dir" "README.md" "$session_file" "" "" "" "mixed" "5" "auto"

  assert_eq "" "$(launch_state_header_value "$state_file" "Git remote path")" "blank git remote path stays blank"
  assert_eq "" "$(launch_state_header_value "$state_file" "GitHub repo")" "blank GitHub repo stays blank"
  assert_eq "$project_dir/docs/queue.md" "$(launch_state_header_value "$state_file" "Queue file")" "queue file does not shift into remote"
  assert_eq "mixed" "$(launch_state_header_value "$state_file" "Agent profile")" "agent profile persisted"
  assert_eq "5" "$(launch_state_header_value "$state_file" "Pane count")" "pane count persisted"
}

test_role_layout_generation() {
  build_session_roles 8

  assert_eq "BUILDER BACKEND DEBUGGER CRITIC BACKEND-2 CRITIC-2 DEBUGGER-2 BUILDER-2" "${SESSION_ROLES[*]}" "eight-pane role layout"
}

test_agent_command_generation() {
  assert_eq "codex 'build it'" "$(pane_command codex BACKEND "build it")" "codex command"
  assert_eq "claude 'check it'" "$(pane_command claude CRITIC "check it")" "claude command"
  assert_eq "claude 'fix it'" "$(pane_command mixed DEBUGGER "fix it")" "mixed debugger command"
  assert_eq "codex 'parallel build'" "$(pane_command mixed BACKEND-2 "parallel build")" "mixed backend repeat command"
}

test_commit_helper_launcher_remote_fallback() {
  local repo_dir="$tmp_root/remote-project"
  local bare_dir="$tmp_root/remote.git"

  git init -q --bare "$bare_dir" >/dev/null
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init -q >/dev/null
  git -C "$repo_dir" config user.name "Launcher Test"
  git -C "$repo_dir" config user.email "launcher-test@example.com"
  printf 'one\n' > "$repo_dir/file.txt"

  GIT_REMOTE_PATH="$bare_dir" bash "$project_root/scripts/codex-commit.sh" --project-root "$repo_dir" file.txt >/dev/null 2>&1

  assert_eq "$bare_dir" "$(git -C "$repo_dir" remote get-url origin)" "launcher remote added as origin"
  if ! git --git-dir="$bare_dir" log --oneline --all -1 >/dev/null 2>&1; then
    printf 'FAIL commit helper did not push to launcher-provided remote\n' >&2
    exit 1
  fi
}

test_prompt_docs_rendering() {
  bash "$project_root/scripts/check-prompt-drift.sh" >/dev/null
}

test_saved_state_round_trip_with_empty_fields
test_role_layout_generation
test_agent_command_generation
test_commit_helper_launcher_remote_fallback
test_prompt_docs_rendering

printf 'Launcher tests passed.\n'
