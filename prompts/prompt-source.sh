#!/usr/bin/env bash

shared_context_session_id() {
  local session_file=$1
  local basename
  local session_id

  if [[ "$session_file" == *"{"* ]]; then
    printf '%s' "{SESSION_ID}"
    return
  fi

  if [[ -f "$session_file" ]]; then
    session_id="$(sed -n 's/^- Session ID: //p' "$session_file" | head -n 1)"
    if [[ -n "$session_id" ]]; then
      printf '%s' "$session_id"
      return
    fi
  fi

  basename="$(basename "$session_file")"
  basename="${basename%-shared-context.md}"
  printf '%s' "$basename"
}

project_git_branch() {
  local project_dir=$1 branch

  if ! git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '%s' "n/a"
    return
  fi

  branch="$(git -C "$project_dir" branch --show-current 2>/dev/null || true)"
  if [[ -n "$branch" ]]; then
    printf '%s' "$branch"
  else
    printf '%s' "detached"
  fi
}

project_git_status() {
  local project_dir=$1 status

  if ! git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '%s' "n/a"
    return
  fi

  status="$(git -C "$project_dir" status --porcelain --untracked-files=no 2>/dev/null || true)"
  if [[ -n "$status" ]]; then
    printf '%s' "dirty"
  else
    printf '%s' "clean"
  fi
}

queue_now_item() {
  local queue_file=$1
  local item

  [[ -f "$queue_file" ]] || {
    printf '%s' "n/a"
    return
  }

  item="$(
    awk '
      /^## Now$/ { in_now = 1; next }
      /^## / && in_now { exit }
      in_now && /^- \[[ xX]\] / {
        sub(/^- \[[ xX]\] /, "")
        print
        exit
      }
    ' "$queue_file" 2>/dev/null || true
  )"

  if [[ -n "$item" ]]; then
    printf '%s' "$item"
  else
    printf '%s' "n/a"
  fi
}

sanitize_title_text() {
  local value=$1 max_len=${2:-0}

  value="$(printf '%s' "$value" | tr '\r\n\t' '   ' | sed 's/[|]/ /g; s/[[:space:]]\+/ /g; s/^ //; s/ $//')"

  if [[ "$max_len" -gt 0 && "${#value}" -gt "$max_len" ]]; then
    value="${value:0:max_len}"
    value="${value%"${value##*[![:space:]]}"}"
  fi

  printf '%s' "$value"
}

shared_context_active_artifact_id() {
  local session_file=$1
  local target_file=$2
  local artifact_id

  if [[ -f "$session_file" ]]; then
    artifact_id="$(sed -n 's/^- Active task artifact ID: //p' "$session_file" | head -n 1)"
    if [[ -n "$artifact_id" ]]; then
      printf '%s' "$artifact_id"
      return
    fi
  fi

  artifact_id="$(basename "$target_file")"
  if [[ -n "$artifact_id" ]]; then
    printf '%s' "$artifact_id"
  else
    printf '%s' "n/a"
  fi
}

context_budget_indicator() {
  local session_file=$1
  local line_count

  [[ -f "$session_file" ]] || {
    printf '%s' "ctx:n/a"
    return
  }

  line_count="$(wc -l < "$session_file" 2>/dev/null | tr -d '[:space:]')"
  if [[ -z "$line_count" ]]; then
    printf '%s' "ctx:n/a"
    return
  fi

  if (( line_count >= 260 )); then
    printf 'ctx:%sL!' "$line_count"
    return
  fi

  printf 'ctx:%sL' "$line_count"
}

session_phase_for_role() {
  local role=$1

  case "$role" in
    BUILDER)
      printf '%s' "plan"
      ;;
    BACKEND|DEBUGGER)
      printf '%s' "build"
      ;;
    CRITIC)
      printf '%s' "verify"
      ;;
    *)
      printf '%s' "build"
      ;;
  esac
}

