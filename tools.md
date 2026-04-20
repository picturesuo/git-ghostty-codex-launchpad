# tools.md

Use this file as the practical command reference for repo-local tools. Prefer commands that actually exist here over guessed package-manager tasks.

## Commit / Git

### `scripts/codex-commit.sh`
- Purpose: stage only the paths you pass, create a commit, and optionally push.
- Location: `scripts/codex-commit.sh`
- Notes: pushes by default; use `--no-push` for local-only commits. `--each-path` splits the work into one commit per path.
- Safe examples:
```bash
bash scripts/codex-commit.sh --no-push AGENTS.md
bash scripts/codex-commit.sh --each-path --no-push AGENTS.md tools.md
```

### `gh`
- Purpose: inspect pull requests, review comments, and CI runs from GitHub without guessing at repo state.
- Location: system CLI
- Notes: use this only when GitHub review or Actions state is relevant to the task.
- Safe examples:
```bash
gh pr view --comments
gh run list --limit 10
```

## Prompt Docs

### `scripts/render-prompt-docs.sh`
- Purpose: regenerate `docs/generated-prompts.md` and `docs/role-selection.md` from `prompts/prompt-source.sh`.
- Location: `scripts/render-prompt-docs.sh`
- Safe examples:
```bash
bash scripts/render-prompt-docs.sh
```

### `scripts/check-prompt-drift.sh`
- Purpose: verify the generated prompt docs and role summaries still match the prompt source and launcher wrapper behavior.
- Location: `scripts/check-prompt-drift.sh`
- Safe examples:
```bash
bash scripts/check-prompt-drift.sh
```

## Docs Index

### `scripts/docs-list.sh`
- Purpose: scan `docs/` for markdown files, extract `summary` and `read_when` front matter, and show which docs to read first.
- Location: `scripts/docs-list.sh`
- Notes: use this before docs-heavy, policy-heavy, or workflow-heavy edits.
- Safe examples:
```bash
bash scripts/docs-list.sh
```

## Verification

### `scripts/check-shell.sh`
- Purpose: run `shellcheck` across the repo's shell entry points and helpers.
- Location: `scripts/check-shell.sh`
- Notes: requires `shellcheck` to be installed.
- Safe examples:
```bash
bash scripts/check-shell.sh
```

### `scripts/check-commit-helper-doc-map.sh`
- Purpose: verify the documented GitHub repo mapping used by the commit helper.
- Location: `scripts/check-commit-helper-doc-map.sh`
- Notes: optionally uses `gh` when available.
- Safe examples:
```bash
bash scripts/check-commit-helper-doc-map.sh
```

## Launcher

### `git-ghostty-codex-launchpad.sh`
- Purpose: start the Ghostty Codex launcher or inspect the last saved session state.
- Location: `git-ghostty-codex-launchpad.sh`
- Safe examples:
```bash
bash git-ghostty-codex-launchpad.sh --status-last
bash git-ghostty-codex-launchpad.sh --resume-last
```

## Notes

- No `scripts/committer` helper is currently present in this repo.
- If a future helper is added, list it here with its purpose, location, and one or two safe example commands.
