#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash /path/to/codex-commit.sh -m "commit message" [--no-push] [--remote auto|<name>] [--project-root /path/to/project] <path> [<path> ...]
  bash /path/to/codex-commit.sh [--no-push] [--remote auto|<name>] [--project-root /path/to/project] <path> [<path> ...]
  bash /path/to/codex-commit.sh --each-path [--no-push] [--remote auto|<name>] [--project-root /path/to/project] <path> [<path> ...]

Behavior:
  - Stages only the paths you pass.
  - Uses the supplied message when provided.
  - Otherwise generates a readable message from the staged paths.
  - Pushes the current branch after a successful commit by default.
  - With --no-push, commits locally without pushing.
  - Uses the current working directory as the project root unless --project-root is provided.
  - With --remote auto (default), prefers the repo's existing push remote and otherwise
    fails if the selected project has no safe existing remote context.
  - With --each-path, commits and pushes each staged path separately with a short message.
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
remote_name="auto"
explicit_project_root=""
split_each_path=0
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
    --each-path)
      split_each_path=1
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

normalize_repo_key() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/\.git$//; s/[^a-z0-9]/ /g; s/[[:space:]]\+/ /g; s/^ //; s/ $//; s/ /-/g'
}

add_candidate_name() {
  local candidate=$1 normalized existing

  candidate="$(printf '%s' "$candidate" | sed 's/^ //; s/ $//')"
  [ -n "$candidate" ] || return 0
  normalized="$(normalize_repo_key "$candidate")"
  [ -n "$normalized" ] || return 0

  for existing in "${candidate_repo_names[@]:-}"; do
    if [ "$existing" = "$normalized" ]; then
      return 0
    fi
  done

  candidate_repo_names+=("$normalized")
}

read_package_name() {
  local package_file name

  for package_file in "$project_root/package.json" "$repo_root/package.json"; do
    if [ -f "$package_file" ]; then
      name="$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$package_file" | head -n1)"
      if [ -n "$name" ]; then
        printf '%s\n' "$name"
        return 0
      fi
    fi
  done

  return 1
}

read_readme_title() {
  local readme_file heading

  for readme_file in "$project_root/README.md" "$repo_root/README.md"; do
    if [ -f "$readme_file" ]; then
      heading="$(sed -n 's/^# \{0,1\}//p' "$readme_file" | head -n1 | sed 's/^ //; s/ $//')"
      if [ -n "$heading" ]; then
        printf '%s\n' "$heading"
        return 0
      fi
    fi
  done

  return 1
}

infer_github_owner() {
  if ! command -v gh >/dev/null 2>&1; then
    return 1
  fi

  gh api user --jq '.login' 2>/dev/null || return 1
}

read_doc_mapped_repo() {
  local file match repo_slug
  local -a files=()

  for file in "$project_root/README.md" "$project_root/AGENTS.md" "$project_root/docs/knowledge.md" "$repo_root/README.md" "$repo_root/AGENTS.md" "$repo_root/docs/knowledge.md"; do
    [ -f "$file" ] && files+=("$file")
  done

  [ "${#files[@]}" -gt 0 ] || return 1

  match="$(
    rg -h -o -N '(github\.com[:/]|https://github\.com/)[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' "${files[@]}" 2>/dev/null | \
      sed -E 's#(https://github\.com/|github\.com[:/])##; s/\.git$//' | \
      head -n1
  )"

  if [ -z "$match" ]; then
    match="$(
      rg -h -o -N 'publishes to GitHub repo `[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+`' "${files[@]}" 2>/dev/null | \
        sed -E 's/.*`([^`]+)`.*/\1/' | \
        head -n1
    )"
  fi

  repo_slug="$(printf '%s' "$match" | sed 's/^ //; s/ $//')"
  [ -n "$repo_slug" ] || return 1

  printf '%s\n' "$repo_slug"
}

repo_slug_to_ssh_url() {
  local repo_slug=$1

  if command -v gh >/dev/null 2>&1; then
    gh repo view "$repo_slug" --json sshUrl --jq '.sshUrl' 2>/dev/null && return 0
  fi

  printf 'git@github.com:%s.git\n' "$repo_slug"
}

resolve_existing_remote() {
  local upstream remote
  local -a remotes=()

  if [ "$remote_name" != "auto" ]; then
    git remote get-url "$remote_name" >/dev/null 2>&1 || {
      echo "Remote does not exist: $remote_name" >&2
      exit 1
    }
    printf '%s\n' "$remote_name"
    return 0
  fi

  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  if [ -n "$upstream" ]; then
    printf '%s\n' "${upstream%%/*}"
    return 0
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    printf '%s\n' "origin"
    return 0
  fi

  while IFS= read -r remote; do
    [ -n "$remote" ] && remotes+=("$remote")
  done < <(git remote)

  if [ "${#remotes[@]}" -eq 1 ]; then
    printf '%s\n' "${remotes[0]}"
    return 0
  fi

  return 1
}

