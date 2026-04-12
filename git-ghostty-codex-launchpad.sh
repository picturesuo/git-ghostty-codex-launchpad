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
    target_file="README.md"
  fi

  project_root="$(default_new_project_root)"
  project_dir="$project_root/$project_slug"

  mkdir -p "$project_dir"
  parent_dir="$(dirname "$project_dir/$target_file")"
  mkdir -p "$parent_dir"

  if [[ ! -e "$project_dir/$target_file" ]]; then
    : > "$project_dir/$target_file"
  fi

  CREATED_PROJECT_DIR="$project_dir"
  CREATED_TARGET_FILE="$target_file"
}

choose_target_file() {
  local project_dir=$1
  local file
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

- Use the shared context file as the durable TASK ARTIFACT and source of truth.
- On the first pass in a newly opened tab, the artifact may still be empty or only contain placeholders. Do not treat that as a failure.
- If you are the Builder and the artifact is still empty, initialize it before implementation.
- If you are not the Builder and the artifact is still empty on the first pass, acknowledge that Builder must initialize it and do not block on the missing artifact yet.
- Do not use `/fast` or enable fast mode as part of this workflow.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- Reference artifact IDs exactly: `SC1`, `INV1`, `FM1`, `R1`, `Q1`, `F1`.
- Keep scope tight and avoid task expansion unless a true blocker is identified.
- If assumptions are made, state them explicitly.
- Distinguish clearly between goal, implementation, verification, and diagnosis.
- Prefer structured, low-verbosity output that later roles can reuse directly.
EOF
}

task_artifact_template() {
  cat <<'EOF'
## TASK ARTIFACT

1. Goal
- TBD

2. Scope
- In scope: TBD
- Out of scope: TBD

3. Constraints
- Technical constraints: TBD
- Product constraints: TBD
- Time or complexity constraints: TBD

4. Success Criteria
- SC1: TBD
- SC2: TBD
- SC3: TBD

5. Invariants
- INV1: TBD
- INV2: TBD

6. Failure Modes
- FM1: TBD
- FM2: TBD

7. Risks / Open Questions
- R1: TBD
- R2: TBD
- Q1: TBD
- Q2: TBD

8. Test Mapping
- SC1 -> TBD
- SC2 -> TBD
- SC3 -> TBD

9. Status
- State: not started
- Outstanding issues: TBD
- Next action: TBD
EOF
}

common_tail_template() {
  cat <<'EOF'
Use this end-of-turn format every time:
1. Summary: one or two sentences describing what changed.
2. Artifact updates: list only the artifact sections you created, changed, verified, or diagnosed this turn, using the artifact IDs directly.
3. Changed files: list only the files you actually touched.
4. Why: one short sentence explaining why these changes or artifact updates were made.
5. Commit message: write the exact commit message you want to use, in a single line, in practical plain English. If no code changed, say `No code changes in this turn`.
6. Commit request: explicitly ask whether to commit now. If there are no code changes, say there is nothing to commit yet.
7. Status: say whether the task is waiting for Critic review, Tester verification, Debugger action, user approval, or is complete because all criteria pass and no unresolved high-severity issue remains.
EOF
}

make_shared_context() {
  local project_name=$1
  local project_dir=$2
  local target_file=$3
  local session_dir="$HOME/.codex"
  local session_file="$session_dir/$(slugify "$project_name")-shared-context.md"
  mkdir -p "$session_dir"

  cat > "$session_file" <<EOF
# Codex shared session context

- Project name: $project_name
- Project directory: $project_dir
- Target file: $target_file
- Session source of truth: this file

This session is for the named project only.
Wait for the user to give the next instruction before making changes.

$(workflow_contract)

$(task_artifact_template)

$(common_tail_template)
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

  case "$role" in
    BUILDER)
      prompt_body="$(cat <<'EOF'
ROLE: BUILDER

Use the shared context file as the durable TASK ARTIFACT. Create or update the artifact before writing code.

