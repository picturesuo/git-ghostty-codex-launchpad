# AGENTS.md

## Purpose
This file is the repo-local operating manual for Codex in `ghostty-codex-launcher`.

Read it at the start of each session and follow it unless the user explicitly overrides it.
Keep it current. If the same mistake, correction, or gotcha happens twice, update this file.
If `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md` exists, use it as the durable task artifact and session source of truth.

## Prompt Layering
- Keep durable repo policy here.
- Keep current-task state in `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md`.
- Keep per-request prompts minimal.
- Do not repeat workflow or status rules that already live here or in the shared artifact.

## Repo Layout
Current repo-local structure is intentionally small:
- `README.md`: user-facing project documentation
- `AGENTS.md`: repo-operating instructions
- `docs/prompt-source.md`: canonical prompt source
- `docs/generated-prompts.md`: generated prompt doc
- `docs/queue.md`: work queue and follow-up memory
- `scripts/render-prompt-docs.sh`: prompt-doc generator
- `scripts/codex-commit.sh`: scoped commit helper

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
4. Inspect the files you plan to touch.
5. Check scoped git status for those files.

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

## Role Workflow
- `builder`: refine the artifact, define success criteria, and hand off a clear implementation contract.
- `backend`: implement the smallest change that satisfies the artifact and update status.
- `critic`: review for regressions, weak criteria, and missing edge cases with explicit pass/fail/not-verified judgments.
- `debugger`: reproduce first, inspect the smallest loop possible, and fix the identified cause with minimal edits.

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
- Commit after each repo-visible non-private change, even when the change is small.
- Do not leave non-private repo-visible file edits uncommitted at end of turn when they are coherent enough to save.
- Commit every meaningful repo-visible change by default, not just at the end of a session.
- Treat any code, config, docs, script, or workflow file change inside the repo as commit-worthy by default unless it is explicitly personal or local-only.
- Treat code, config, behavior, workflow, and collaborator-facing docs changes as commit-worthy when someone reviewing or using the project would need to see them.
- Do not wait to bundle separate meaningful changes together when they can ship as small atomic commits.
- Keep commits atomic and easy to understand.
- Default to `main` unless the user says otherwise.
- Do not stage unrelated files.
- Do not commit private, machine-specific, secret, scratch, cache, log, editor-metadata, or other local-only files unless the user explicitly asks for them.
- Publish in the same turn by default when the branch already has a configured upstream.
- The current helper only pushes to the configured upstream branch.
- Do not claim the helper can infer a destination from repo docs, canonical repo mapping, nearby repos, remotes, or GitHub account state until that logic exists in `scripts/codex-commit.sh`.
- If no upstream is configured, either configure it first or use `--no-push` for an intentional local-only commit.
- If no GitHub remote or upstream is configured, report that limitation explicitly and do not claim the work is published.
- Do not push to a merely similar or guessed GitHub repo when the repo identity is ambiguous.
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
- Default to commit-and-push when an upstream already exists.
- Use `--no-push` when a push is impossible or intentionally undesired.

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