find_matching_github_repo() {
  local owner package_name readme_title repo_name project_name candidate
  local mapped_repo
  candidate_repo_names=()

  if mapped_repo="$(read_doc_mapped_repo 2>/dev/null)"; then
    repo_slug_to_ssh_url "$mapped_repo"
    return 0
  fi

  owner="$(infer_github_owner)" || return 1

  repo_name="$(basename "$repo_root")"
  project_name="$(basename "$project_root")"
  add_candidate_name "$repo_name"
  add_candidate_name "$project_name"

  if package_name="$(read_package_name 2>/dev/null)"; then
    add_candidate_name "$package_name"
  fi
  if readme_title="$(read_readme_title 2>/dev/null)"; then
    add_candidate_name "$readme_title"
  fi

  [ "${#candidate_repo_names[@]}" -gt 0 ] || return 1

  for candidate in "${candidate_repo_names[@]}"; do
    if gh repo view "$owner/$candidate" --json sshUrl --jq '.sshUrl' >/tmp/codex-commit-gh-match.$$ 2>/dev/null; then
      cat /tmp/codex-commit-gh-match.$$
      rm -f /tmp/codex-commit-gh-match.$$
      return 0
    fi
  done

  return 1
}

resolve_push_remote() {
  local existing

  if existing="$(resolve_existing_remote)"; then
    printf '%s\n' "$existing"
    return 0
  fi

  if [ -z "$(git remote)" ]; then
    echo "No git remote is configured for this project. Add a remote or use --no-push." >&2
    exit 1
  fi

  if [ "$remote_name" != "auto" ]; then
    echo "Remote does not exist: $remote_name" >&2
    exit 1
  fi

  echo "Could not resolve a safe push remote automatically from the selected project's existing remotes." >&2
  echo "Configure an upstream remote or pass --remote <name>." >&2
  exit 1
}

push_current_branch() {
  local branch=$1 push_remote

  [ -n "$branch" ] || {
    echo "Refusing to push from a detached HEAD." >&2
    exit 1
  }

  push_remote="$(resolve_push_remote)"
  if git push -u "$push_remote" "$branch"; then
    return 0
  fi

  echo "Initial push failed. Fetching latest $push_remote/$branch and retrying with rebase." >&2
  git fetch "$push_remote" "$branch"

  if ! git pull --rebase "$push_remote" "$branch"; then
    echo "Automatic rebase failed. Resolve the rebase manually, then push again." >&2
    exit 1
  fi

  git push -u "$push_remote" "$branch"
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
        printf '%s repo workflow rules in AGENTS.md\n' "$action"
        return
        ;;
      */README.md|README.md)
        printf '%s project documentation in README.md\n' "$action"
        return
        ;;
      */docs/queue.md|docs/queue.md)
        printf '%s work queue in docs/queue.md\n' "$action"
        return
        ;;
      */scripts/codex-commit.sh|scripts/codex-commit.sh)
        printf '%s commit helper in scripts/codex-commit.sh\n' "$action"
        return
        ;;
    esac

    printf '%s %s in project\n' "$action" "$stem"
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

  if [ "${#topics[@]}" -eq 0 ]; then
    printf '%s %s files in project\n' "$action" "${#rel_paths[@]}"
  elif [ "${#topics[@]}" -eq 1 ]; then
    printf '%s %s in project\n' "$action" "${topics[0]}"
  elif [ "${#topics[@]}" -eq 2 ]; then
    printf '%s %s and %s in project\n' "$action" "${topics[0]}" "${topics[1]}"
  else
    printf '%s %s, %s, and related files in project\n' "$action" "${topics[0]}" "${topics[1]}"
  fi
}

commit_staged_path() {
  local rel_path=$1 commit_message
  local -a rel_paths=("$rel_path")

  if git diff --cached --quiet -- "$rel_path"; then
    return 1
  fi

  if [ -z "$message" ]; then
    commit_message="$(generate_message)"
  else
    commit_message="$message"
  fi

  commit_message="$(printf '%s' "$commit_message" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  [ -n "$commit_message" ] || { echo "Commit message is empty." >&2; exit 1; }

  git commit -m "$commit_message" -- "$rel_path"
  printf 'Committed: %s\n' "$commit_message"

  if [ "$push_after_commit" -eq 1 ]; then
    push_current_branch "$(current_branch)"
    printf 'Pushed current branch.\n'
  fi

  return 0
}

if git diff --cached --quiet -- "${rel_paths[@]}"; then
  echo "No staged changes for the requested paths."
  exit 0
fi

if [ "$split_each_path" -eq 1 ] && [ "${#rel_paths[@]}" -gt 1 ]; then
  committed_any=0

  for rel_path in "${rel_paths[@]}"; do
    if commit_staged_path "$rel_path"; then
      committed_any=1
    fi
  done

  if [ "$committed_any" -eq 0 ]; then
    echo "No staged changes for the requested paths."
    exit 0
  fi
else
  if [ -z "$message" ]; then
    message="$(generate_message)"
  fi

  message="$(printf '%s' "$message" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  [ -n "$message" ] || { echo "Commit message is empty." >&2; exit 1; }

  git commit -m "$message" -- "${rel_paths[@]}"
  printf 'Committed: %s\n' "$message"

  if [ "$push_after_commit" -eq 1 ]; then
    push_current_branch "$(current_branch)"
    printf 'Pushed current branch.\n'
  fi
fi