launcher_context_bar_core() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  local branch dirty_state task_label artifact_id phase session_id budget

  project_name="$(sanitize_title_text "$project_name" 20)"
  branch="$(sanitize_title_text "$(project_git_branch "$project_dir")" 16)"
  dirty_state="$(project_git_status "$project_dir")"
  task_label="$(sanitize_title_text "$(queue_now_item "$project_dir/docs/queue.md")" 24)"
  artifact_id="$(sanitize_title_text "$(shared_context_active_artifact_id "$session_file" "$target_file")" 20)"
  phase="$(session_phase_for_role "$role")"
  session_id="$(sanitize_title_text "$(shared_context_session_id "$session_file")" 8)"
  budget="$(sanitize_title_text "$(context_budget_indicator "$session_file")" 10)"

  if [[ -z "$branch" || "$branch" == "n/a" ]]; then
    branch="no-git"
  fi
  if [[ -z "$dirty_state" || "$dirty_state" == "n/a" ]]; then
    dirty_state="n/a"
  fi
  if [[ -z "$task_label" || "$task_label" == "n/a" ]]; then
    task_label="$(sanitize_title_text "$artifact_id" 24)"
  fi
  if [[ -z "$artifact_id" || "$artifact_id" == "n/a" ]]; then
    artifact_id="$(sanitize_title_text "$(basename "$target_file")" 20)"
  fi
  if [[ -z "$phase" ]]; then
    phase="build"
  fi
  if [[ -z "$session_id" ]]; then
    session_id="session"
  fi
  if [[ -z "$budget" ]]; then
    budget="ctx:n/a"
  fi

  printf '%s | %s | %s | %s | %s | task:%s | art:%s | %s | %s' \
    "$project_name" \
    "$branch" \
    "$dirty_state" \
    "$role" \
    "$phase" \
    "$task_label" \
    "$artifact_id" \
    "$budget" \
    "$session_id"
}

launcher_context_bar() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  launcher_context_bar_core "$role" "$project_name" "$project_dir" "$target_file" "$session_file"
}

base_wrapper_prompt() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  local context_bar session_id queue_file knowledge_file active_artifact

  context_bar="$(launcher_context_bar "$role" "$project_name" "$project_dir" "$target_file" "$session_file")"
  session_id="$(shared_context_session_id "$session_file")"
  queue_file="$project_dir/docs/queue.md"
  knowledge_file="$project_dir/docs/knowledge.md"
  active_artifact="$(shared_context_active_artifact_id "$session_file" "$target_file")"

  cat <<EOF
Shared project context:
- Project name: $project_name
- Project directory: $project_dir
- Target file: $target_file
- Active task artifact ID: $active_artifact
- Context bar: $context_bar
- Session ID: $session_id
- Queue file: $queue_file
- Knowledge file: $knowledge_file
- Shared context file: $session_file

