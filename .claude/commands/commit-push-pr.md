# Commit, Push, And PR Check

Use this when a finished launcher-repo change should be published and the user explicitly asked for GitHub publishing.

1. Run `git status --short --branch`.
2. Inspect `git diff -- <paths>` for the intended files.
3. Commit and push each completed file with `bash scripts/codex-commit.sh <path>`.
4. If a pull request is involved, run `gh pr view --comments` and summarize unresolved feedback.

For launched target projects in publish mode `auto`, use the same helper and prefer `--each-path` when several finished files are ready.
