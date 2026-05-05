#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
docs_dir="$project_root/docs"

if [ ! -d "$docs_dir" ]; then
  echo "No docs directory found at $docs_dir" >&2
  exit 1
fi

find_docs() {
  find "$docs_dir" -type f -name '*.md' | sort
}

extract_front_matter_field() {
  local file=$1
  local field=$2

  awk -v target="$field" '
    NR == 1 && $0 != "---" { exit }
    NR == 1 { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && $0 ~ ("^" target ":") {
      sub("^" target ":[[:space:]]*", "", $0)
      print
      exit
    }
  ' "$file"
}

extract_read_when() {
  local file=$1

  awk '
    NR == 1 && $0 != "---" { exit }
    NR == 1 { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^read_when:[[:space:]]*$/ { capture = 1; next }
    in_fm && capture && /^[A-Za-z0-9_-]+:/ { capture = 0 }
    in_fm && capture && /^[[:space:]]*-[[:space:]]+/ {
      sub(/^[[:space:]]*-[[:space:]]+/, "", $0)
      print
    }
  ' "$file"
}

extract_heading() {
  local file=$1
  sed -n 's/^# \{0,1\}//p' "$file" | head -n1
}

printf 'Docs index for %s\n' "$project_root"
printf 'Read the most relevant docs before editing docs-heavy or policy-heavy parts of the repo.\n'

found_any=0
while IFS= read -r file; do
  found_any=1
  rel_path="${file#$project_root/}"
  title="$(extract_heading "$file")"
  summary="$(extract_front_matter_field "$file" "summary")"

  printf '\n%s\n' "$rel_path"
  if [ -n "$title" ]; then
    printf '  title: %s\n' "$title"
  fi
  if [ -n "$summary" ]; then
    printf '  summary: %s\n' "$summary"
  else
    printf '  summary: MISSING\n'
  fi

  read_when_lines="$(extract_read_when "$file" || true)"
  if [ -n "$read_when_lines" ]; then
    printf '  read_when:\n'
    while IFS= read -r line; do
      printf '    - %s\n' "$line"
    done <<< "$read_when_lines"
  else
    printf '  read_when: MISSING\n'
  fi
done < <(find_docs)

if [ "$found_any" -eq 0 ]; then
  echo "No markdown docs found under $docs_dir" >&2
  exit 1
fi
