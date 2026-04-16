#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/codex-commit.sh -m "commit message" <path> [<path> ...]
  bash scripts/codex-commit.sh --no-push -m "commit message" <path> [<path> ...]
  bash scripts/codex-commit.sh --no-push <path> [<path> ...]
  bash scripts/codex-commit.sh <path> [<path> ...]

Behavior:
  - Stages only the paths you pass.
  - Uses the supplied message when provided.
  - Otherwise generates a human-readable message from the staged paths.
  - By default, commits and then pushes to the configured upstream branch.
  - If no upstream exists, it tries to infer a safe GitHub destination from remotes,
    repo docs, and the authenticated GitHub account before asking you to use --no-push.
  - With --no-push, commits locally without pushing.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
repo_root="$(git -C "$project_root" rev-parse --show-toplevel)"
project_prefix="${project_root#$repo_root/}"

message=""
push_after_commit=1
upstream_ref=""
upstream_remote=""
upstream_branch=""
shared_context_file="$HOME/.codex/codex-ghostty-launcher-shared-context.md"
declare -a paths=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -m|--message)
      shift
      [ "$#" -gt 0 ] || { echo "Missing commit message." >&2; exit 1; }
      message="$1"
      ;;
    --push)
      push_after_commit=1
      ;;
    --no-push)
      push_after_commit=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        paths+=("$1")
        shift
      done
      break
      ;;
    *)
      paths+=("$1")
      ;;
  esac
  shift
done

[ "${#paths[@]}" -gt 0 ] || { usage >&2; exit 1; }

cd "$repo_root"

trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

