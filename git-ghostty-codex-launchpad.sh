#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prompts/prompt-source.sh"

SHELL_STARTUP_DELAY_SECONDS=1.5
CODEX_PROMPT_STAGGER_SECONDS=2
LAUNCHPAD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_COMMIT_HELPER="$LAUNCHPAD_ROOT/scripts/codex-commit.sh"

applescript_string() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}

shell_single_quote() {
  local value=$1
  value=${value//\'/\'\\\'\'}
  printf "'%s'" "$value"
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

prompt_new_file_name() {
  local dialog_result

  if ! dialog_result="$(
    osascript <<'EOF'
try
  text returned of (display dialog "No existing project was found. What file should I create first?" default answer "" buttons {"Cancel", "Create"} default button "Create")
on error number -128
  return ""
end try
EOF
  )"; then
    dialog_result=""
  fi

  NEW_FILE_NAME="$dialog_result"
}

derive_project_name_from_file() {
  local requested_file=$1
  local base_name

  requested_file="$(sanitize_relative_file_path "$requested_file")"
  if [[ -z "$requested_file" ]]; then
    printf '%s' "new project"
    return
  fi

  base_name="$(basename "$requested_file")"
  base_name="${base_name%.*}"
  base_name="${base_name//[-_]/ }"
  base_name="${base_name#"${base_name%%[![:space:]]*}"}"
  base_name="${base_name%"${base_name##*[![:space:]]}"}"

  if [[ -z "$base_name" ]]; then
    printf '%s' "new project"
    return
  fi

  printf '%s' "$base_name"
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

default_new_project_root() {
  if [[ -d "$HOME/Projects" ]]; then
    printf '%s' "$HOME/Projects"
    return
  fi

  printf '%s' "$HOME/Desktop"
}

sanitize_relative_file_path() {
  local value=$1
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  value="${value#./}"

  while [[ "$value" == */* ]]; do
    value="${value//\/\//\/}"
    [[ "$value" == *"//"* ]] || break
  done

  if [[ -z "$value" || "$value" == /* ]]; then
    printf '%s' ""
    return
  fi

  case "$value" in
    .|..|../*|*/../*|*/..)
      printf '%s' ""
      return
      ;;
  esac

  printf '%s' "$value"
}

seed_project_workflow_files() {
  local project_name=$1
  local project_dir=$2

  mkdir -p "$project_dir/docs"

  if [[ ! -e "$project_dir/AGENTS.md" ]]; then
    cat > "$project_dir/AGENTS.md" <<EOF
# AGENTS.md

## Purpose
This file is the repo-local operating manual for Codex in "$project_name".

Read it at the start of each session.
Follow it unless the user explicitly overrides it.
Keep it current.

## Shared Context
- If a shared context file exists, use it as the durable task artifact for the current task.
- Update only the sections or artifact IDs owned by your role.
- Do not rewrite the whole shared context file.
- Keep durable reusable knowledge in `docs/knowledge.md`; keep current-task state in the shared context file.

## Working Rules
- Keep scope tight.
- Prefer small, reversible changes.
- State assumptions explicitly when needed.
- Publish verified completed work with `bash $(printf '%q' "$CODEX_COMMIT_HELPER") <paths...>`.
- Use `--no-push` only when a local-only commit is intentional.
- Do not auto-publish partial, failing, or unverified work.
EOF
  fi

  if [[ ! -e "$project_dir/docs/queue.md" ]]; then
    cat > "$project_dir/docs/queue.md" <<'EOF'
# Queue

## Now
- [ ] Initialize the first real task artifact.

## Next
- [ ] Add the next smallest shippable step.
- [ ] Capture the main edge case.
- [ ] Capture one cleanup item.

## Later
- [ ] Expand only when the project grows.

## Blocked
- [ ] No blockers recorded yet.

## Discovered While Working
- [ ] Fill this in as the session learns new details.
EOF
  fi

  if [[ ! -e "$project_dir/docs/knowledge.md" ]]; then
    cat > "$project_dir/docs/knowledge.md" <<'EOF'
# Knowledge

## User-Provided Knowledge
- Capture durable user guidance, preferences, and constraints that should survive past a single task.

## Project Facts
- Capture stable project facts, decisions, and summaries worth reusing across tasks.

## Retrieval Hints
- Search this file, the shared context file, and nearby repo docs with `rg` before broader search.
- Label each note by source when useful: `user`, `repo`, or `external`.
EOF
  fi
}

create_new_project() {
  local project_name=$1
  local requested_file=$2
  local project_root project_dir target_file parent_dir
  local project_slug

  project_slug="$(slugify "$project_name")"
  if [[ -z "$project_slug" ]]; then
    project_slug="new-project"
  fi

  target_file="$(sanitize_relative_file_path "$requested_file")"
  if [[ -z "$target_file" ]]; then
    target_file="AGENTS.md"
  fi

  project_root="$(default_new_project_root)"
  project_dir="$project_root/$project_slug"

  mkdir -p "$project_dir"
  parent_dir="$(dirname "$project_dir/$target_file")"
  mkdir -p "$parent_dir"

  if [[ ! -e "$project_dir/$target_file" ]]; then
    : > "$project_dir/$target_file"
  fi

  seed_project_workflow_files "$project_name" "$project_dir"

  CREATED_PROJECT_DIR="$project_dir"
  CREATED_TARGET_FILE="$target_file"
}

choose_target_file() {
  local project_dir=$1
  local file

  if [[ ! -f "$project_dir/AGENTS.md" ]]; then
    printf '%s' "AGENTS.md"
    return
  fi

  local candidates=(
    "app/page.tsx"
    "app/page.jsx"
    "app/page.ts"
    "pages/index.tsx"
    "pages/index.jsx"
    "src/app/page.tsx"
    "src/app/page.jsx"
    "src/pages/index.tsx"
    "src/pages/index.jsx"
    "src/index.ts"
    "src/index.tsx"
    "src/index.js"
    "src/index.jsx"
    "index.ts"
    "index.tsx"
    "index.js"
    "index.jsx"
    "README.md"
  )

  for file in "${candidates[@]}"; do
    if [[ -f "$project_dir/$file" ]]; then
      printf '%s' "$file"
      return
    fi
  done

  find "$project_dir" -maxdepth 2 -type f \
    \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.md' \) \
    -print | head -n 1 | sed "s#^$project_dir/##" || true
}

workflow_contract() {
  cat <<'EOF'
## Workflow Contract

- `AGENTS.md` is the durable repo policy.
- Use the shared context file as the durable TASK ARTIFACT and source of truth.
- Do not repeat repo policy in every prompt if `AGENTS.md` already covers it.
- Keep prompts short, concrete, and role-specific.
- Prefer clear ownership over overlapping responsibilities.
- The launcher may seed a generic bootstrap artifact before the first concrete user task exists.
- Refine the bootstrap artifact into task-specific details as soon as the user gives a concrete request.
- Do not return `NOT READY` solely because the artifact is still in its bootstrap state.
- Do not use `/fast` or enable fast mode as part of this workflow.
- Do not rewrite the whole shared context file.
- Update only the sections or artifact IDs owned by your role.
- Preserve useful existing content.
- Work inside the project directory.
- Treat `Target file` as a starting point, not a hard restriction, unless the artifact explicitly says otherwise.
- Do not invent unrelated requirements.
- State assumptions as `Q` or `R` items.
- Keep durable reusable knowledge in `docs/knowledge.md`; keep current-task state in the shared context file.
- Prefer lightweight local retrieval first: search `docs/knowledge.md`, the shared context, and nearby repo docs with `rg` before broader search.
- Use online search only when local project context and recorded knowledge are insufficient for the task.
- Treat user-provided knowledge, repo facts, and search-derived information as distinct sources and label them when recording reusable notes.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- When that completion bar is met, publish the intended files with `bash $CODEX_COMMIT_HELPER <paths...>`.
- Do not auto-publish partial, failing, or unverified work.
- Reference artifact IDs exactly: `SC1`, `INV1`, `FM1`, `R1`, `Q1`, `F1`.
- Keep scope tight and avoid task expansion unless a true blocker is identified.
- Distinguish clearly between goal, implementation, verification, and diagnosis.
- Prefer structured, low-verbosity output that later roles can reuse directly.
- Run the lightest checks that materially reduce risk.
- Only claim verification that was actually performed.
- Record verified items and remaining uncertainty in the artifact.
- If validation is incomplete or failing, do not publish; record why in the artifact.
- Never ask for commit approval.
- Do not include commit message or commit request text in the response unless explicitly requested.
- Stage only intended files inside the project directory.
- If nothing changed, do not commit.
EOF
}

legacy_workflow_contract_v1() {
  cat <<'EOF'
## Workflow Contract

- `AGENTS.md` is the durable repo policy.
- Use the shared context file as the durable TASK ARTIFACT and source of truth.
- Do not repeat repo policy in every prompt if `AGENTS.md` already covers it.
- Keep prompts short, concrete, and role-specific.
- Prefer clear ownership over overlapping responsibilities.
- On the first pass in a newly opened tab, the artifact may still be empty or only contain placeholders. Do not treat that as a failure.
- If you are the Builder and the artifact is still empty, initialize it before implementation.
- If you are not the Builder and the artifact is still empty on the first pass, return `NOT READY` in the normal response format and stop.
- Do not use `/fast` or enable fast mode as part of this workflow.
- Do not rewrite the whole shared context file.
- Update only the sections or artifact IDs owned by your role.
- Preserve useful existing content.
- Work inside the project directory.
- Treat `Target file` as a starting point, not a hard restriction, unless the artifact explicitly says otherwise.
- Do not invent unrelated requirements.
- State assumptions as `Q` or `R` items.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- When that completion bar is met, publish the intended files with `bash scripts/codex-commit.sh --push <paths...>`.
- Do not auto-publish partial, failing, or unverified work.
- Reference artifact IDs exactly: `SC1`, `INV1`, `FM1`, `R1`, `Q1`, `F1`.
- Keep scope tight and avoid task expansion unless a true blocker is identified.
- Distinguish clearly between goal, implementation, verification, and diagnosis.
- Prefer structured, low-verbosity output that later roles can reuse directly.
- Run the lightest checks that materially reduce risk.
- Only claim verification that was actually performed.
- Record verified items and remaining uncertainty in the artifact.
- If validation is incomplete or failing, do not publish; record why in the artifact.
- Never ask for commit approval.
- Do not include commit message or commit request text in the response unless explicitly requested.
- Stage only intended files inside the project directory.
- If nothing changed, do not commit.
EOF
}

task_artifact_template() {
  cat <<'EOF'
## TASK ARTIFACT

1. Goal
- Capture the next concrete request without blocking startup on placeholder setup.

2. Scope
- In scope: refine this artifact and make the smallest directly requested change once the task is clear.
- Out of scope: unrelated expansion before a concrete request exists.

3. Constraints
- Technical constraints: keep edits scoped to the selected project and preserve existing shared-context state across relaunches.
- Product constraints: direct user instructions override workflow defaults when they conflict.
- Time or complexity constraints: prefer the smallest safe change that unblocks work.

4. Success Criteria
- SC1: The shared context starts with usable artifact fields so a fresh session can begin immediately.
- SC2: The first role handling a concrete task can refine this bootstrap artifact instead of returning `NOT READY`.
- SC3: Relaunching the launcher preserves any existing shared-context task state.

5. Invariants
- INV1: Preserve user-provided instructions and existing task state once they exist.
- INV2: Keep work scoped to the selected project unless the user explicitly redirects it.

6. Implementation Plan
- Refine the artifact just enough for the active role to proceed when the first concrete request arrives.

7. Failure Modes
- FM1: The launcher resets the shared artifact back to placeholders and destroys active task context.
- FM2: Roles refuse to work because the artifact never moves past an empty bootstrap state.

8. Risks / Open Questions
- R1: A bootstrap artifact can still be too generic if the first concrete user request is not recorded promptly.
- R2: Some projects may still need repo-local instructions seeded before role prompts are useful.
- Q1: The first role to act should refine the artifact further if the user gives a concrete task.
- Q2: User overrides take precedence if the workflow and the request conflict.

9. Test Mapping
- SC1 -> Inspect a newly created shared-context file for fully populated bootstrap sections.
- SC2 -> Verify role prompts do not stop only because the artifact is still in bootstrap form.
- SC3 -> Relaunch against an existing shared-context file and confirm it is not overwritten.

10. Reusable Knowledge
- User-provided knowledge: none captured yet
- Durable project facts: none captured yet
- Retrieval path: search `docs/knowledge.md`, this shared context file, and nearby repo docs with `rg` before broader search.
- Ingestible sources in v1: direct user instructions, pasted facts, stable repo docs, and short summaries of resolved task decisions.

11. Weak Spots / Coaching
- Weak spots: none recorded yet
- Coaching guidance: none recorded yet
- Learning loop: `CRITIC` should turn repeated or high-severity weak points into targeted coaching guidance that later roles can reuse.

12. Status
- State: waiting for first concrete task
- Outstanding issues: none yet
- Next action: refine this artifact when the user gives the first specific request
EOF
}

common_tail_template() {
  cat <<'EOF'
Use this end-of-turn format every time:
1. Summary: one or two sentences describing what changed.
2. Artifact updates: list only the artifact sections you created, changed, verified, or diagnosed this turn, using the artifact IDs directly.
3. Changed files: list only the files you actually touched.
4. Why: one short sentence explaining why these changes or artifact updates were made.
EOF
}

compact_shared_context_boilerplate() {
  local session_file=$1
  local content updated workflow tail

  [[ -f "$session_file" ]] || return

  content="$(cat "$session_file")"
  updated="$content"
  tail="$(common_tail_template)"

  for workflow in "$(workflow_contract)" "$(legacy_workflow_contract_v1)"; do
    updated="${updated/$'\n\n'"$workflow"$'\n\n'/$'\n\n'}"
    updated="${updated/"$workflow"$'\n\n'/}"
  done

  if [[ "$updated" == *"## Workflow Contract"* && "$updated" == *"## TASK ARTIFACT"* ]]; then
    updated="$(
      printf '%s\n' "$updated" | awk '
        BEGIN { drop = 0 }
        $0 == "## Workflow Contract" { drop = 1; next }
        drop && $0 == "## TASK ARTIFACT" { drop = 0; print; next }
        !drop { print }
      '
    )"
  fi

  updated="${updated/$'\n\n'"$tail"$'\n'/$'\n'}"
  updated="${updated/$'\n\n'"$tail"/}"

  if [[ "$updated" != "$content" ]]; then
    printf '%s' "$updated" > "$session_file"
  fi
}

ensure_shared_context_knowledge_sections() {
  local session_file=$1
  local content updated

  [[ -f "$session_file" ]] || return

  content="$(cat "$session_file")"
  updated="$content"

  if [[ "$updated" != *"## TASK ARTIFACT"* ]]; then
    return
  fi

  if [[ "$updated" == *"Reusable Knowledge"* && "$updated" == *"Weak Spots / Coaching"* ]]; then
    return
  fi

  updated="$(
    printf '%s\n' "$updated" | awk '
      BEGIN {
        in_artifact = 0
        inserted = 0
      }

      function print_block() {
        if (inserted) {
          return
        }

        print ""
        print "### Reusable Knowledge"
        print "- User-provided knowledge: none captured yet"
        print "- Durable project facts: none captured yet"
        print "- Retrieval path: search `docs/knowledge.md`, this shared context file, and nearby repo docs with `rg` before broader search."
        print "- Ingestible sources in v1: direct user instructions, pasted facts, stable repo docs, and short summaries of resolved task decisions."
        print ""
        print "### Weak Spots / Coaching"
        print "- Weak spots: none recorded yet"
        print "- Coaching guidance: none recorded yet"
        print "- Learning loop: `CRITIC` should turn repeated or high-severity weak points into targeted coaching guidance that later roles can reuse."
        print ""
        inserted = 1
      }

      /^## TASK ARTIFACT$/ {
        in_artifact = 1
        print
        next
      }

      in_artifact && /^## / {
        print_block()
        in_artifact = 0
        print
        next
      }

      in_artifact && /^[0-9]+\. Status$/ {
        print_block()
        print
        next
      }

      {
        print
      }

      END {
        if (in_artifact && !inserted) {
          print_block()
        }
      }
    '
  )"

  if [[ "$updated" != "$content" ]]; then
    printf '%s' "$updated" > "$session_file"
  fi
}

