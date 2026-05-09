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

test_saved_state_repair_for_shifted_fields() {
  local project_dir="$tmp_root/repair-project"
  local session_file="$tmp_root/repair-shared-context.md"
  local state_file="$tmp_root/repair-last-session.md"

  mkdir -p "$project_dir/docs"
  printf '# Queue\n\n## Now\n- [ ] Repair queue\n' > "$project_dir/docs/queue.md"
  printf '# Knowledge\n' > "$project_dir/docs/knowledge.md"
  printf '# Shared\n- Project name: Repair\n- Project directory: %s\n- Target file: README.md\n- Active task artifact ID: README.md\n- Session ID: repair12\n' "$project_dir" > "$session_file"
  {
    printf '# Ghostty Codex Launchpad Last Session\n\n'
    printf -- '- Project name: Repair\n'
    printf -- '- Project directory: %s\n' "$project_dir"
    printf -- '- Target file: README.md\n'
    printf -- '- Shared context file: %s\n' "$session_file"
    printf -- '- Git remote path: %s/docs/queue.md\n' "$project_dir"
    printf -- '- GitHub repo: %s/docs/knowledge.md\n' "$project_dir"
    printf -- '- Queue file: Repair queue\n'
    printf -- '- Knowledge file: main\n'
  } > "$state_file"

  LAUNCHPAD_LAST_SESSION_FILE="$state_file"
  repair_saved_launch_state_if_needed "$state_file"

  assert_eq "" "$(launch_state_header_value "$state_file" "Git remote path")" "repaired git remote path"
  assert_eq "$project_dir/docs/queue.md" "$(launch_state_header_value "$state_file" "Queue file")" "repaired queue file"
  assert_eq "$project_dir/docs/knowledge.md" "$(launch_state_header_value "$state_file" "Knowledge file")" "repaired knowledge file"
}

test_role_layout_generation() {
  build_session_roles 8

  assert_eq "BUILDER BACKEND DEBUGGER CRITIC BACKEND-2 CRITIC-2 DEBUGGER-2 BUILDER-2" "${SESSION_ROLES[*]}" "eight-pane role layout"
}

test_split_layout_generation() {
  local expected

  expected="$(printf '%s\n%s\n%s\n%s' \
    '  set pane2 to split pane1 direction right with configuration cfg' \
    '  set pane3 to split pane2 direction right with configuration cfg' \
    '  set pane4 to split pane3 direction right with configuration cfg' \
    '  perform action "equalize_splits" on pane1')"

  assert_eq "$expected" "$(build_session_split_applescript 4)" "four-pane split layout is equalized"
  assert_eq "" "$(build_session_split_applescript 1)" "single-pane split layout has no equalization"
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

test_claude_bootstrap_files() {
  local project_dir="$tmp_root/bootstrap-project"
  local formatter_project_dir="$tmp_root/formatter-project"

  seed_project_workflow_files "Bootstrap" "$project_dir"

  [[ -f "$project_dir/CLAUDE.md" ]] || { printf 'FAIL CLAUDE.md was not seeded\n' >&2; exit 1; }
  [[ -f "$project_dir/docs/agent-workflow.md" ]] || { printf 'FAIL docs/agent-workflow.md was not seeded\n' >&2; exit 1; }
  [[ -f "$project_dir/.claude/commands/commit-push-pr.md" ]] || { printf 'FAIL Claude command was not seeded\n' >&2; exit 1; }
  [[ -f "$project_dir/.claude/settings.json" ]] || { printf 'FAIL Claude settings were not seeded\n' >&2; exit 1; }

  if rg -q '"hooks"' "$project_dir/.claude/settings.json"; then
    printf 'FAIL formatter hook was seeded without a formatter\n' >&2
    exit 1
  fi

  mkdir -p "$formatter_project_dir"
  printf '{"scripts":{"format":"prettier --write ."}}\n' > "$formatter_project_dir/package.json"
  printf 'lockfileVersion: 9\n' > "$formatter_project_dir/pnpm-lock.yaml"
  seed_project_workflow_files "Formatter" "$formatter_project_dir"

  rg -q '"PostToolUse"' "$formatter_project_dir/.claude/settings.json" || { printf 'FAIL formatter hook was not seeded\n' >&2; exit 1; }
  rg -q 'pnpm format' "$formatter_project_dir/.claude/settings.json" || { printf 'FAIL formatter hook did not use pnpm\n' >&2; exit 1; }
}

test_prompt_docs_rendering() {
  bash "$project_root/scripts/check-prompt-drift.sh" >/dev/null
}

test_skill_validation() {
  bash "$project_root/scripts/validate-skills.sh" >/dev/null
}

test_saved_state_round_trip_with_empty_fields
test_saved_state_repair_for_shifted_fields
test_role_layout_generation
test_split_layout_generation
test_agent_command_generation
test_commit_helper_launcher_remote_fallback
test_claude_bootstrap_files
test_prompt_docs_rendering
test_skill_validation

printf 'Launcher tests passed.\n'
