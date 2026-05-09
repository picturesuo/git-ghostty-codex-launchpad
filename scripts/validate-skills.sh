#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
skills_dir="$project_root/skills"

if [ ! -d "$skills_dir" ]; then
  echo "No skills directory found at $skills_dir" >&2
  exit 0
fi

names_file="$(mktemp)"
trap 'rm -f "$names_file"' EXIT

error_count=0
skill_count=0

field_value() {
  local file=$1
  local field=$2

  awk -v target="$field" '
    NR == 1 && $0 != "---" { exit }
    NR == 1 { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && $0 ~ ("^" target ":") {
      sub("^" target ":[[:space:]]*", "", $0)
      gsub(/^["'\''"]|["'\''"]$/, "", $0)
      print
      exit
    }
  ' "$file"
}

record_error() {
  local file=$1
  local message=$2

  printf 'Skill validation failed: %s: %s\n' "${file#$project_root/}" "$message" >&2
  error_count=$((error_count + 1))
}

validate_skill() {
  local file=$1
  local name description

  skill_count=$((skill_count + 1))

  if [ "$(sed -n '1p' "$file")" != "---" ]; then
    record_error "$file" "front matter must start on the first line"
    return
  fi

  if ! awk 'NR > 1 && $0 == "---" { found = 1; exit } END { exit found ? 0 : 1 }' "$file"; then
    record_error "$file" "front matter must close with ---"
    return
  fi

  name="$(field_value "$file" "name" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  description="$(field_value "$file" "description" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"

  if [ -z "$name" ]; then
    record_error "$file" "missing non-empty field: name"
  fi

  if [ -z "$description" ]; then
    record_error "$file" "missing non-empty field: description"
  fi

  if [ -n "$name" ]; then
    if grep -Fxq "$name" "$names_file"; then
      record_error "$file" "duplicate skill name: $name"
    else
      printf '%s\n' "$name" >> "$names_file"
    fi
  fi
}

while IFS= read -r skill_file; do
  validate_skill "$skill_file"
done < <(find "$skills_dir" -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' | sort)

if [ "$skill_count" -eq 0 ]; then
  echo "No skills/*/SKILL.md files found." >&2
  exit 0
fi

if [ "$error_count" -gt 0 ]; then
  exit 1
fi

printf 'Validated %d skill(s).\n' "$skill_count"
