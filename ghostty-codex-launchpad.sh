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
  PROJECT_NAME="$(
    osascript <<'EOF'
text returned of (display dialog "What project are we working on?" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
  )"
}

search_project_dir() {
  local project_name=$1
  local search_root candidate
  local lowered normalized
  local exact_roots fuzzy_roots
  lowered="$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]')"
  normalized="$(slugify "$project_name")"
  exact_roots=("$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Projects")
  fuzzy_roots=("$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Projects" "$HOME")

  for search_root in "${exact_roots[@]}"; do
    [[ -d "$search_root" ]] || continue

    candidate="$(
      find "$search_root" -maxdepth 5 -type d \
        \( \
          \( -iname "$project_name" -o -iname "$normalized" \) \
          -a \
          \( -exec test -d {}/.git \; -o -exec test -f {}/package.json \; -o -exec test -f {}/README.md \; -o -exec test -f {}/README.mdx \; \) \
        \) \
        -print -quit 2>/dev/null || true
    )"

    if [[ -n "$candidate" ]]; then
      printf '%s' "$candidate"
      return
    fi
  done

  if command -v mdfind >/dev/null 2>&1; then
    candidate="$(
      mdfind "kMDItemFSName == '*${project_name}*'cd || kMDItemFSName == '*${lowered}*'cd" 2>/dev/null \
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
    [[ -d "$search_root" ]] || continue

    candidate="$(
      find "$search_root" -maxdepth 4 -type d \
        \( \
          \( -iname "*$project_name*" -o -iname "*$lowered*" \) \
          -a \
          \( -exec test -d {}/.git \; -o -exec test -f {}/package.json \; -o -exec test -f {}/README.md \; -o -exec test -f {}/README.mdx \; \) \
        \) \
        -print -quit 2>/dev/null || true
    )"

    if [[ -n "$candidate" ]]; then
      printf '%s' "$candidate"
      return
    fi
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
Before any commit or push to GitHub is made, list changed files, identify which are directly related to the current task, exclude unrelated or suspicious changes, summarize what changed, propose a commit message, and wait for explicit user approval.
After permission is given, git can stage the approved files, create the commit, and push it online to GitHub automatically.
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
Commit workflow: Before any commit or push to GitHub is made, list changed files, identify which are directly related to the current task, exclude unrelated or suspicious changes, summarize what changed, propose a commit message, and wait for explicit user approval.
After permission is given, git can stage the approved files, create the commit, and push it online to GitHub automatically.

Return:
1. Your role.
2. A short summary of what you should do.
3. A short summary of what you should avoid.
4. Any questions about the project folder or scope.

If you have no questions, say you are ready.
EOF
}

main() {
  osascript <<EOF
tell application "Ghostty"
  activate

  set cfg to new surface configuration
  set initial working directory of cfg to $(applescript_string "$HOME")
  set win to new window with configuration cfg
  set tab1 to tab 1 of win
  set tab2 to new tab in win with configuration cfg
  set tab3 to new tab in win with configuration cfg
  set tab4 to new tab in win with configuration cfg

  set pane1 to focused terminal of tab1
  set pane2 to focused terminal of tab2
  set pane3 to focused terminal of tab3
  set pane4 to focused terminal of tab4

  input text "codex" to pane1
  input text "codex" to pane2
  input text "codex" to pane3
  input text "codex" to pane4

  send key "enter" to pane1
  send key "enter" to pane2
  send key "enter" to pane3
  send key "enter" to pane4
end tell
EOF

  sleep 2

  local project_name project_dir session_file prompt1 prompt2 prompt3 prompt4

  prompt_project_name
  project_name="$PROJECT_NAME"

  project_dir="$(search_project_dir "$project_name")"
  if [[ -z "$project_dir" ]]; then
    project_dir="$HOME"
  fi

  make_shared_context "$project_name" "$project_dir"
  session_file="$SHARED_CONTEXT_FILE"

  prompt1="$(role_prompt BUILDER "$project_name" "$project_dir" "$session_file")"
  prompt2="$(role_prompt BACKEND "$project_name" "$project_dir" "$session_file")"
  prompt3="$(role_prompt DEBUGGER "$project_name" "$project_dir" "$session_file")"
  prompt4="$(role_prompt TESTER "$project_name" "$project_dir" "$session_file")"

  osascript <<EOF
tell application "Ghostty"
  activate

  set tab1 to tab 1 of front window
  set tab2 to tab 2 of front window
  set tab3 to tab 3 of front window
  set tab4 to tab 4 of front window

  set pane1 to focused terminal of tab1
  set pane2 to focused terminal of tab2
  set pane3 to focused terminal of tab3
  set pane4 to focused terminal of tab4

  input text $(applescript_string "$prompt1") to pane1
  input text $(applescript_string "$prompt2") to pane2
  input text $(applescript_string "$prompt3") to pane3
  input text $(applescript_string "$prompt4") to pane4

  send key "enter" to pane1
  send key "enter" to pane2
  send key "enter" to pane3
  send key "enter" to pane4
end tell
EOF

  printf 'Prepared Ghostty Codex session for %s\nProject directory: %s\nShared context: %s\n' "$project_name" "$project_dir" "$session_file"
}

main "$@"
