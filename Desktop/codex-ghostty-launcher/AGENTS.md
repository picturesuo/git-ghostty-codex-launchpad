# AGENTS.md

## Purpose
This file is the repo-local operating manual for Codex in `ghostty-codex-launcher`.

Read it at the start of each session.
Follow it unless the user explicitly overrides it.
Keep it current. If the same mistake, correction, or gotcha happens twice, update this file.

If `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md` exists, use it as the durable task artifact and session source of truth. Treat this `AGENTS.md` as the standing repo policy and the shared context file as the current-task record.

## Prompt Layering
- Keep durable repo policy in `AGENTS.md`.
- Keep current-task state in `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md`.
- Keep per-request prompts minimal: project context, role, and the instruction to read `AGENTS.md` plus the shared artifact first.
- Do not repeat long workflow contracts, commit ceremony, or response-level status requirements in every prompt when this file and the shared artifact already define them.

## Repo Layout
Current repo-local structure is intentionally small:

- `README.md`: user-facing project documentation.
- `AGENTS.md`: repo-operating instructions for Codex.
- `docs/queue.md`: lightweight work queue and follow-up memory.
- `scripts/codex-commit.sh`: helper for staging intended files and committing small atomic changes.

Do not invent build, test, or runtime commands that are not present in the repo. If new project-specific commands become real, document them here or in `docs/`.

## Core Operating Principles
- Keep blast radius small.
- Prefer fast forward progress over over-planning.
- Make small atomic commits.
- Commit to `main` unless told otherwise.
- Use docs as working memory.
- Use queue-driven execution.
- Prefer CLI-first tooling.
- Use targeted tests and lightweight validation.
- After each task, generate next small tasks, edge cases, and cleanup items.
- Be explicit about what was verified versus not verified.
- If a task grows too large, stop and surface options before continuing.

## Startup Checklist
1. Read `AGENTS.md`.
2. Read `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md` if it exists.
3. Read `docs/queue.md`.
4. Inspect the current repo-local files before editing.
5. Check scoped git status for the files you plan to touch, for example `git status --short -- AGENTS.md docs/queue.md` or `git status --short -- .`.

## Queue-Driven Execution
`docs/queue.md` is the working queue.

Use these sections:
- `Now`
- `Next`
- `Later`
- `Blocked`
- `Discovered While Working`

Rules:
- Keep `Now` limited to the current small executable task.
- Break larger work into the smallest independently shippable slices.
- After each meaningful unit of work, add:
  - 3 next small tasks
  - 2 edge cases
  - 1 cleanup or simplification item
- If there is no obvious feature task, improve docs, validation, naming, error handling, or workflow clarity.

## Four-Pane Workflow

### builder
Responsibilities:
- Implement the current highest-value queued task.
- Make the smallest viable change that satisfies the success criteria.
- Keep changes localized and reversible.
- Update docs and queue entries as part of the same unit of work.
- Commit after each meaningful unit using `scripts/codex-commit.sh`.

### critic
Responsibilities:
- Review recent changes for correctness, unnecessary complexity, missing edge cases, and validation gaps.
- Focus on bugs, regressions, risky assumptions, unclear naming, and documentation drift.
- Produce concrete, actionable findings.
- Do not block progress unless risk is material.

### debugger
Responsibilities:
- Reproduce failures with the smallest possible loop.
- Inspect logs, CLI output, diffs, and targeted checks before editing.
- Prefer the smallest fix that addresses the identified cause.
- State clearly what failed, what was reproduced, and what remains uncertain.

### queue-manager
Responsibilities:
- Keep `docs/queue.md` current.
- Convert vague ideas into concrete small tasks.
- Add follow-up tasks, edge cases, and cleanup items discovered during work.
- Prevent idle time by keeping the next small unit ready.