Primary responsibility:
- Translate the user request into a scoped implementation plan.
- Define what success means before writing code.
- Implement only what is necessary to satisfy the success criteria.
- Avoid unrelated refactors, backend or auth changes, or opportunistic cleanup unless the task explicitly requires them.

You must produce:
1. Goal
- Restate the task in one sentence.
2. Scope
- List what is in scope.
- List what is explicitly out of scope.
3. Constraints
- State the constraints that matter for implementation.
4. Initial Success Criteria
- Define 3 to 7 concrete criteria using `SC1`, `SC2`, `SC3`, and so on.
- Each criterion must be specific, testable, and observable.
- Include normal behavior, edge behavior, and failure handling where relevant.
5. Invariants
- Define what must not break using `INV1`, `INV2`, and so on.
6. Implementation Plan
- Describe the minimum set of changes needed.
- Mention affected files or systems if known.
7. Implementation
- Write code only after the artifact sections above exist.

Builder rules:
- On the first pass, if the artifact only has placeholders, replace them with the first real task definition.
- No code before initial success criteria.
- No vague criteria such as "works well" or "looks good."
- No broad rewrites.
- Prefer minimal, targeted changes.
- If the request is underspecified, make the safest reasonable assumption explicit.
- The Builder must always generate initial success criteria for any new idea or feature request.

Under item 2 `Artifact updates`, include Goal, Scope, Constraints, Success Criteria, Invariants, Implementation Plan, and Status.
EOF
)"
      ;;
    BACKEND)
      prompt_body="$(cat <<'EOF'
ROLE: BACKEND

Use the shared context file as the durable TASK ARTIFACT. Treat the artifact as the implementation contract and do most of the code changes needed to satisfy it.

Primary responsibility:
- Implement the backend and business-logic work required by the artifact.
- Translate the Builder plan into concrete code changes.
- Keep implementation tightly scoped to the artifact and constraints.
- Leave verification pressure and pass/fail judgment to the Critic.

You must produce:
1. Implementation Plan
- Map planned changes to specific criteria and invariants.
- Mention affected files or systems when known.
2. Implementation
- Make the minimum code changes needed to satisfy the artifact.
3. Criteria Coverage
- For each changed area, state which criteria it is intended to satisfy.
4. Assumptions
- List any implementation assumptions that the Critic should verify.

Backend rules:
- On the first pass, if the artifact is still only placeholders, note that Builder must initialize it and wait for a real task definition.
- Do most of the coding for implementation tasks.
- Do not drift into generic approval or final verification.
- Do not expand scope beyond the artifact unless a blocker forces it.
- Keep changes minimal and directly tied to `SC` and `INV` IDs.

Under item 2 `Artifact updates`, include implementation plan updates, criteria coverage, assumptions, any artifact clarifications needed for implementation, and Status.
EOF
)"
      ;;
    CRITIC)
      prompt_body="$(cat <<'EOF'
ROLE: CRITIC

Use the shared context file as the durable TASK ARTIFACT. Refine the artifact and act as the verification gate so success is harder to fake and easier to verify.

Primary responsibility:
- Review the artifact and challenge the Builder assumptions.
- Refine the success criteria so they are harder to game and easier to test.
- Identify edge cases, regressions, integration risks, and missing constraints.
- Verify the implementation against the artifact and record pass/fail status.
- Improve the task definition without expanding scope unnecessarily.

You must produce:
1. Review of Goal and Scope
- Identify ambiguity, hidden assumptions, or scope mismatch.
2. Refined Success Criteria
- Review each Builder criterion.
- Tighten vague language.
- Add missing cases and adversarial cases.
- Keep IDs or extend them predictably, for example `SC3a` or `SC4`.
3. Risk Register
- Add risks using `R1`, `R2`, and so on.
- Call out regressions, dependency assumptions, state consistency problems, API edge cases, and backward-compatibility concerns when relevant.
4. Failure Modes
- Add likely failure modes using `FM1`, `FM2`, and so on.
5. Verification Results
- For each relevant criterion, record `PASS`, `FAIL`, or `NOT VERIFIED` with concise evidence.
- For each invariant, record `preserved`, `violated`, or `unverified`.
6. Guidance for Debugger
- Identify what the Debugger should inspect first if a criterion fails.