github_slug_from_url() {
  local url=${1:-}
  case "$url" in
    git@github.com:*)
      url="${url#git@github.com:}"
      ;;
    ssh://git@github.com/*)
      url="${url#ssh://git@github.com/}"
      ;;
    https://github.com/*)
      url="${url#https://github.com/}"
      ;;
    http://github.com/*)
      url="${url#http://github.com/}"
      ;;
    *)
      return 1
      ;;
  esac

  url="${url%.git}"

  case "$url" in
    */*)
      printf '%s\n' "$url"
      return 0
      ;;
  esac

  return 1
}

github_url_from_slug() {
  printf 'https://github.com/%s.git\n' "$1"
}

github_login() {
  if command -v gh >/dev/null 2>&1; then
    gh api user --jq .login 2>/dev/null || true
  fi
}

append_unique() {
  local value=$1
  local item

  [ -n "$value" ] || return 0

  if [ "${#unique_values[@]}" -gt 0 ]; then
    for item in "${unique_values[@]}"; do
      [ "$item" != "$value" ] || return 0
    done
  fi

  unique_values+=("$value")
}

append_unique_label() {
  local value=$1
  local item

  [ -n "$value" ] || return 0

  if [ "${#unique_labels[@]}" -gt 0 ]; then
    for item in "${unique_labels[@]}"; do
      [ "$item" != "$value" ] || return 0
    done
  fi

  unique_labels+=("$value")
}

describe_generic_path() {
  local rel_path=$1
  local rel_base rel_stem extension

  rel_base="$(basename "$rel_path")"
  rel_stem="${rel_base%.*}"
  rel_stem="${rel_stem//-/ }"
  rel_stem="$(trim "$rel_stem")"
  extension="${rel_base##*.}"

  if [ "$rel_base" = "$extension" ]; then
    extension=""
  fi

  case "$extension" in
    md|mdx|txt)
      printf '%s documentation\n' "$rel_stem"
      ;;
    sh|py|js|jsx|ts|tsx|rb|go|rs|java|c|cc|cpp|h)
      printf '%s behavior\n' "$rel_stem"
      ;;
    json|toml|yaml|yml)
      printf '%s configuration\n' "$rel_stem"
      ;;
    *)
      printf '%s updates\n' "$rel_stem"
      ;;
  esac
}

collect_doc_repo_candidates() {
  local source line slug login filtered
  local -a sources=()
  local -a doc_candidates=()
  local -a unique_values=()
  local -a login_matches=()

  sources+=("$project_root/README.md" "$project_root/docs/knowledge.md")

  if [ -f "$shared_context_file" ]; then
    sources+=("$shared_context_file")
  fi

  for source in "${sources[@]}"; do
    [ -f "$source" ] || continue

    while IFS= read -r line; do
      while IFS= read -r slug; do
        slug="$(trim "$slug")"
        append_unique "$slug"
      done < <(
        printf '%s\n' "$line" \
          | perl -ne 'while (/github\.com[:\/]([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)/g) { print "$1\n"; }
                        while (/(?:mapped to|publishes to GitHub repo)\s+`([^`]+)`/g) { print "$1\n"; }'
      )
    done < <(rg -N 'github\.com|mapped to|publishes to GitHub repo' "$source" || true)
  done

  doc_candidates=("${unique_values[@]}")
  [ "${#doc_candidates[@]}" -gt 0 ] || return 1

  if [ "${#doc_candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${doc_candidates[0]}"
    return 0
  fi

  login="$(github_login)"

  if [ -n "$login" ]; then
    for filtered in "${doc_candidates[@]}"; do
      case "$filtered" in
        "$login"/*)
          login_matches+=("$filtered")
          ;;
      esac
    done
  fi

  if [ "${#login_matches[@]}" -eq 1 ]; then
    printf '%s\n' "${login_matches[0]}"
    return 0
  fi

  printf 'Ambiguous GitHub repo mapping in repo docs:' >&2
  for slug in "${doc_candidates[@]}"; do
    printf ' %s' "$slug" >&2
  done
  printf '\n' >&2
  return 1
}

resolve_remote_for_push() {
  local remote_name remote_url remote_slug branch_name inferred_slug candidate_branch
  local -a remotes=()
  local -a github_remotes=()
  local -a matching_remotes=()

  branch_name="$(git branch --show-current)"
  [ -n "$branch_name" ] || {
    echo "Cannot push: detached HEAD has no branch name to publish." >&2
    return 1
  }

  if upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"; then
    upstream_remote="${upstream_ref%%/*}"
    upstream_branch="${upstream_ref#*/}"

    if ! git merge-base HEAD "$upstream_ref" >/dev/null 2>&1; then
      echo "Cannot push: configured upstream $upstream_ref has no merge base with the current branch. Reconfigure the upstream or rerun with --no-push." >&2
      return 1
    fi

    return 0
  fi

  while IFS= read -r remote_name; do
    [ -n "$remote_name" ] || continue
    remote_url="$(git remote get-url --push "$remote_name" 2>/dev/null || git remote get-url "$remote_name" 2>/dev/null || true)"
    remotes+=("$remote_name")

    if remote_slug="$(github_slug_from_url "$remote_url")"; then
      github_remotes+=("$remote_name:$remote_slug")
    fi
  done < <(git remote)

  if [ "${#remotes[@]}" -eq 1 ]; then
    upstream_remote="${remotes[0]}"
    upstream_branch="$branch_name"
    return 0
  fi

  if [ "${#github_remotes[@]}" -eq 1 ]; then
    upstream_remote="${github_remotes[0]%%:*}"
    upstream_branch="$branch_name"
    return 0
  fi

  if inferred_slug="$(collect_doc_repo_candidates)"; then
    for remote_name in "${github_remotes[@]}"; do
      remote_slug="${remote_name#*:}"
      if [ "$remote_slug" = "$inferred_slug" ]; then
        matching_remotes+=("${remote_name%%:*}")
      fi
    done

    if [ "${#matching_remotes[@]}" -eq 1 ]; then
      upstream_remote="${matching_remotes[0]}"
      upstream_branch="$branch_name"
      return 0
    fi

    if [ "${#matching_remotes[@]}" -gt 1 ]; then
      echo "Cannot push: multiple remotes match inferred GitHub repo $inferred_slug." >&2
      return 1
    fi

    if ! git remote get-url origin >/dev/null 2>&1; then
      git remote add origin "$(github_url_from_slug "$inferred_slug")"
      upstream_remote="origin"
      upstream_branch="$branch_name"
      printf 'Configured origin as %s.\n' "$inferred_slug"
      return 0
    fi
  fi

  echo "Cannot push: no upstream is configured and no single safe GitHub destination could be inferred. Configure a remote/upstream, or rerun with --no-push." >&2
  return 1
}