Read \`$project_dir/AGENTS.md\` first if it exists.
Read the shared context file second and use it as the task artifact for the current task.
Update the shared context file directly as part of your work, but only in the sections owned by your role.
Work inside \`$project_dir\`.
Use the queue and knowledge files as the first local context after the shared artifact.
If the work moves from one file to another, commit and push the finished file before starting the next one.
ROLE: $role
EOF
}

role_selection_summary() {
  cat <<'EOF'
# Role Selection

- `BUILDER`: use when the task artifact is missing, vague, or needs tighter success criteria before implementation.
- `BACKEND`: use when the artifact is concrete enough to implement the next scoped change.
- `CRITIC`: use when implementation exists and needs pass/fail judgment, missing risks, or stronger criteria.
- `DEBUGGER`: use when a criterion failed, an invariant broke, or a critic finding needs a minimal confirmed fix.
EOF
}

push_helper_instructions() {
  cat <<'EOF'
- Use `scripts/codex-commit.sh` with explicit path arguments.
- Use `scripts/codex-commit.sh --each-path` when changing more than one file so each file gets its own short commit message and push.
- Keep push messages short, human-readable, and descriptive.
- Do not use `--no-push` in the normal launcher workflow.
- If push cannot happen, treat that as a blocker and fix the remote/branch setup first.
- Do not push partial, failing, or unverified work.
EOF
}

role_prompt_body() {
  local role=$1

  case "$role" in
    BUILDER)
      cat <<'EOF'
Purpose:
- Initialize or tighten the task artifact before implementation.

Owns:
- Goal
- Scope
- Constraints
- Success Criteria
- Invariants
- Failure Modes
- Risks / Open Questions
- Test Mapping
- Status

Must:
- Keep scope tight and executable.
- Use exact artifact IDs such as `SC1`, `INV1`, `FM1`, `R1`, `Q1`.
- If the work moves from one file to another, commit and push the finished file before starting the next one.
- Stop after artifact setup if implementation belongs to another role.
- Auto-commit and auto-push coherent repo-visible changes instead of waiting for approval.
- Do not ask the user for permission before pushing a coherent repo-visible change set.

Must not:
- Invent unrelated product requirements.
- Start coding before usable success criteria exist.
- Claim verification not performed.
EOF
      ;;
    BACKEND)
      cat <<'EOF'
Purpose:
- Implement the smallest artifact-scoped change.

Owns:
- Code and doc changes needed for implementation
- Implementation notes
- Criteria coverage notes
- Assumptions
- Status

Must:
- Classify the task as `tiny`, `medium`, or `broad` before editing.
- Tiny tasks go straight to implementation.
- Broad tasks must first produce a file list and rollback plan.
- Work directly against current `SC` and `INV` IDs.
- Keep changes localized and reversible.
- If the work moves from one file to another, finish and push the current file before moving on.
- Search `docs/knowledge.md`, the shared context file, and nearby repo docs before broader search.
- Check `docs/queue.md` for the current `Now` item before broadening scope.
- Finish coherent change sets with `scripts/codex-commit.sh --each-path` when moving across files so each file gets a short commit message and push.
- Keep push messages short and human-readable; default to push when the selected project has a safe existing remote.
- Do not ask the user for permission before pushing a coherent repo-visible change set.
- Auto-commit and auto-push verified changes instead of waiting for approval.
- Refine only the minimum artifact sections needed to implement.

Push helper:
EOF
      push_helper_instructions
      cat <<'EOF'

Notes:
- The helper auto-discovers the project root and the best matching GitHub remote when possible.
- If the helper refuses to publish, fix the issue first instead of bypassing it.
EOF
      cat <<'EOF'

Must not:
- Redefine scope without a blocker.
- Claim final verification.
- Publish partial or unverified work.
EOF
      ;;
    CRITIC)
      cat <<'EOF'
Purpose:
- Judge whether the implementation satisfies the artifact.

Owns:
- Verification results
- Invariant judgments
- Added risks or failure modes
- Debugger guidance
- Status updates if judgment changes

Must:
- Record explicit `PASS`, `FAIL`, or `NOT VERIFIED` per relevant criterion.
- Map every finding to an artifact ID.
- Focus on bugs, regressions, ambiguity, and validation gaps.
- If the work moves from one file to another, commit and push the verified file before moving to the next one.
- Use the queue item and shared context snapshot to keep verification tightly scoped.
- Auto-push coherent repo-visible changes instead of waiting for approval.
- Do not ask the user for permission before pushing a coherent repo-visible change set.

Must not:
- Invent broad new scope.
- Propose unrelated rewrites.
- Publish failing or unverified work.
EOF
      ;;
    DEBUGGER)
      cat <<'EOF'
Purpose:
- Fix failures found by `CRITIC` with the smallest confirmed change.

Owns:
- Reproduced failures
- Likely root cause
- Fix applied
- Criteria rechecked
- Remaining uncertainty
- Status

Must:
- Start from failing criteria, violated invariants, or critic findings.
- Reproduce before editing when practical.
- Map diagnosis and fix back to exact artifact IDs.
- Re-read the queue item and shared context snapshot before changing code.
- If the work moves from one file to another, fix and push one file at a time instead of batching them.
- Auto-push coherent repo-visible changes instead of waiting for approval.
- Do not ask the user for permission before pushing a coherent repo-visible change set.

Must not:
- Broaden scope beyond the failing path without a blocker.
- Rely on speculation when direct evidence is available.
- Treat a non-reproduced issue as confirmed.
EOF
      ;;
    *)
      echo "Unsupported role: $role" >&2
      return 1
      ;;
  esac
}
