# AGENTS.md

## Purpose
This file is the durable repo policy for Codex in `ghostty-codex-launchpad`.
The shared context file at `~/.codex/ghostty-codex-launchpad-shared-context.md`, when present, is the current-task record.

Keep `AGENTS.md` short and stable. Launch-time behavior belongs in `prompts/prompt-source.sh`; the generated role summary belongs in `docs/role-selection.md`; current task memory belongs in the shared context file.

## Repo Layout
- `README.md`: user-facing project overview.
- `AGENTS.md`: durable repo policy.
- `prompts/prompt-source.sh`: canonical launcher and pane prompt source.
- `docs/generated-prompts.md`: generated documentation for the prompt source.
- `docs/prompt-source.md`: prompt ownership overview.
- `docs/role-selection.md`: generated role summary.
- `docs/context-budget.md`: context-budget rules.
- `docs/queue.md`: working queue.
- `docs/knowledge.md`: durable user guidance and project facts.
- `scripts/render-prompt-docs.sh`: regenerate prompt docs from the prompt source.
- `scripts/check-prompt-drift.sh`: check the launcher and generated docs against the prompt source.
- `scripts/check-shell.sh`: shell sanity checks for repo shell entry points and helpers.
- `scripts/check-commit-helper-doc-map.sh`: verify commit-helper GitHub repo mapping.
- `scripts/codex-commit.sh`: stage intended files and push small atomic changes.
- `git-ghostty-codex-launchpad.sh`: main Ghostty launcher.
- `start-git-ghostty-codex-launchpad.sh`: thin shell wrapper.
- `open-git-ghostty-codex-launchpad.command`: macOS launcher.

Do not invent build, test, or runtime commands that are not present in the repo.

## Startup Checklist
1. Read `AGENTS.md`.
2. Read the shared context file if it exists.
3. Read `docs/queue.md`.
4. Inspect the current repo-local files before editing.
5. Check scoped git status for the files you plan to touch.

## Working Rules
- Keep launch-time behavior in the prompt source, not in repo policy.
- Keep prompts short, concrete, and role-specific.
- Use docs as working memory.
- Keep scope tight and changes reversible.
- Prefer targeted validation over whole-repo validation.
- Be explicit about what was verified versus not verified.
- When the work moves from one file to another, commit and push the finished file before starting the next one.
- Use `scripts/codex-commit.sh --each-path` when changing more than one file so each file gets its own short commit message and push.
- If the task grows too large, stop and present options before continuing.

## Queue
`docs/queue.md` is the working queue.

Use these sections:
- `Now`
- `Next`
- `Later`
- `Blocked`
- `Discovered While Working`

Rules:
- Keep `Now` to one small executable task.
- After each meaningful unit of work, add 3 next small tasks, 2 edge cases, and 1 cleanup or simplification item.
- If there is no obvious feature task, improve docs, validation, naming, error handling, or workflow clarity.

## Commit Policy
- Auto-push coherent repo-visible non-private changes by default.
- Use `scripts/codex-commit.sh` with explicit path arguments.
- Keep commits atomic and avoid unrelated staging.
- Default to `main` unless told otherwise.
- Never commit personal, secret, machine-specific, scratch, cache, or other local-only files unless explicitly requested.
- Use `--no-push` only when a local-only commit is intentional or a safe push destination is unavailable.
