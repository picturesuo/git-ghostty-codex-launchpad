#!/usr/bin/env bash

shared_context_session_id() {
  local session_file=$1
  local basename

  if [[ "$session_file" == *"{"* ]]; then
    printf '%s' "{SESSION_ID}"
    return
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

base_wrapper_prompt() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  local session_id queue_file knowledge_file git_branch git_state queue_now

  session_id="$(shared_context_session_id "$session_file")"
  queue_file="$project_dir/docs/queue.md"
  knowledge_file="$project_dir/docs/knowledge.md"
  git_branch="$(project_git_branch "$project_dir")"
  git_state="$(project_git_status "$project_dir")"
  queue_now="$(queue_now_item "$queue_file")"

  cat <<EOF
Shared project context:
- Project name: $project_name
- Project directory: $project_dir
- Target file: $target_file
- Session ID: $session_id
- Git branch: $git_branch
- Git status: $git_state
- Queue now: $queue_now
- Queue file: $queue_file
- Knowledge file: $knowledge_file
- Shared context file: $session_file

Read \`$project_dir/AGENTS.md\` first if it exists.
Read the shared context file second and use it as the task artifact for the current task.
Update the shared context file directly as part of your work, but only in the sections owned by your role.
Work inside \`$project_dir\`.
Use the queue and knowledge files as the first local context after the shared artifact.
ROLE: $role
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
- Stop after artifact setup if implementation belongs to another role.

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
- Work directly against current `SC` and `INV` IDs.
- Keep changes localized and reversible.
- Search `docs/knowledge.md`, the shared context file, and nearby repo docs before broader search.
- Check `docs/queue.md` for the current `Now` item before broadening scope.
- Refine only the minimum artifact sections needed to implement.

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
- Use the queue item and shared context snapshot to keep verification tightly scoped.

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