declare -a rel_paths=()
for path in "${paths[@]}"; do
  if [[ "$path" = /* ]]; then
    abs_path="$path"
  else
    abs_path="$(cd "$project_root" && cd "$(dirname "$path")" && pwd)/$(basename "$path")"
  fi

  case "$abs_path" in
    "$project_root"/*|"$project_root") ;;
    *)
      echo "Refusing to stage path outside project root: $path" >&2
      exit 1
      ;;
  esac

  rel_path="${abs_path#$repo_root/}"

  if [ ! -e "$abs_path" ] && ! git -C "$repo_root" ls-files --error-unmatch -- "$rel_path" >/dev/null 2>&1; then
    echo "Path does not exist and is not tracked: $path" >&2
    exit 1
  fi

  rel_paths+=("$rel_path")
done

if [ "$push_after_commit" -eq 1 ]; then
  resolve_remote_for_push
fi

git add -- "${rel_paths[@]}"

if git diff --cached --quiet -- "${rel_paths[@]}"; then
  echo "No staged changes for the requested paths."
  exit 0
fi

generate_message() {
  local status first base stem action label rel_path label_count
  local -a labels=()
  local -a unique_labels=()
  status="$(git diff --cached --name-status -- "${rel_paths[@]}" | awk 'NR==1 {print substr($1,1,1)}')"
  first="$(printf '%s\n' "${rel_paths[@]}" | head -n1)"
  base="$(basename "$first")"
  stem="${base%.*}"
  stem="${stem//-/ }"
  stem="$(trim "$stem")"

  case "$status" in
    A) action="add" ;;
    D) action="remove" ;;
    R) action="rename" ;;
    *) action="update" ;;
  esac

  for rel_path in "${rel_paths[@]}"; do
    case "$rel_path" in
      "$project_prefix/AGENTS.md")
        labels+=("repo operating rules")
        ;;
      "$project_prefix/README.md")
        labels+=("repo workflow documentation")
        ;;
      "$project_prefix/docs/queue.md")
        labels+=("prompt workflow queue")
        ;;
      "$project_prefix/docs/prompt-source.md")
        labels+=("prompt source contract")
        ;;
      "$project_prefix/docs/generated-prompts.md")
        labels+=("generated prompt docs")
        ;;
      "$project_prefix/docs/context-budget.md")
        labels+=("context budget guidance")
        ;;
      "$project_prefix/docs/knowledge.md")
        labels+=("project knowledge notes")
        ;;
      "$project_prefix/scripts/codex-commit.sh")
        labels+=("commit and publish helper")
        ;;
      "$project_prefix/scripts/render-prompt-docs.sh")
        labels+=("prompt docs generator")
        ;;
      "$project_prefix/scripts/check-prompt-drift.sh")
        labels+=("prompt drift checker")
        ;;
      "$project_prefix/codex/config.toml")
        labels+=("codex runtime defaults")
        ;;
      *)
        labels+=("$(describe_generic_path "$rel_path")")
        ;;
    esac
  done

  for label in "${labels[@]}"; do
    append_unique_label "$label"
  done

  label_count=${#unique_labels[@]}

  if [ "$label_count" -eq 1 ]; then
    printf '%s\n' "$action ${unique_labels[0]}"
    return
  fi

  if [ "$label_count" -eq 2 ]; then
    printf '%s\n' "$action ${unique_labels[0]} and ${unique_labels[1]}"
    return
  fi

  printf '%s\n' "$action ${unique_labels[0]}, ${unique_labels[1]}, and related workflow files"
}

if [ -z "$message" ]; then
  message="$(generate_message)"
fi

message="$(printf '%s' "$message" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
[ -n "$message" ] || { echo "Commit message is empty." >&2; exit 1; }

git commit -m "$message" -- "${rel_paths[@]}"
printf 'Committed: %s\n' "$message"

if [ "$push_after_commit" -eq 1 ]; then
  if [ -n "$upstream_ref" ]; then
    git push "$upstream_remote" "HEAD:$upstream_branch"
    printf 'Pushed to %s.\n' "$upstream_ref"
  else
    git push --set-upstream "$upstream_remote" "HEAD:$upstream_branch"
    printf 'Pushed and set upstream to %s/%s.\n' "$upstream_remote" "$upstream_branch"
  fi
fi
