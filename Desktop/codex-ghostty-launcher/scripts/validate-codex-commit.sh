#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
helper="$project_root/scripts/codex-commit.sh"

tmp_root="$(mktemp -d -t codex-commit-validate.XXXXXX)"
trap 'rm -rf "$tmp_root"' EXIT

assert_contains() {
  local haystack=$1
  local needle=$2
  local context=$3

  case "$haystack" in
    *"$needle"*) ;;
    *)
      echo "Validation failed: expected '$needle' in $context." >&2
      printf '%s\n' "$haystack" >&2
      exit 1
      ;;
  esac
}

assert_not_contains() {
  local haystack=$1
  local needle=$2
  local context=$3

  case "$haystack" in
    *"$needle"*)
      echo "Validation failed: unexpected '$needle' in $context." >&2
      printf '%s\n' "$haystack" >&2
      exit 1
      ;;
  esac
}

make_repo() {
  local repo_dir=$1
  local include_repo_mapping=${2:-1}

  mkdir -p "$repo_dir/scripts" "$repo_dir/docs"
  cp "$helper" "$repo_dir/scripts/"
  cp "$project_root/README.md" "$repo_dir/README.md"
  cp "$project_root/docs/knowledge.md" "$repo_dir/docs/knowledge.md"

  if [ "$include_repo_mapping" -eq 0 ]; then
    perl -0pi -e 's/For GitHub publishing, treat this duplicate workspace as mapped to `[^`]+`\.\n//g' "$repo_dir/README.md"
    perl -0pi -e 's/^.*publishes to GitHub repo `[^`]+` when automatic destination resolution is needed\.\n//mg' "$repo_dir/docs/knowledge.md"
  fi

  git -C "$repo_dir" init >/dev/null
  git -C "$repo_dir" config user.name test
  git -C "$repo_dir" config user.email test@example.com
  mkdir -p "$repo_dir/home"
}

validate_no_upstream() {
  local repo_dir="$tmp_root/no-upstream"
  local output

  make_repo "$repo_dir" 0
  printf 'one\n' > "$repo_dir/note.txt"
  git -C "$repo_dir" add README.md docs/knowledge.md scripts/codex-commit.sh note.txt
  git -C "$repo_dir" commit -m init >/dev/null
  printf 'two\n' >> "$repo_dir/note.txt"

  if output="$(HOME="$repo_dir/home" bash "$repo_dir/scripts/codex-commit.sh" note.txt 2>&1)"; then
    echo "Validation failed: no-upstream path unexpectedly succeeded." >&2
    exit 1
  fi

  assert_contains "$output" "Cannot push" "no-upstream output"
}

validate_no_push() {
  local repo_dir="$tmp_root/no-push"
  local output

  make_repo "$repo_dir"
  printf 'one\n' > "$repo_dir/note.txt"
  git -C "$repo_dir" add README.md docs/knowledge.md scripts/codex-commit.sh note.txt
  git -C "$repo_dir" commit -m init >/dev/null
  printf 'two\n' >> "$repo_dir/note.txt"

  output="$(HOME="$repo_dir/home" bash "$repo_dir/scripts/codex-commit.sh" --no-push note.txt 2>&1)"

  assert_contains "$output" "Committed:" "no-push output"
  assert_not_contains "$output" "Pushed" "no-push output"
}

validate_path_outside_repo() {
  local repo_dir="$tmp_root/outside"
  local outside_file="$tmp_root/outside-file.txt"
  local output

  make_repo "$repo_dir"
  printf 'one\n' > "$repo_dir/note.txt"
  git -C "$repo_dir" add README.md docs/knowledge.md scripts/codex-commit.sh note.txt
  git -C "$repo_dir" commit -m init >/dev/null
  printf 'outside\n' > "$outside_file"

  if output="$(HOME="$repo_dir/home" bash "$repo_dir/scripts/codex-commit.sh" --no-push "$outside_file" 2>&1)"; then
    echo "Validation failed: outside-repo path unexpectedly succeeded." >&2
    exit 1
  fi

  assert_contains "$output" "Refusing to stage path outside project root" "outside-repo output"
}

validate_message_quality() {
  local repo_dir="$tmp_root/message-quality"
  local output subject

  make_repo "$repo_dir"
  printf 'one\n' > "$repo_dir/note.txt"
  git -C "$repo_dir" add README.md docs/knowledge.md scripts/codex-commit.sh note.txt
  git -C "$repo_dir" commit -m init >/dev/null
  printf 'two\n' >> "$repo_dir/note.txt"

  output="$(HOME="$repo_dir/home" bash "$repo_dir/scripts/codex-commit.sh" --no-push note.txt 2>&1)"
  subject="$(git -C "$repo_dir" log -1 --pretty=%s)"

  assert_contains "$output" "Committed:" "message-quality output"
  assert_contains "$subject" "documentation" "generated commit subject"

  if [ "$(printf '%s\n' "$subject" | wc -w | tr -d ' ')" -lt 3 ]; then
    echo "Validation failed: generated message too short: $subject" >&2
    exit 1
  fi
}

validate_no_upstream
validate_no_push
validate_path_outside_repo
validate_message_quality

echo "codex-commit validation passed."