make_shared_context() {
  local project_name=$1
  local project_dir=$2
  local target_file=$3
  local session_dir="$HOME/.codex"
  local session_file="$session_dir/$(slugify "$project_name")-shared-context.md"
  mkdir -p "$session_dir"

  if [[ -e "$session_file" ]]; then
    compact_shared_context_boilerplate "$session_file"
    ensure_shared_context_knowledge_sections "$session_file"
    SHARED_CONTEXT_FILE="$session_file"
    return
  fi

  cat > "$session_file" <<EOF
# Codex shared session context

- Project name: $project_name
- Project directory: $project_dir
- Target file: $target_file
- Session source of truth: this file

$(task_artifact_template)
EOF

  SHARED_CONTEXT_FILE="$session_file"
}

role_prompt() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  local prompt_body

  prompt_body="$(role_prompt_body "$role")"

  cat <<EOF
$(base_wrapper_prompt "$role" "$project_name" "$project_dir" "$target_file" "$session_file")

$prompt_body
EOF
}

launch_ghostty_session() {
  local project_dir=$1
  shift
  local prompt1=$1
  local prompt2=$2
  local prompt3=$3
  local prompt4=$4
  local prompt_file1 prompt_file2 prompt_file3 prompt_file4
  local pane1_command pane2_command pane3_command pane4_command

  prompt_file1="$(mktemp -t codex-launchpad-prompt1.XXXXXX)"
  prompt_file2="$(mktemp -t codex-launchpad-prompt2.XXXXXX)"
  prompt_file3="$(mktemp -t codex-launchpad-prompt3.XXXXXX)"
  prompt_file4="$(mktemp -t codex-launchpad-prompt4.XXXXXX)"

  printf '%s' "$prompt1" > "$prompt_file1"
  printf '%s' "$prompt2" > "$prompt_file2"
  printf '%s' "$prompt3" > "$prompt_file3"
  printf '%s' "$prompt4" > "$prompt_file4"

  pane1_command="codex \"\$(cat $(shell_single_quote "$prompt_file1"))\""
  pane2_command="codex \"\$(cat $(shell_single_quote "$prompt_file3"))\""
  pane3_command="codex \"\$(cat $(shell_single_quote "$prompt_file2"))\""
  pane4_command="codex \"\$(cat $(shell_single_quote "$prompt_file4"))\""

  if ! osascript <<EOF
tell application "Ghostty"
  activate

  set launcherWindow to front window
  set cfg to new surface configuration
  set initial working directory of cfg to $(applescript_string "$project_dir")
  set environment variables of cfg to {"GHOSTTY_LAUNCHPAD_SESSION=1", "DISABLE_AUTO_UPDATE=true", "DISABLE_UPDATE_PROMPT=true"}
  set win to new window with configuration cfg
  set pane1 to terminal 1 of selected tab of win
  set pane2 to split pane1 direction right with configuration cfg
  set pane3 to split pane1 direction right with configuration cfg
  set pane4 to split pane2 direction right with configuration cfg

  delay ${SHELL_STARTUP_DELAY_SECONDS}

  input text $(applescript_string "$pane1_command") to pane1
  send key "enter" to pane1
  delay ${CODEX_PROMPT_STAGGER_SECONDS}

  input text $(applescript_string "$pane2_command") to pane2
  send key "enter" to pane2
  delay ${CODEX_PROMPT_STAGGER_SECONDS}

  input text $(applescript_string "$pane3_command") to pane3
  send key "enter" to pane3
  delay ${CODEX_PROMPT_STAGGER_SECONDS}

  input text $(applescript_string "$pane4_command") to pane4
  send key "enter" to pane4

  try
    close window launcherWindow
  end try
end tell
EOF
  then
    rm -f "$prompt_file1" "$prompt_file2" "$prompt_file3" "$prompt_file4"
    return 1
  fi

  rm -f "$prompt_file1" "$prompt_file2" "$prompt_file3" "$prompt_file4"
}