## Navigation and Tooling
- Prefer `rg` for search and `rg --files` for file discovery.
- Prefer `sed -n` or `nl -ba` for focused file inspection.
- Prefer repo-local scripts over ad hoc command sequences when scripts exist.
- Prefer direct CLI verification over broad manual exploration.

## Edit Discipline
- Optimize for clarity, locality, and reversibility.
- Keep each change limited to one logical idea.
- Do not mix workflow updates with unrelated product changes.
- Avoid opportunistic rewrites or wide formatting churn.
- If a task starts touching too many files or requires architecture changes, stop and present options.

## Validation Policy
- Run the lightest relevant checks that materially reduce risk.
- Prefer targeted validation over whole-repo validation.
- For docs or script-only changes, file inspection plus shell validation is usually enough.
- Only claim verification you actually performed.

When reporting completion, separate:
- verified
- not verified
- remaining uncertainty

## Commit Policy
- Commit after each meaningful unit of work.
- Push each meaningful repo-visible commit to GitHub by default when the repo has a configured remote and branch upstream.
- Commit every meaningful repo-visible change by default, not just at the end of a session.
- Treat code, config, behavior, workflow, and collaborator-facing docs changes as commit-worthy when someone reviewing or using the project would need to see them.
- Do not wait to bundle separate meaningful changes together when they can ship as small atomic commits.
- Keep commits atomic and easy to understand.
- Default to `main` unless the user says otherwise.
- Do not stage unrelated files.
- Do not commit private, machine-specific, secret, scratch, cache, log, editor-metadata, or other local-only files unless the user explicitly asks for them.
- Before any push, state exactly which files changed and exactly which files are being published if the publish set is not already obvious from the task.

## Publish Policy
- Publish only files that users or collaborators actually need to use, review, or run the project.
- Keep local-only working files out of the repo unless the user explicitly asks for them.
- Default new GitHub repositories to private unless the user explicitly asks for public visibility.
- If a file is outside the project directory, treat it as excluded unless the user explicitly says to include it.
- If the publish set is ambiguous, stop and list the exact files before pushing.

Never publish these by default:
- external shared context files such as `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md`
- scratch notes, temporary files, caches, logs, or editor metadata
- unrelated files from a parent or sibling repository
- secrets, tokens, credentials, or machine-specific config

Before pushing, report:
- exact changed files
- exact files to be published
- anything intentionally kept local

### Commit Helper
Use the repo-local helper after each meaningful unit:

```bash
bash scripts/codex-commit.sh -m "add codex workflow docs" AGENTS.md docs/queue.md scripts/codex-commit.sh
```

Or let it generate a concise message:

```bash
bash scripts/codex-commit.sh AGENTS.md docs/queue.md
```

Use `--no-push` only when a local-only commit is intentional or the repo does not yet have a working upstream:

```bash
bash scripts/codex-commit.sh --no-push AGENTS.md docs/queue.md
```

Rules:
- Always pass the intended file paths explicitly.
- Messages should be concise, accurate, and human-sounding.
- Prefer a short sentence that says what changed, not a placeholder like `add 3 files`.
- Target roughly 3 to 8 words.
- Avoid random or empty phrasing.
- Default to commit-and-push; use `--no-push` only when a push is impossible or intentionally undesired.

Examples:
- `add auth callback handler`
- `fix pagination edge case`
- `refactor queue parsing`
- `improve settings form validation`
- `document commit defaults across repo docs`
- `update commit helper messaging`

## Docs as Working Memory
- Use `docs/` to store durable project knowledge.
- Update docs when behavior, commands, assumptions, or gotchas change.
- Prefer short high-signal docs over speculative large design docs.
- If a repeated correction happens twice, update this file.

## Failure Handling
- Reproduce before editing when fixing a bug.
- Fix forward when the cause is clear and the blast radius is small.
- If the task grows larger than expected, stop and present options before continuing.
- If a complete clean worktree is impossible because of unrelated existing changes outside this project directory, do not alter those files; report the limitation explicitly.
