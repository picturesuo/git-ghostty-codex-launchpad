#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prompts/prompt-source.sh"

SHELL_STARTUP_DELAY_SECONDS=1.5
CODEX_PROMPT_STAGGER_SECONDS=2
LAUNCHPAD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_COMMIT_HELPER="$LAUNCHPAD_ROOT/scripts/codex-commit.sh"
LAUNCHPAD_LAST_SESSION_FILE="$HOME/.codex/ghostty-codex-launchpad-last-session.md"

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

display_name_from_slug() {
  local value=$1
  value="${value//-/ }"
  value="${value//_/ }"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

shared_prefix_length() {
  local left=$1
  local right=$2
  local i max_len

  max_len=${#left}
  if (( ${#right} < max_len )); then
    max_len=${#right}
  fi

  for ((i = 0; i < max_len; i++)); do
    if [[ "${left:i:1}" != "${right:i:1}" ]]; then
      printf '%s' "$i"
      return
    fi
  done

  printf '%s' "$max_len"
}

token_match_strength() {
  local input_token=$1
  local candidate_token=$2
  local prefix_len

  if [[ "$input_token" == "$candidate_token" ]]; then
    printf '3'
    return
  fi

  if (( ${#input_token} >= 5 || ${#candidate_token} >= 5 )); then
    if [[ "$candidate_token" == "$input_token"* || "$input_token" == "$candidate_token"* ]]; then
      printf '2'
      return
    fi

    prefix_len="$(shared_prefix_length "$input_token" "$candidate_token")"
    if (( prefix_len >= 5 )); then
      printf '1'
      return
    fi
  fi

  printf '0'
}

name_similarity_metrics() {
  local input_name=$1
  local candidate_name=$2
  local input_slug candidate_slug token candidate_token strength best_strength matched_input_tokens input_token_count prefix_len
  local -a input_tokens candidate_tokens

  input_slug="$(slugify "$input_name")"
  candidate_slug="$(slugify "$candidate_name")"

  if [[ -z "$input_slug" || -z "$candidate_slug" ]]; then
    printf '0\t0\t0\n'
    return
  fi

  IFS='-' read -r -a input_tokens <<< "$input_slug"
  IFS='-' read -r -a candidate_tokens <<< "$candidate_slug"

  matched_input_tokens=0
  input_token_count=0
  best_strength=0

  for token in "${input_tokens[@]}"; do
    if (( ${#token} < 3 )); then
      continue
    fi

    input_token_count=$((input_token_count + 1))
    strength=0

    for candidate_token in "${candidate_tokens[@]}"; do
      local candidate_strength
      candidate_strength="$(token_match_strength "$token" "$candidate_token")"
      if (( candidate_strength > strength )); then
        strength=$candidate_strength
      fi
    done

    if (( strength > 0 )); then
      matched_input_tokens=$((matched_input_tokens + 1))
      best_strength=$((best_strength + strength))
    fi
  done

  if [[ "$candidate_slug" == "$input_slug" ]]; then
    best_strength=$((best_strength + 6))
  elif [[ "$candidate_slug" == "$input_slug"* || "$input_slug" == "$candidate_slug"* ]]; then
    best_strength=$((best_strength + 4))
  else
    prefix_len="$(shared_prefix_length "$input_slug" "$candidate_slug")"
    if (( prefix_len >= 5 )); then
      best_strength=$((best_strength + prefix_len))
    fi
  fi

  printf '%s\t%s\t%s\n' "$best_strength" "$matched_input_tokens" "$input_token_count"
}

shared_context_header_value() {
  local session_file=$1
  local field_name=$2

  [[ -f "$session_file" ]] || return 1
  sed -n "s/^- ${field_name}: //p" "$session_file" | head -n 1
}

launch_state_header_value() {
  local state_file=$1
  local field_name=$2

  [[ -f "$state_file" ]] || return 1
  sed -n "s/^- ${field_name}: //p" "$state_file" | head -n 1
}

generate_session_id() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-8
    return
  fi

  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 4
    return
  fi

  date +%s | shasum -a 256 | cut -c1-8
}

ensure_shared_context_session_id() {
  local session_file=$1 session_id tmp_file
  local target_file artifact_id

  session_id="$(shared_context_header_value "$session_file" "Session ID" || true)"
  target_file="$(shared_context_header_value "$session_file" "Target file" || true)"
  if [[ -n "$target_file" ]]; then
    artifact_id="$(basename "$target_file")"
  else
    artifact_id="n/a"
  fi

  if [[ -n "$session_id" ]]; then
    SHARED_CONTEXT_SESSION_ID="$session_id"
    return 0
  fi

  session_id="$(generate_session_id)"
  tmp_file="$(mktemp)"

  awk -v session_id="$session_id" -v artifact_id="$artifact_id" '
    BEGIN { inserted = 0 }
    /^- Active task artifact ID: / { next }
    /^- Session ID: / { next }
    {
      print
      if (!inserted && /^- Target file: /) {
        print "- Active task artifact ID: " artifact_id
        print "- Session ID: " session_id
        inserted = 1
      }
    }
    END {
      if (!inserted) {
        print "- Active task artifact ID: " artifact_id
        print "- Session ID: " session_id
      }
    }
  ' "$session_file" > "$tmp_file" && mv "$tmp_file" "$session_file"

  SHARED_CONTEXT_SESSION_ID="$session_id"
}

ensure_shared_context_active_artifact_id() {
  local session_file=$1 artifact_id target_file tmp_file

  target_file="$(shared_context_header_value "$session_file" "Target file" || true)"
  if [[ -n "$target_file" ]]; then
    artifact_id="$(basename "$target_file")"
  else
    artifact_id="n/a"
  fi

  tmp_file="$(mktemp)"

  awk -v artifact_id="$artifact_id" '
    BEGIN { inserted = 0 }
    /^- Active task artifact ID: / { next }
    {
      print
      if (!inserted && /^- Target file: /) {
        print "- Active task artifact ID: " artifact_id
        inserted = 1
      }
    }
    END {
      if (!inserted) {
        print "- Active task artifact ID: " artifact_id
      }
    }
  ' "$session_file" > "$tmp_file" && mv "$tmp_file" "$session_file"
}

store_last_launch_state() {
  local project_name=$1
  local project_dir=$2
  local target_file=$3
  local session_file=$4
  local git_remote_path=$5
  local github_repo_slug=$6
  local watch_command=$7
  local state_dir snapshot
  local summary_role=BUILDER

  state_dir="$(dirname "$LAUNCHPAD_LAST_SESSION_FILE")"
  mkdir -p "$state_dir"
  snapshot="$(launch_state_snapshot_fields "$summary_role" "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug" "$watch_command")"

  IFS=$'\t' read -r \
    saved_at \
    snapshot_role \
    snapshot_project_name \
    snapshot_project_dir \
    snapshot_target_file \
    artifact_id \
    session_id \
    phase \
    context_budget \
    context_bar \
    snapshot_session_file \
    snapshot_git_remote_path \
    snapshot_github_repo_slug \
    queue_file \
    knowledge_file \
    queue_now \
    branch \
    git_status \
    snapshot_watch_command \
    <<< "$snapshot"

  cat > "$LAUNCHPAD_LAST_SESSION_FILE" <<EOF
# Ghostty Codex Launchpad Last Session

- Saved at: $saved_at
- Snapshot role: $snapshot_role
- Project name: $snapshot_project_name
- Project directory: $snapshot_project_dir
- Target file: $snapshot_target_file
- Active task artifact ID: $artifact_id
- Session ID: $session_id
- Session phase: $phase
- Context budget: $context_budget
- Context bar: $context_bar
- Shared context file: $snapshot_session_file
- Git remote path: $snapshot_git_remote_path
- GitHub repo: $snapshot_github_repo_slug
- Queue file: $queue_file
- Knowledge file: $knowledge_file
- Queue now: $queue_now
- Git branch: $branch
- Git status: $git_status
- Watch command: $snapshot_watch_command
EOF
}

print_last_launch_state() {
  if [[ ! -f "$LAUNCHPAD_LAST_SESSION_FILE" ]]; then
    echo "No saved launch state has been recorded yet."
    return 1
  fi
  cat "$LAUNCHPAD_LAST_SESSION_FILE"
}

build_default_watch_command() {
  local project_dir=$1

  cat <<EOF
while true; do
  clear
  echo "Project: $project_dir"
  echo "Git branch: \$(git -C $(shell_single_quote "$project_dir") branch --show-current 2>/dev/null || echo detached)"
  echo "Git status:"
  git -C $(shell_single_quote "$project_dir") status --short --branch --untracked-files=no 2>/dev/null || true
  echo
  echo "Queue now:"
  awk '
    /^## Now$/ { in_now = 1; next }
    /^## / && in_now { exit }
    in_now && /^- \[[ xX]\] / { sub(/^- \[[ xX]\] /, ""); print; exit }
  ' $(shell_single_quote "$project_dir/docs/queue.md") 2>/dev/null || echo "n/a"
  sleep 2
done
EOF
}

launch_state_snapshot_fields() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  local git_remote_path=$6
  local github_repo_slug=$7
  local watch_command=$8
  local saved_at summary_role artifact_id session_id phase context_budget context_bar queue_file knowledge_file queue_now branch git_status

  summary_role="$role"
  saved_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  artifact_id="$(shared_context_active_artifact_id "$session_file" "$target_file")"
  session_id="$(shared_context_session_id "$session_file")"
  phase="$(session_phase_for_role "$summary_role")"
  context_budget="$(context_budget_indicator "$session_file")"
  context_bar="$(launcher_context_bar_core "$summary_role" "$project_name" "$project_dir" "$target_file" "$session_file")"
  queue_file="$project_dir/docs/queue.md"
  knowledge_file="$project_dir/docs/knowledge.md"
  queue_now="$(queue_now_item "$queue_file")"
  branch="$(project_git_branch "$project_dir")"
  git_status="$(project_git_status "$project_dir")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$saved_at" \
    "$summary_role" \
    "$project_name" \
    "$project_dir" \
    "$target_file" \
    "$artifact_id" \
    "$session_id" \
    "$phase" \
    "$context_budget" \
    "$context_bar" \
    "$session_file" \
    "$git_remote_path" \
    "$github_repo_slug" \
    "$queue_file" \
    "$knowledge_file" \
    "$queue_now" \
    "$branch" \
    "$git_status" \
    "$watch_command"
}

build_session_title() {
  local project_name=$1 project_dir=$2 target_file=$3 session_file=$4 role=$5
  local snapshot context_bar

  snapshot="$(launch_state_snapshot_fields "$role" "$project_name" "$project_dir" "$target_file" "$session_file" "{GIT_REMOTE_PATH}" "{GITHUB_REPO_SLUG}" "{WATCH_COMMAND}")"

  IFS=$'\t' read -r \
    _saved_at \
    _snapshot_role \
    _snapshot_project_name \
    _snapshot_project_dir \
    _snapshot_target_file \
    _artifact_id \
    _session_id \
    _phase \
    _budget \
    context_bar \
    _snapshot_session_file \
    _snapshot_git_remote_path \
    _snapshot_github_repo_slug \
    _queue_file \
    _knowledge_file \
    _queue_now \
    _branch \
    _git_status \
    _watch_command \
    <<< "$snapshot"

  printf '%s' "$context_bar"
}

build_watch_title() {
  local project_name=$1 project_dir=$2 session_file=$3
  local branch session_id

  project_name="$(sanitize_title_text "$project_name" 24)"
  branch="$(sanitize_title_text "$(project_git_branch "$project_dir")" 24)"
  session_id="$(sanitize_title_text "$(shared_context_session_id "$session_file")" 8)"

  if [[ -z "$branch" || "$branch" == "n/a" ]]; then
    branch="no-git"
  fi
  if [[ -z "$session_id" ]]; then
    session_id="session"
  fi

  printf '%s | %s | watch | %s' "$project_name" "$branch" "$session_id"
}

pane_command_with_title() {
  local title=$1 prompt_text=$2

  printf "printf '\\033]0;%%s\\a' %s; codex %s" "$(shell_single_quote "$title")" "$(shell_single_quote "$prompt_text")"
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

project_git_remote_path() {
  local project_dir=$1 upstream remote
  local -a remotes=()

  if [[ ! -d "$project_dir" || ! -d "$project_dir/.git" ]]; then
    return 1
  fi

  upstream="$(git -C "$project_dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  if [[ -n "$upstream" ]]; then
    remote="${upstream%%/*}"
    if [[ -n "$remote" ]] && git -C "$project_dir" remote get-url "$remote" >/dev/null 2>&1; then
      git -C "$project_dir" remote get-url "$remote"
      return 0
    fi
  fi

  if git -C "$project_dir" remote get-url origin >/dev/null 2>&1; then
    git -C "$project_dir" remote get-url origin
    return 0
  fi

  while IFS= read -r remote; do
    [ -n "$remote" ] && remotes+=("$remote")
  done < <(git -C "$project_dir" remote)

  if [[ "${#remotes[@]}" -eq 1 ]]; then
    git -C "$project_dir" remote get-url "${remotes[0]}" 2>/dev/null || return 1
    return 0
  fi

  return 1
}

github_repo_slug_from_remote_url() {
  local remote_url=$1 repo_slug

  repo_slug="$(printf '%s' "$remote_url" | sed -nE 's#^(git@github\.com:|ssh://git@github\.com/|https://github\.com/|http://github\.com/)?([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(\.git)?$#\2#p')"
  if [[ -n "$repo_slug" ]]; then
    repo_slug="${repo_slug%.git}"
    printf '%s' "$repo_slug"
    return 0
  fi

  repo_slug="$(printf '%s' "$remote_url" | sed -nE 's#.*github\.com[:/]+([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(\.git)?$#\1#p')"
  if [[ -n "$repo_slug" ]]; then
    repo_slug="${repo_slug%.git}"
    printf '%s' "$repo_slug"
    return 0
  fi

  return 1
}

launch_remote_defaults() {
  local project_dir=$1 last_project_dir remote_url

  GIT_REMOTE_PATH_DEFAULT=""
  GITHUB_REPO_SLUG_DEFAULT=""

  if [[ -f "$LAUNCHPAD_LAST_SESSION_FILE" ]]; then
    last_project_dir="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Project directory" || true)"
    if [[ "$last_project_dir" == "$project_dir" ]]; then
      GIT_REMOTE_PATH_DEFAULT="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Git remote path" || true)"
      GITHUB_REPO_SLUG_DEFAULT="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "GitHub repo" || true)"
    fi
  fi

  if [[ -z "$GIT_REMOTE_PATH_DEFAULT" ]]; then
    remote_url="$(project_git_remote_path "$project_dir" 2>/dev/null || true)"
    if [[ -n "$remote_url" ]]; then
      GIT_REMOTE_PATH_DEFAULT="$remote_url"
    fi
  fi

  if [[ -z "$GITHUB_REPO_SLUG_DEFAULT" && -n "$GIT_REMOTE_PATH_DEFAULT" ]]; then
    GITHUB_REPO_SLUG_DEFAULT="$(github_repo_slug_from_remote_url "$GIT_REMOTE_PATH_DEFAULT" 2>/dev/null || true)"
  fi
}

prompt_git_remote_path() {
  local dialog_result default_answer=${1-}

  default_answer="$(applescript_string "$default_answer")"

  if ! dialog_result="$(
    osascript <<EOF
try
  text returned of (display dialog "What git remote path should this project push to? Leave blank for a brand-new local project." default answer $default_answer buttons {"Cancel", "Continue"} default button "Continue")
on error number -128
  return ""
end try
EOF
  )"; then
    dialog_result=""
  fi

  GIT_REMOTE_PATH="$dialog_result"
}

prompt_github_repo_slug() {
  local dialog_result default_answer=${1-}

  default_answer="$(applescript_string "$default_answer")"

  if ! dialog_result="$(
    osascript <<EOF
try
  text returned of (display dialog "What GitHub repo should this project commit to? Leave blank for a brand-new local project." default answer $default_answer buttons {"Cancel", "Continue"} default button "Continue")
on error number -128
  return ""
end try
EOF
  )"; then
    dialog_result=""
  fi

  GITHUB_REPO_SLUG="$dialog_result"
}

confirm_project_match() {
  local requested_project_name=$1
  local candidate_project_dir=$2
  local dialog_result requested_text candidate_text

  requested_text="$(applescript_string "Project name: $requested_project_name")"
  candidate_text="$(applescript_string "Matched project: $candidate_project_dir")"

  if ! dialog_result="$(
    osascript <<EOF
try
  button returned of (display dialog ${requested_text} & "\n\n" & ${candidate_text} & "\n\nUse this project?" buttons {"Pick Again", "Use This Project"} default button "Use This Project" cancel button "Pick Again")
on error number -128
  return "Pick Again"
end try
EOF
  )"; then
    dialog_result="Pick Again"
  fi

  [[ "$dialog_result" == "Use This Project" ]]
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

search_root_for_project_similarity() {
  local search_root=$1
  local project_name=$2
  local max_depth=$3
  local candidate best_candidate best_score best_matches best_tokens ambiguous
  local candidate_name score matches token_count

  [[ -d "$search_root" ]] || return 1

  best_candidate=""
  best_score=0
  best_matches=0
  best_tokens=0
  ambiguous=0

  while IFS= read -r -d '' candidate; do
    candidate_name="$(basename "$candidate")"
    IFS=$'\t' read -r score matches token_count <<< "$(name_similarity_metrics "$project_name" "$candidate_name")"

    if (( token_count == 0 || matches < 2 )); then
      continue
    fi

    if (( matches * 2 < token_count + 1 )); then
      continue
    fi

    if (( score > best_score || (score == best_score && matches > best_matches) )); then
      best_candidate="$candidate"
      best_score=$score
      best_matches=$matches
      best_tokens=$token_count
      ambiguous=0
      continue
    fi

    if (( score == best_score && matches == best_matches && score > 0 )); then
      ambiguous=1
    fi
  done < <(
    find "$search_root" -maxdepth "$max_depth" -type d \
      \( -exec test -d {}/.git \; -o -exec test -f {}/package.json \; -o -exec test -f {}/README.md \; -o -exec test -f {}/README.mdx \; \) \
      -print0 2>/dev/null
  )

  if [[ -n "$best_candidate" && $ambiguous -eq 0 && $best_score -ge 4 && $best_matches -ge 2 ]]; then
    printf '%s' "$best_candidate"
    return 0
  fi

  return 1
}

search_shared_context_for_project() {
  local project_name=$1
  local session_dir="$HOME/.codex"
  local session_file candidate_dir candidate_name candidate_label
  local score_dir matches_dir tokens_dir score_name matches_name tokens_name
  local score_label matches_label tokens_label score matches tokens
  local best_dir best_score best_matches ambiguous

  [[ -d "$session_dir" ]] || return 1

  best_dir=""
  best_score=0
  best_matches=0
  ambiguous=0

  while IFS= read -r session_file; do
    [[ -f "$session_file" ]] || continue

    candidate_dir="$(shared_context_header_value "$session_file" "Project directory")"
    [[ -n "$candidate_dir" && -d "$candidate_dir" ]] || continue
    [[ "$candidate_dir" != "$HOME" ]] || continue
    if [[ ! -d "$candidate_dir/.git" && ! -f "$candidate_dir/package.json" && ! -f "$candidate_dir/README.md" && ! -f "$candidate_dir/README.mdx" ]]; then
      continue
    fi

    candidate_name="$(shared_context_header_value "$session_file" "Project name")"
    candidate_label="$(basename "$candidate_dir")"

    IFS=$'\t' read -r score_dir matches_dir tokens_dir <<< "$(name_similarity_metrics "$project_name" "$candidate_label")"
    IFS=$'\t' read -r score_name matches_name tokens_name <<< "$(name_similarity_metrics "$project_name" "$candidate_name")"

    score=$score_dir
    matches=$matches_dir
    tokens=$tokens_dir

    if (( score_name > score || (score_name == score && matches_name > matches) )); then
      score=$score_name
      matches=$matches_name
      tokens=$tokens_name
    fi

    if (( score_dir < 4 || matches_dir < 2 || tokens == 0 || matches < 2 || score < 4 )); then
      continue
    fi

    if (( matches * 2 < tokens + 1 )); then
      continue
    fi

    if (( score > best_score || (score == best_score && matches > best_matches) )); then
      best_dir="$candidate_dir"
      best_score=$score
      best_matches=$matches
      ambiguous=0
      continue
    fi

    if (( score == best_score && matches == best_matches && score > 0 )) && [[ "$candidate_dir" != "$best_dir" ]]; then
      ambiguous=1
    fi
  done < <(find "$session_dir" -maxdepth 1 -type f -name '*-shared-context.md' -print | sort)

  if [[ -n "$best_dir" && $ambiguous -eq 0 ]]; then
    printf '%s' "$best_dir"
    return 0
  fi

  return 1
}

search_shared_context_for_project_exact() {
  local project_name=$1
  local project_slug candidate_dir candidate_name candidate_label candidate_slug
  local session_dir="$HOME/.codex"
  local session_file

  [[ -d "$session_dir" ]] || return 1

  project_slug="$(slugify "$project_name")"

  while IFS= read -r session_file; do
    [[ -f "$session_file" ]] || continue

    candidate_dir="$(shared_context_header_value "$session_file" "Project directory")"
    [[ -n "$candidate_dir" && -d "$candidate_dir" ]] || continue
    [[ "$candidate_dir" != "$HOME" ]] || continue
    if [[ ! -d "$candidate_dir/.git" && ! -f "$candidate_dir/package.json" && ! -f "$candidate_dir/README.md" && ! -f "$candidate_dir/README.mdx" ]]; then
      continue
    fi

    candidate_name="$(shared_context_header_value "$session_file" "Project name")"
    candidate_label="$(basename "$candidate_dir")"
    candidate_slug="$(slugify "$candidate_label")"

    if [[ "$candidate_slug" == "$project_slug" || "$(slugify "$candidate_name")" == "$project_slug" ]]; then
      printf '%s' "$candidate_dir"
      return 0
    fi
  done < <(find "$session_dir" -maxdepth 1 -type f -name '*-shared-context.md' -print | sort)

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

  if candidate="$(search_shared_context_for_project "$project_name")"; then
    printf '%s' "$candidate"
    return
  fi

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

  for search_root in "${exact_roots[@]}" "${likely_roots[@]}"; do
    if candidate="$(search_root_for_project_similarity "$search_root" "$project_name" 5)"; then
      printf '%s' "$candidate"
      return
    fi
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

search_project_dir_exact() {
  local project_name=$1
  local search_root candidate pattern
  local lowered normalized
  local exact_roots likely_roots
  lowered="$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]')"
  normalized="$(slugify "$project_name")"
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

  if candidate="$(search_shared_context_for_project_exact "$project_name")"; then
    printf '%s' "$candidate"
    return
  fi

  for search_root in "${exact_roots[@]}"; do
    for pattern in "$(find_glob_escape "$project_name")" "$(find_glob_escape "$normalized")"; do
      if candidate="$(search_root_for_project "$search_root" "$pattern" 5)"; then
        printf '%s' "$candidate"
        return
      fi
    done
  done

  for search_root in "${likely_roots[@]}"; do
    for pattern in "$(find_glob_escape "$project_name")" "$(find_glob_escape "$lowered")" "$(find_glob_escape "$normalized")"; do
      if candidate="$(search_root_for_project "$search_root" "$pattern" 4)"; then
        printf '%s' "$candidate"
        return
      fi
    done
  done

  return 1
}

find_shared_context_by_project_dir() {
  local session_dir=$1
  local project_dir=$2
  local candidate best_candidate candidate_mtime best_mtime

  [[ -d "$session_dir" ]] || return 1

  best_candidate=""
  best_mtime=0

  while IFS= read -r candidate; do
    [[ -f "$candidate" ]] || continue
    if ! grep -Fqx -- "- Project directory: $project_dir" "$candidate"; then
      continue
    fi

    candidate_mtime="$(stat -f '%m' "$candidate" 2>/dev/null || printf '0')"
    if (( candidate_mtime >= best_mtime )); then
      best_mtime=$candidate_mtime
      best_candidate="$candidate"
    fi
  done < <(find "$session_dir" -maxdepth 1 -type f -name '*-shared-context.md' -print | sort)

  if [[ -n "$best_candidate" ]]; then
    printf '%s' "$best_candidate"
    return 0
  fi

  return 1
}

shared_context_matches_project_dir() {
  local session_file=$1
  local project_dir=$2

  [[ -f "$session_file" ]] || return 1
  grep -Fqx -- "- Project directory: $project_dir" "$session_file"
}

resolve_shared_context_file() {
  local project_name=$1
  local project_dir=$2
  local session_dir=$3
  local desired_file canonical_file basename_file basename_slug

  desired_file="$session_dir/$(slugify "$project_name")-shared-context.md"
  basename_slug="$(slugify "$(basename "$project_dir")")"
  basename_file="$session_dir/$basename_slug-shared-context.md"

  if [[ -e "$basename_file" ]]; then
    printf '%s' "$basename_file"
    return
  fi

  if canonical_file="$(find_shared_context_by_project_dir "$session_dir" "$project_dir")"; then
    printf '%s' "$canonical_file"
    return
  fi

  if [[ -e "$desired_file" ]]; then
    if shared_context_matches_project_dir "$desired_file" "$project_dir"; then
      printf '%s' "$desired_file"
      return
    fi
  fi

  printf '%s' "$desired_file"
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
- Auto-push coherent repo-visible changes by default.
- When the work moves from one file to another, automatically commit and push the finished file before starting the next one.
- Do not ask the user for permission before pushing a coherent repo-visible change set.
- Auto-push coherent repo-visible changes by default with `bash $(printf '%q' "$CODEX_COMMIT_HELPER") <paths...>`.
- Use `bash $(printf '%q' "$CODEX_COMMIT_HELPER") --each-path <paths...>` when changing more than one file so each file gets its own short commit message and push before the next file starts.
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
  local content updated tail

  [[ -f "$session_file" ]] || return

  content="$(cat "$session_file")"
  updated="$content"
  tail="$(common_tail_template)"

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
  local git_remote_path=$4
  local github_repo_slug=$5
  local session_dir="$HOME/.codex"
  local session_file
  mkdir -p "$session_dir"

  session_file="$(resolve_shared_context_file "$project_name" "$project_dir" "$session_dir")"

  if [[ -e "$session_file" ]]; then
    compact_shared_context_boilerplate "$session_file"
    ensure_shared_context_knowledge_sections "$session_file"
    ensure_shared_context_session_id "$session_file"
    SHARED_CONTEXT_FILE="$session_file"
    return
  fi

  cat > "$session_file" <<EOF
# Codex shared session context

- Project name: $project_name
- Project directory: $project_dir
- Target file: $target_file
- Active task artifact ID: $(basename "$target_file")
- Git remote path: $git_remote_path
- GitHub repo: $github_repo_slug
- Session ID: $(generate_session_id)
- Queue file: $project_dir/docs/queue.md
- Knowledge file: $project_dir/docs/knowledge.md
- Session source of truth: this file

$(task_artifact_template)
EOF

  ensure_shared_context_session_id "$session_file"
  ensure_shared_context_active_artifact_id "$session_file"
  SHARED_CONTEXT_FILE="$session_file"
}

role_prompt() {
  local role=$1
  local project_name=$2
  local project_dir=$3
  local target_file=$4
  local session_file=$5
  local git_remote_path=${6:-"{GIT_REMOTE_PATH}"}
  local github_repo_slug=${7:-"{GITHUB_REPO_SLUG}"}
  local prompt_body

  prompt_body="$(role_prompt_body "$role")"

  cat <<EOF
$(base_wrapper_prompt "$role" "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug")

$prompt_body
EOF
}

launch_ghostty_session() {
  local project_name=$1
  local project_dir=$2
  local target_file=$3
  local session_file=$4
  local git_remote_path=$5
  local github_repo_slug=$6
  local prompt1=$7
  local prompt2=$8
  local prompt3=$9
  local prompt4=${10}
  local pane1_title pane2_title pane3_title pane4_title
  local pane1_command pane2_command pane3_command pane4_command

  pane1_title="$(build_session_title "$project_name" "$project_dir" "$target_file" "$session_file" "BUILDER")"
  pane2_title="$(build_session_title "$project_name" "$project_dir" "$target_file" "$session_file" "DEBUGGER")"
  pane3_title="$(build_session_title "$project_name" "$project_dir" "$target_file" "$session_file" "BACKEND")"
  pane4_title="$(build_session_title "$project_name" "$project_dir" "$target_file" "$session_file" "CRITIC")"

  pane1_command="$(pane_command_with_title "$pane1_title" "$prompt1")"
  pane2_command="$(pane_command_with_title "$pane2_title" "$prompt3")"
  pane3_command="$(pane_command_with_title "$pane3_title" "$prompt2")"
  pane4_command="$(pane_command_with_title "$pane4_title" "$prompt4")"

  if ! osascript <<EOF
tell application "Ghostty"
  activate

  set launcherWindow to front window
  set cfg to new surface configuration
  set initial working directory of cfg to $(applescript_string "$project_dir")
  set environment variables of cfg to {"GHOSTTY_LAUNCHPAD_SESSION=1", "DISABLE_AUTO_UPDATE=true", "DISABLE_UPDATE_PROMPT=true", $(applescript_string "GIT_REMOTE_PATH=$git_remote_path"), $(applescript_string "GITHUB_REPO_SLUG=$github_repo_slug")}
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
    return 1
  fi
}

launch_ghostty_watch_window() {
  local project_name=$1
  local project_dir=$2
  local session_file=$3
  local watch_command=$4
  local watch_title watch_shell_command

  watch_title="$(build_watch_title "$project_name" "$project_dir" "$session_file")"
  watch_shell_command="printf '\\033]0;%s\\a' $(shell_single_quote "$watch_title"); bash -lc $(shell_single_quote "$watch_command")"

  if ! osascript <<EOF
tell application "Ghostty"
  activate

  set cfg to new surface configuration
  set initial working directory of cfg to $(applescript_string "$project_dir")
  set environment variables of cfg to {"GHOSTTY_LAUNCHPAD_SESSION=1", "DISABLE_AUTO_UPDATE=true", "DISABLE_UPDATE_PROMPT=true"}
  set win to new window with configuration cfg
  set pane1 to terminal 1 of selected tab of win

  delay ${SHELL_STARTUP_DELAY_SECONDS}

  input text $(applescript_string "$watch_shell_command") to pane1
  send key "enter" to pane1
end tell
EOF
  then
    return 1
  fi
}

main() {
  local project_name project_dir session_file project_name_compact target_file requested_file
  local resolved_project_slug
  local git_remote_path github_repo_slug
  local launch_mode="launch"
  local watch_requested=0
  local watch_command=""
  local last_project_name last_project_dir last_target_file last_session_file
  local -a roles prompts
  local role

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --resume-last|--resume)
        launch_mode="resume"
        ;;
      --status-last|--what-was-i-doing|--last)
        launch_mode="status"
        ;;
      --watch)
        watch_requested=1
        ;;
      --watch-command)
        watch_requested=1
        shift
        [[ $# -gt 0 ]] || { echo "Missing watch command." >&2; exit 1; }
        watch_command="$1"
        ;;
      -h|--help)
        cat <<'EOF'
Usage:
  bash git-ghostty-codex-launchpad.sh
  bash git-ghostty-codex-launchpad.sh --resume-last
  bash git-ghostty-codex-launchpad.sh --status-last
  bash git-ghostty-codex-launchpad.sh --watch
  bash git-ghostty-codex-launchpad.sh --watch-command "npm test -- --watch"

Modes:
  - Default: launch the four-pane Ghostty Codex session.
  - --resume-last: reopen the last saved project session state.
  - --status-last: print the last saved session summary and exit.
  - --watch: open a live status watcher for the launched project.
  - --watch-command: open a live watcher window with the supplied shell command.
EOF
        return 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        return 1
        ;;
    esac
    shift
  done

  if [[ "$launch_mode" == "status" ]]; then
    print_last_launch_state
    return 0
  fi

  if [[ "$launch_mode" == "resume" ]]; then
    if [[ ! -f "$LAUNCHPAD_LAST_SESSION_FILE" ]]; then
      echo "No saved launch state has been recorded yet." >&2
      return 1
    fi

    last_project_name="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Project name")"
    last_project_dir="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Project directory")"
    last_target_file="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Target file")"
    last_session_file="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Shared context file")"

    if [[ -z "$last_project_name" || -z "$last_project_dir" || -z "$last_target_file" ]]; then
      echo "Saved launch state is incomplete." >&2
      return 1
    fi

    project_name="$last_project_name"
    project_dir="$last_project_dir"
    target_file="$last_target_file"

    if [[ ! -d "$project_dir" ]]; then
      echo "Saved project directory no longer exists: $project_dir" >&2
      return 1
    fi

    make_shared_context "$project_name" "$project_dir" "$target_file" "$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Git remote path")" "$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "GitHub repo")"
    session_file="$SHARED_CONTEXT_FILE"
    git_remote_path="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Git remote path")"
    github_repo_slug="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "GitHub repo")"

    store_last_launch_state "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug" "$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Watch command")"

    roles=(BUILDER BACKEND DEBUGGER CRITIC)
    for role in "${roles[@]}"; do
      prompts+=("$(role_prompt "$role" "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug")")
    done

    launch_ghostty_session "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug" "${prompts[0]}" "${prompts[1]}" "${prompts[2]}" "${prompts[3]}"

  printf 'Resumed Ghostty Codex session for %s\nProject directory: %s\nTarget file: %s\nShared context: %s\n' "$project_name" "$project_dir" "$target_file" "$session_file"
  printf 'Session ID: %s\nTask label: %s\nArtifact ID: %s\nPhase: %s\nContext budget: %s\nQueue file: %s\nKnowledge file: %s\nGit branch: %s\nGit status: %s\nGit remote path: %s\nGitHub repo: %s\n' \
      "$(shared_context_session_id "$session_file")" \
      "$(sanitize_title_text "$(queue_now_item "$project_dir/docs/queue.md")" 28)" \
      "$(shared_context_header_value "$session_file" "Active task artifact ID" || true)" \
      "$(session_phase_for_role "BUILDER")" \
      "$(context_budget_indicator "$session_file")" \
      "$project_dir/docs/queue.md" \
      "$project_dir/docs/knowledge.md" \
      "$(project_git_branch "$project_dir")" \
      "$(project_git_status "$project_dir")" \
      "$git_remote_path" \
      "$github_repo_slug"
    if [[ $watch_requested -eq 1 ]]; then
      watch_command="$(launch_state_header_value "$LAUNCHPAD_LAST_SESSION_FILE" "Watch command")"
      if [[ -z "$watch_command" ]]; then
        watch_command="$(build_default_watch_command "$project_dir")"
      fi
      launch_ghostty_watch_window "$project_name" "$project_dir" "$session_file" "$watch_command"
      printf 'Started live watcher window for %s\n' "$project_name"
    fi
    return 0
  fi

  while :; do
    prompt_project_name
    project_name="$PROJECT_NAME"
    project_name_compact="$(printf '%s' "$project_name" | tr -d '[:space:]')"
    project_dir=""
    target_file=""

    if [[ -n "$project_name_compact" ]]; then
      if candidate_project_dir="$(search_project_dir_exact "$project_name")"; then
        project_dir="$candidate_project_dir"
      elif candidate_project_dir="$(search_project_dir "$project_name")"; then
        if confirm_project_match "$project_name" "$candidate_project_dir"; then
          project_dir="$candidate_project_dir"
        else
          continue
        fi
      fi
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
      resolved_project_slug="$(slugify "$(basename "$project_dir")")"
      if [[ -n "$resolved_project_slug" ]]; then
        project_name="$(display_name_from_slug "$resolved_project_slug")"
      fi

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

    break
  done

  launch_remote_defaults "$project_dir"

  prompt_git_remote_path "$GIT_REMOTE_PATH_DEFAULT"
  git_remote_path="$GIT_REMOTE_PATH"
  prompt_github_repo_slug "$GITHUB_REPO_SLUG_DEFAULT"
  github_repo_slug="$GITHUB_REPO_SLUG"

  make_shared_context "$project_name" "$project_dir" "$target_file" "$git_remote_path" "$github_repo_slug"
  session_file="$SHARED_CONTEXT_FILE"
  store_last_launch_state "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug" "$watch_command"

  roles=(BUILDER BACKEND DEBUGGER CRITIC)
  for role in "${roles[@]}"; do
    prompts+=("$(role_prompt "$role" "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug")")
  done

  launch_ghostty_session "$project_name" "$project_dir" "$target_file" "$session_file" "$git_remote_path" "$github_repo_slug" "${prompts[0]}" "${prompts[1]}" "${prompts[2]}" "${prompts[3]}"

  printf 'Prepared Ghostty Codex session for %s\nProject directory: %s\nTarget file: %s\nShared context: %s\n' "$project_name" "$project_dir" "$target_file" "$session_file"
  printf 'Session ID: %s\nTask label: %s\nArtifact ID: %s\nPhase: %s\nContext budget: %s\nQueue file: %s\nKnowledge file: %s\nGit branch: %s\nGit status: %s\nGit remote path: %s\nGitHub repo: %s\n' \
    "$(shared_context_session_id "$session_file")" \
    "$(sanitize_title_text "$(queue_now_item "$project_dir/docs/queue.md")" 28)" \
    "$(shared_context_header_value "$session_file" "Active task artifact ID" || true)" \
    "$(session_phase_for_role "BUILDER")" \
    "$(context_budget_indicator "$session_file")" \
    "$project_dir/docs/queue.md" \
    "$project_dir/docs/knowledge.md" \
    "$(project_git_branch "$project_dir")" \
    "$(project_git_status "$project_dir")" \
    "$git_remote_path" \
    "$github_repo_slug"

  if [[ $watch_requested -eq 1 ]]; then
    if [[ -z "$watch_command" ]]; then
      watch_command="$(build_default_watch_command "$project_dir")"
    fi
    launch_ghostty_watch_window "$project_name" "$project_dir" "$session_file" "$watch_command"
    printf 'Started live watcher window for %s\n' "$project_name"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
