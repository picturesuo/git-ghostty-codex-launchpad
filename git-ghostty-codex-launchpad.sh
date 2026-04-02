#!/bin/bash
set -euo pipefail

applescript_string() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}

slugify() {
  local value=$1
  value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
  value="${value#-}"
  value="${value%-}"
  printf '%s' "$value"
}

prompt_project_name() {
  local dialog_result

  if ! dialog_result="$(
    osascript <<'EOF'
try
  text returned of (display dialog "What project are we working on?" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
on error number -128
  return ""
end try
EOF
  )"; then
    dialog_result=""
  fi

  PROJECT_NAME="$dialog_result"
}

find_glob_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\*/\\*}
  value=${value//\?/\\?}
  value=${value//[/\\[}
  printf '%s' "$value"
}

search_root_for_project() {
  local search_root=$1
  local name_pattern=$2
  local max_depth=$3
  local candidate

  [[ -d "$search_root" ]] || return 1

  if [[ "$search_root" == "$HOME" ]]; then
    candidate="$(
      find "$search_root" -maxdepth "$max_depth" \
        \( \
          -path "$HOME/Library" -o \
          -path "$HOME/Movies" -o \
          -path "$HOME/Music" -o \
          -path "$HOME/Pictures" -o \
          -path "$HOME/Applications" -o \
          -path "$HOME/.Trash" \
        \) -prune -o \
        -type d \
        \( \
          \( -iname "$name_pattern" \) \
          -a \
          \( -exec test -d {}/.git \; -o -exec test -f {}/package.json \; -o -exec test -f {}/README.md \; -o -exec test -f {}/README.mdx \; \) \
        \) \
        -print -quit 2>/dev/null || true
    )"
  else
    candidate="$(
      find "$search_root" -maxdepth "$max_depth" -type d \
        \( \
          \( -iname "$name_pattern" \) \
          -a \
          \( -exec test -d {}/.git \; -o -exec test -f {}/package.json \; -o -exec test -f {}/README.md \; -o -exec test -f {}/README.mdx \; \) \
        \) \
        -print -quit 2>/dev/null || true
    )"
  fi

  if [[ -n "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  return 1
}

search_project_dir() {
  local project_name=$1
  local search_root candidate pattern
  local lowered normalized mdfind_project_name mdfind_lowered
  local exact_roots likely_roots fuzzy_roots
  lowered="$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]')"
  normalized="$(slugify "$project_name")"
  mdfind_project_name="${project_name//\'/}"
  mdfind_lowered="${lowered//\'/}"
  exact_roots=("$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Projects")
  likely_roots=(
    "$HOME/Code"
    "$HOME/src"
    "$HOME/dev"
    "$HOME/work"
    "$HOME/workspace"
    "$HOME/workspaces"
    "$HOME/repos"
    "$HOME/repo"
  )
  fuzzy_roots=("$HOME")

  for search_root in "${exact_roots[@]}"; do
    for pattern in "$(find_glob_escape "$project_name")" "$(find_glob_escape "$normalized")"; do
      if candidate="$(search_root_for_project "$search_root" "$pattern" 5)"; then
        printf '%s' "$candidate"
        return
      fi
    done
  done

  for search_root in "${likely_roots[@]}"; do
    for pattern in "*$(find_glob_escape "$project_name")*" "*$(find_glob_escape "$lowered")*" "*$(find_glob_escape "$normalized")*"; do
      if candidate="$(search_root_for_project "$search_root" "$pattern" 4)"; then
        printf '%s' "$candidate"
        return
      fi
    done
  done

  if command -v mdfind >/dev/null 2>&1; then
    candidate="$(
      mdfind "kMDItemFSName == '*${mdfind_project_name}*'cd || kMDItemFSName == '*${mdfind_lowered}*'cd" 2>/dev/null \
        | while read -r path; do
            if [[ -d "$path" && ( -d "$path/.git" || -f "$path/package.json" || -f "$path/README.md" || -f "$path/README.mdx" ) ]]; then
              printf '%s\n' "$path"
            fi
          done | head -n 1 || true
    )"

    if [[ -n "$candidate" ]]; then
      printf '%s' "$candidate"
      return
    fi
  fi

  for search_root in "${fuzzy_roots[@]}"; do
    for pattern in "*$(find_glob_escape "$project_name")*" "*$(find_glob_escape "$lowered")*" "*$(find_glob_escape "$normalized")*"; do
      if candidate="$(search_root_for_project "$search_root" "$pattern" 4)"; then
        printf '%s' "$candidate"
        return
      fi
    done
  done

  printf '%s' ""
}

