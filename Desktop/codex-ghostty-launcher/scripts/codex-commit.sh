#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/codex-commit.sh --push -m "commit message" <path> [<path> ...]
  bash scripts/codex-commit.sh --push <path> [<path> ...]
  bash scripts/codex-commit.sh -m "commit message" <path> [<path> ...]
  bash scripts/codex-commit.sh <path> [<path> ...]

Behavior:
  - Stages only the paths you pass.
  - Uses the supplied message when provided.
  - Otherwise generates a short message from the staged paths.
  - With `--push`, commits first and then pushes the current branch.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
repo_root="$(git -C "$project_root" rev-parse --show-toplevel)"
project_prefix="${project_root#$repo_root/}"

message=""
push_after_commit=0
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
    "$project_root"/*) ;;
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

if git diff --cached --quiet -- "${rel_paths[@]}"; then
  echo "No staged changes for the requested paths."
  exit 0
fi

generate_message() {
  local status first base stem action rel_path
  local -a labels=()
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
        printf '%s\n' "$action repo workflow rules"
        return
        ;;
      */README.md|README.md)
        printf '%s\n' "$action repo documentation"
        return
        ;;
      */docs/queue.md|docs/queue.md)
        printf '%s\n' "$action work queue"
        return
        ;;
      */scripts/codex-commit.sh|scripts/codex-commit.sh)
        printf '%s\n' "$action commit helper messaging"
        return
        ;;
    esac

    printf '%s\n' "$action $stem"
    return
  fi

  for rel_path in "${rel_paths[@]}"; do
    case "$rel_path" in
      "$project_prefix/AGENTS.md")
        labels+=("repo workflow rules")
        ;;
      "$project_prefix/README.md")
        labels+=("repo documentation")
        ;;
      "$project_prefix/docs/queue.md")
        labels+=("work queue")
        ;;
      "$project_prefix/scripts/codex-commit.sh")
        labels+=("commit helper")
        ;;
      *)
        labels+=("related files")
        ;;
    esac
  done

  if [ "${#labels[@]}" -eq 2 ]; then
    printf '%s\n' "$action ${labels[0]} and ${labels[1]}"
    return
  fi

  if [ "${#labels[@]}" -gt 2 ]; then
    printf '%s\n' "$action ${labels[0]}, ${labels[1]}, and related files"
    return
  fi

  printf '%s\n' "$action related files"
}

if [ -z "$message" ]; then
  message="$(generate_message)"
fi

message="$(printf '%s' "$message" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
[ -n "$message" ] || { echo "Commit message is empty." >&2; exit 1; }

git commit -m "$message" -- "${rel_paths[@]}"
printf 'Committed: %s\n' "$message"

if [ "$push_after_commit" -eq 1 ]; then
  git push
  printf 'Pushed current branch.\n'
fi
