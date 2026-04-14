#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/codex-commit.sh -m "commit message" [--push] [--remote origin] <path> [<path> ...]
  bash scripts/codex-commit.sh [--push] [--remote origin] <path> [<path> ...]

Behavior:
  - Stages only the paths you pass.
  - Uses the supplied message when provided.
  - Otherwise generates a short message from the staged paths.
  - With --push, pushes the current branch after a successful commit.
  - With --push and no new staged changes, pushes the current branch if it is already ahead or has no upstream yet.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
repo_root="$(git -C "$project_root" rev-parse --show-toplevel)"
if [ "$project_root" = "$repo_root" ]; then
  project_prefix=""
else
  project_prefix="${project_root#$repo_root/}"
fi

message=""
push_after_commit=0
remote_name="origin"
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
    --remote)
      shift
      [ "$#" -gt 0 ] || { echo "Missing remote name." >&2; exit 1; }
      remote_name="$1"
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

git add -- "${rel_paths[@]}"

current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

push_current_branch() {
  local branch=$1

  [ -n "$branch" ] || {
    echo "Refusing to push from a detached HEAD." >&2
    exit 1
  }

  git remote get-url "$remote_name" >/dev/null 2>&1 || {
    echo "Remote does not exist: $remote_name" >&2
    exit 1
  }

  if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    git push
  else
    git push -u "$remote_name" "$branch"
  fi
}

generate_message() {
  local status first base stem action all_workflow_paths rel_path workflow_prefix
  status="$(git diff --cached --name-status -- "${rel_paths[@]}" | awk 'NR==1 {print substr($1,1,1)}')"
  first="$(printf '%s\n' "${rel_paths[@]}" | head -n1)"
  base="$(basename "$first")"
  stem="${base%.*}"
  stem="${stem//-/ }"

  case "$status" in
    A) action="add" ;;
    D) action="remove" ;;
    R) action="rename" ;;
    *) action="update" ;;
  esac

  if [ "${#rel_paths[@]}" -eq 1 ]; then
    case "$first" in
      */AGENTS.md|AGENTS.md)
        printf '%s\n' "$action codex workflow"
        return
        ;;
      */docs/queue.md|docs/queue.md)
        printf '%s\n' "$action queue docs"
        return
        ;;
      */scripts/codex-commit.sh|scripts/codex-commit.sh)
        printf '%s\n' "$action commit helper"
        return
        ;;
    esac

    printf '%s\n' "$action $stem"
    return
  fi

  if [ -n "$project_prefix" ]; then
    workflow_prefix="$project_prefix/"
  else
    workflow_prefix=""
  fi

  all_workflow_paths=1
  for rel_path in "${rel_paths[@]}"; do
    case "$rel_path" in
      "${workflow_prefix}AGENTS.md"|"${workflow_prefix}docs/queue.md"|"${workflow_prefix}scripts/codex-commit.sh") ;;
      *)
        all_workflow_paths=0
        break
        ;;
    esac
  done

  if [ "$all_workflow_paths" -eq 1 ]; then
    printf '%s\n' "$action codex workflow files"
    return
  fi

  printf '%s\n' "$action ${#rel_paths[@]} files"
}

if [ -z "$message" ]; then
  message="$(generate_message)"
fi

message="$(printf '%s' "$message" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
[ -n "$message" ] || { echo "Commit message is empty." >&2; exit 1; }

if git diff --cached --quiet -- "${rel_paths[@]}"; then
  if [ "$push_after_commit" -eq 1 ]; then
    branch="$(current_branch)"
    push_current_branch "$branch"
    printf 'Pushed branch: %s\n' "$branch"
    exit 0
  fi

  echo "No staged changes for the requested paths."
  exit 0
fi

git commit -m "$message" -- "${rel_paths[@]}"
printf 'Committed: %s\n' "$message"

if [ "$push_after_commit" -eq 1 ]; then
  branch="$(current_branch)"
  push_current_branch "$branch"
  printf 'Pushed branch: %s\n' "$branch"
fi