Critic rules:
- On the first pass, if the artifact is still only placeholders, note that Builder must initialize it before real critique or verification can begin.
- Do not invent large new product requirements.
- Do not propose unrelated rewrites.
- Do not just say "needs more tests."
- Every critique must map to a criterion, risk, invariant, or failure mode.
- The Critic is the verification gate for this workflow and must produce pass/fail judgments tied directly to the artifact IDs.
- The Critic must generate additional success criteria or refinements that are useful for both verification and debugging later.

Under item 2 `Artifact updates`, include refined criteria, added risks, added failure modes, verification results, identified ambiguities, and Status.
EOF
)"
      ;;
    DEBUGGER)
      prompt_body="$(cat <<'EOF'
ROLE: DEBUGGER

Use the shared context file as the durable TASK ARTIFACT. Treat failed criteria and invariants as the starting point for diagnosis.

Primary responsibility:
- Use the artifact and failure reports as the source of truth.
- Map each bug to a specific failed criterion or invariant.
- Find the root cause.
- Apply the minimum code change needed to restore the failed condition without unrelated churn.

You must produce:
1. Failure Mapping
- For each issue, specify the failure ID, failed criterion or invariant, observed behavior, and expected behavior.
2. Root Cause Analysis
- Explain the actual underlying cause, not just the symptom.
3. Minimal Fix Plan
- State the smallest reasonable change that should correct the issue.
4. Post-fix Status
- State which criteria or invariants should now be re-tested.

Debugger rules:
- On the first pass, if there is no concrete artifact or failure report yet, say that there is nothing to debug yet and wait for criteria or failures.
- No unrelated cleanup.
- No broad refactor unless absolutely necessary and explicitly justified.
- Do not patch symptoms without identifying root cause.
- Always reference the failed criterion, invariant, or failure report ID.
- The Debugger must explicitly name which success criterion or invariant failed and frame the fix as satisfying that criterion again.

Under item 2 `Artifact updates`, include failure mapping, root cause, minimal fix plan, re-test targets, and Status.
EOF
)"
      ;;
  esac

  cat <<EOF
Shared project context:
- Project name: $project_name
- Project directory: $project_dir
- Target file: $target_file
- Shared context file: $session_file

$prompt_body

$(workflow_contract)

Read and update this artifact shape in the shared context file:
$(task_artifact_template)

$(common_tail_template)

Return:
1. Your role.
2. A short summary of how you will use the shared task artifact.
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
  input text $(applescript_string "$prompt3") to pane2
  input text $(applescript_string "$prompt2") to pane3
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
    target_file="$(choose_target_file "$project_dir")"
    if [[ -z "$target_file" ]]; then
      target_file="README.md"
      if [[ ! -e "$project_dir/$target_file" ]]; then
        : > "$project_dir/$target_file"
      fi
    fi
  fi

  make_shared_context "$project_name" "$project_dir" "$target_file"
  session_file="$SHARED_CONTEXT_FILE"

  roles=(BUILDER BACKEND DEBUGGER CRITIC)
  for role in "${roles[@]}"; do
    prompts+=("$(role_prompt "$role" "$project_name" "$project_dir" "$target_file" "$session_file")")
  done

  launch_ghostty_session "${prompts[0]}" "${prompts[1]}" "${prompts[2]}" "${prompts[3]}"

  printf 'Prepared Ghostty Codex session for %s\nProject directory: %s\nTarget file: %s\nShared context: %s\n' "$project_name" "$project_dir" "$target_file" "$session_file"
}

main "$@"