make_shared_context() {
  local project_name=$1
  local project_dir=$2
  local session_dir="$HOME/.codex"
  local session_file="$session_dir/$(slugify "$project_name")-shared-context.md"
  mkdir -p "$session_dir"

  cat > "$session_file" <<EOF
# Codex shared session context

- Project name: $project_name
- Project directory: $project_dir
- Session source of truth: this file

This session is for the named project only.
Wait for the user to give the next instruction before making changes.
At the end of every turn, include a concise summary of what changed and a clear request asking whether to commit.
Before any commit is made, list changed files, identify which are directly related to the current task, exclude unrelated or suspicious changes, summarize what changed, propose a commit message, and wait for explicit user approval.
Use this exact end-of-turn format every time:
1. Summary: one or two sentences describing what changed.
2. Changed files: list only the files you actually touched.
3. Commit command: write the exact git commit command you want to use, in a single line.
4. Push command: write the exact git push command you want to use, in a single line.
5. Commit plan: explain in one sentence that you are waiting for approval before running either command.
6. Commit request: explicitly ask whether to commit now.
7. Status: say you are waiting for approval.
EOF

  SHARED_CONTEXT_FILE="$session_file"
}

role_prompt() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local session_file=$4
  local role_name role_scope role_limits

  case "$role" in
    BUILDER)
      role_name="BUILDER"
      role_scope="Main feature work and end-to-end user-facing implementation."
      role_limits="Do not refactor unrelated code or touch backend/auth/infra unless needed."
      ;;
    BACKEND)
      role_name="BACKEND"
      role_scope="APIs, database, validation, auth, and business logic."
      role_limits="Do not do UI polish or unrelated refactors."
      ;;
    DEBUGGER)
      role_name="DEBUGGER"
      role_scope="Root-cause analysis for bugs, broken behavior, and failures."
      role_limits="Only make the minimum code change needed to fix the issue."
      ;;
    TESTER)
      role_name="TESTER"
      role_scope="Verification, edge cases, and stability checks after the feature works."
      role_limits="Do not invent new behavior or do broad rewrites."
      ;;
  esac

  cat <<EOF
Shared project context:
- Project name: $project_name
- Project directory: $project_dir
- Shared context file: $session_file

You are the $role_name.
$role_scope
$role_limits
Turn workflow: At the end of every turn, include a concise summary of what changed and explicitly ask whether to commit.
Commit workflow: Before any commit is made, list changed files, identify which are directly related to the current task, exclude unrelated or suspicious changes, summarize what changed, propose a commit message, and wait for explicit user approval.
Use this exact end-of-turn format every time:
1. Summary: one or two sentences describing what changed.
2. Changed files: list only the files you actually touched.
3. Commit command: write the exact git commit command you want to use, in a single line.
4. Push command: write the exact git push command you want to use, in a single line.
5. Commit plan: explain in one sentence that you are waiting for approval before running either command.
6. Commit request: explicitly ask whether to commit now.
7. Status: say you are waiting for approval.

Return:
1. Your role.
2. A short summary of what you should do.
3. A short summary of what you should avoid.
4. Any questions about the project folder or scope.

If you have no questions, say you are ready.
EOF
}

launch_ghostty_session() {
  local prompt1=$1
  local prompt2=$2
  local prompt3=$3
  local prompt4=$4

  osascript <<EOF
tell application "Ghostty"
  activate

  set launcherWindow to front window
  set cfg to new surface configuration
  set initial working directory of cfg to $(applescript_string "$HOME")
  set environment variables of cfg to {"GHOSTTY_LAUNCHPAD_SESSION=1"}
  set win to new window with configuration cfg
  set pane1 to terminal 1 of selected tab of win
  set pane2 to split pane1 direction right with configuration cfg
  set pane3 to split pane1 direction right with configuration cfg
  set pane4 to split pane2 direction right with configuration cfg

  input text "codex" to pane1
  input text "codex" to pane2
  input text "codex" to pane3
  input text "codex" to pane4

  send key "enter" to pane1
  send key "enter" to pane2
  send key "enter" to pane3
  send key "enter" to pane4

  delay 2

  input text $(applescript_string "$prompt1") to pane1
  input text $(applescript_string "$prompt2") to pane2
  input text $(applescript_string "$prompt3") to pane3
  input text $(applescript_string "$prompt4") to pane4

  send key "enter" to pane1
  send key "enter" to pane2
  send key "enter" to pane3
  send key "enter" to pane4

  try
    close window launcherWindow
  end try
end tell
EOF
}

main() {
  local project_name project_dir session_file project_name_compact
  local -a roles prompts
  local role

  prompt_project_name
  project_name="$PROJECT_NAME"
  project_name_compact="$(printf '%s' "$project_name" | tr -d '[:space:]')"

  if [[ -z "$project_name_compact" ]]; then
    return 0
  fi

  project_dir="$(search_project_dir "$project_name")"
  if [[ -z "$project_dir" ]]; then
    project_dir="$HOME"
  fi

  make_shared_context "$project_name" "$project_dir"
  session_file="$SHARED_CONTEXT_FILE"

  roles=(BUILDER BACKEND DEBUGGER TESTER)
  for role in "${roles[@]}"; do
    prompts+=("$(role_prompt "$role" "$project_name" "$project_dir" "$session_file")")
  done

  launch_ghostty_session "${prompts[0]}" "${prompts[1]}" "${prompts[2]}" "${prompts[3]}"

  printf 'Prepared Ghostty Codex session for %s\nProject directory: %s\nShared context: %s\n' "$project_name" "$project_dir" "$session_file"
}

main "$@"
