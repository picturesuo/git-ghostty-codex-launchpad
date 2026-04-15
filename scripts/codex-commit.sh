#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash /path/to/codex-commit.sh -m "commit message" [--no-push] [--remote origin] [--project-root /path/to/project] <path> [<path> ...]
  bash /path/to/codex-commit.sh [--no-push] [--remote origin] [--project-root /path/to/project] <path> [<path> ...]

Behavior:
  - Stages only the paths you pass.
  - Uses the supplied message when provided.
  - Otherwise generates a short message from the staged paths.
  - Pushes the current branch after a successful commit by default.
  - With --no-push, commits locally without pushing.
  - Uses the current working directory as the project root unless --project-root is provided.
EOF
}

invocation_dir="$(pwd)"
project_root="$invocation_dir"

resolve_repo_root() {
  local root=$1

  if ! git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Selected project is not inside a git repository: $root" >&2
    exit 1
  fi

  git -C "$root" rev-parse --show-toplevel
}

message=""
push_after_commit=1
remote_name="origin"
explicit_project_root=""
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
    --remote)
      shift
      [ "$#" -gt 0 ] || { echo "Missing remote name." >&2; exit 1; }
      remote_name="$1"
      ;;
    --project-root)
      shift
      [ "$#" -gt 0 ] || { echo "Missing project root." >&2; exit 1; }
      explicit_project_root="$1"
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

if [ -n "$explicit_project_root" ]; then
  project_root="$(cd "$explicit_project_root" && pwd)"
else
  project_root="$invocation_dir"
fi

repo_root="$(resolve_repo_root "$project_root")"

if [ "$project_root" = "$repo_root" ]; then
  project_prefix=""
else
  project_prefix="${project_root#$repo_root/}"
fi

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
  local status first base stem action rel_path workflow_prefix topic_keys
  local -a topics=()

  status="$(git diff --cached --name-status -- "${rel_paths[@]}" | awk 'NR==1 {print substr($1,1,1)}')"
  first="$(printf '%s\n' "${rel_paths[@]}" | head -n1)"
  base="$(basename "$first")"
  stem="${base%.*}"
  stem="${stem//-/ }"
  topic_keys=""

  case "$status" in
    A) action="add" ;;
    D) action="remove" ;;
    R) action="rename" ;;
    *) action="update" ;;
  esac

  if [ "${#rel_paths[@]}" -eq 1 ]; then
    case "$first" in
      */AGENTS.md|AGENTS.md)
        printf '%s\n' "$action repo workflow rules"
        return
        ;;
      */README.md|README.md)
        printf '%s\n' "$action project documentation"
        return
        ;;
      */docs/queue.md|docs/queue.md)
        printf '%s\n' "$action work queue"
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

  for rel_path in "${rel_paths[@]}"; do
    case "$rel_path" in
      "${workflow_prefix}AGENTS.md"|AGENTS.md)
        case "|$topic_keys|" in
          *"|repo policy|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}repo policy"
            topics+=("repo policy")
            ;;
        esac
        ;;
      "${workflow_prefix}README.md"|README.md)
        case "|$topic_keys|" in
          *"|README|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}README"
            topics+=("README")
            ;;
        esac
        ;;
      "${workflow_prefix}docs/queue.md"|docs/queue.md)
        case "|$topic_keys|" in
          *"|queue docs|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}queue docs"
            topics+=("queue docs")
            ;;
        esac
        ;;
      "${workflow_prefix}scripts/codex-commit.sh"|scripts/codex-commit.sh)
        case "|$topic_keys|" in
          *"|commit helper|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}commit helper"
            topics+=("commit helper")
            ;;
        esac
        ;;
      "${workflow_prefix}git-ghostty-codex-launchpad.sh"|git-ghostty-codex-launchpad.sh)
        case "|$topic_keys|" in
          *"|launcher workflow|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}launcher workflow"
            topics+=("launcher workflow")
            ;;
        esac
        ;;
      "${workflow_prefix}start-git-ghostty-codex-launchpad.sh"|start-git-ghostty-codex-launchpad.sh|"${workflow_prefix}open-git-ghostty-codex-launchpad.command"|open-git-ghostty-codex-launchpad.command)
        case "|$topic_keys|" in
          *"|launcher wrappers|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}launcher wrappers"
            topics+=("launcher wrappers")
            ;;
        esac
        ;;
      *)
        stem="$(basename "$rel_path")"
        stem="${stem%.*}"
        stem="${stem//[-_]/ }"
        case "|$topic_keys|" in
          *"|$stem|"*) ;;
          *)
            topic_keys="${topic_keys}${topic_keys:+|}$stem"
            topics+=("$stem")
            ;;
        esac
        ;;
    esac
  done

  case "${#topics[@]}" in
    0)
      printf '%s\n' "$action changes"
      ;;
    1)
      printf '%s %s\n' "$action" "${topics[0]}"
      ;;
    2)
      printf '%s %s and %s\n' "$action" "${topics[0]}" "${topics[1]}"
      ;;
    *)
      local joined=""
      local i

      for ((i=0; i<${#topics[@]}-1; i++)); do
        if [ -n "$joined" ]; then
          joined+=", "
        fi
        joined+="${topics[i]}"
      done

      printf '%s %s, and %s\n' "$action" "$joined" "${topics[$((${#topics[@]} - 1))]}"
      ;;
  esac
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