main() {
  local project_name project_dir session_file project_name_compact target_file requested_file
  local -a roles prompts
  local role

  prompt_project_name
  project_name="$PROJECT_NAME"
  project_name_compact="$(printf '%s' "$project_name" | tr -d '[:space:]')"

  if [[ -n "$project_name_compact" ]]; then
    project_dir="$(search_project_dir "$project_name")"
  else
    project_dir=""
  fi

  if [[ -z "$project_dir" ]]; then
    prompt_new_file_name
    requested_file="$NEW_FILE_NAME"
    if [[ -z "$project_name_compact" ]]; then
      project_name="$(derive_project_name_from_file "$requested_file")"
    fi
    create_new_project "$project_name" "$requested_file"
    project_dir="$CREATED_PROJECT_DIR"
    target_file="$CREATED_TARGET_FILE"
  else
    if [[ ! -f "$project_dir/AGENTS.md" ]]; then
      seed_project_workflow_files "$project_name" "$project_dir"
      target_file="AGENTS.md"
    else
      seed_project_workflow_files "$project_name" "$project_dir"
      target_file="$(choose_target_file "$project_dir")"
      if [[ -z "$target_file" ]]; then
        target_file="README.md"
        if [[ ! -e "$project_dir/$target_file" ]]; then
          : > "$project_dir/$target_file"
        fi
      fi
    fi
  fi

  make_shared_context "$project_name" "$project_dir" "$target_file"
  session_file="$SHARED_CONTEXT_FILE"

  roles=(BUILDER BACKEND DEBUGGER CRITIC)
  for role in "${roles[@]}"; do
    prompts+=("$(role_prompt "$role" "$project_name" "$project_dir" "$target_file" "$session_file")")
  done

  launch_ghostty_session "$project_dir" "${prompts[0]}" "${prompts[1]}" "${prompts[2]}" "${prompts[3]}"

  printf 'Prepared Ghostty Codex session for %s\nProject directory: %s\nTarget file: %s\nShared context: %s\n' "$project_name" "$project_dir" "$target_file" "$session_file"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
