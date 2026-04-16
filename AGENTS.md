# AGENTS.md

## Purpose
This file is the repo-local operating manual for Codex in `ghostty-codex-launchpad`.

`AGENTS.md` is the durable repo policy.
If `~/.codex/ghostty-codex-launchpad-shared-context.md` exists, use it as the durable task artifact for the current task. Treat this file as standing repo policy and the shared context file as the current-task record.

Read it at the start of each session.
Follow it unless the user explicitly overrides it.
Keep it current. If the same mistake, correction, or gotcha happens twice, update this file.

## Repo Layout
Current repo-local structure:

- `README.md`: user-facing project overview.
- `AGENTS.md`: repo-operating instructions for Codex.
- `prompts/prompt-source.sh`: canonical prompt source used by the launcher and docs generator.
- `docs/prompt-source.md`: prompt-ownership overview.
- `docs/generated-prompts.md`: generated prompt documentation derived from the canonical prompt source.
- `docs/queue.md`: lightweight work queue and follow-up memory.
- `docs/knowledge.md`: durable reusable user guidance and project facts.
- `docs/role-selection.md`: short role-selection rubric.
- `docs/context-budget.md`: context-budget rules for prompt layering.
- `scripts/render-prompt-docs.sh`: helper that regenerates prompt docs from the canonical prompt source.
- `scripts/check-prompt-drift.sh`: helper that checks launcher prompts against the canonical prompt source and generated docs.
- `scripts/check-commit-helper-doc-map.sh`: helper that checks the documented GitHub repo mapping used by commit-helper auto-discovery.
- `scripts/codex-commit.sh`: helper for staging intended files and committing small atomic changes.
- `git-ghostty-codex-launchpad.sh`: main Ghostty launcher.
- `start-git-ghostty-codex-launchpad.sh`: thin shell wrapper.
- `open-git-ghostty-codex-launchpad.command`: double-clickable macOS launcher.

Do not invent build, test, or runtime commands that are not present in the repo. If new project-specific commands become real, document them here or in `docs/`.

## Core Operating Principles
- Do not restate repo policy in every prompt if `AGENTS.md` already covers it.
- Keep prompts short, concrete, and role-specific.
- Prefer clear ownership over overlapping responsibilities.
- Keep blast radius small.
- Prefer fast forward progress over over-planning.
- Make small atomic commits.
- Publish verified completed work promptly.
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
2. Read `~/.codex/ghostty-codex-launchpad-shared-context.md` if it exists.
3. Read `docs/queue.md`.
4. Inspect the current repo-local files before editing.
5. Check scoped git status for the files you plan to touch, for example `git status --short -- README.md git-ghostty-codex-launchpad.sh` or `git status --short -- .`.

## Shared Context Discipline
- Read `AGENTS.md` first and the shared context file second.
- Do not rewrite the whole shared context file.
- Update only the sections or artifact IDs owned by your role.
- Preserve useful existing content.
- If the artifact is placeholder-only and your role is not `BUILDER`, return `NOT READY` using the shared-context response format and stop.

## Task Targeting
- Work inside the project directory.
- Treat the selected target file as a starting point, not a hard restriction, unless the artifact says otherwise.
- If a typed project name loosely matches an existing project directory, prefer reusing that existing project and its shared context instead of bootstrapping a near-duplicate project or session file.
- If the selected project is missing `AGENTS.md`, the launcher seeds a starter `AGENTS.md` and `docs/queue.md` and targets `AGENTS.md` first.
- Keep scope tight.
- Do not invent unrelated requirements.
- State assumptions as `Q` or `R` items in the artifact when needed.

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

## Role Ownership
- `BUILDER` owns: Goal, Scope, Constraints, initial Success Criteria, initial Invariants, initial Failure Modes, initial Risks / Open Questions, initial Test Mapping, Status.
- `BACKEND` owns: implementation work, implementation notes, criteria coverage notes, implementation assumptions.
- `CRITIC` owns: refined criteria, added risks, added failure modes, verification results, invariant judgments, debugger guidance.
- `DEBUGGER` owns: reproduced failures, likely root cause, fixes applied, criteria rechecked, updated verification results, remaining uncertainty.

## Four-Pane Workflow

### builder
Responsibilities:
- Initialize and refine the artifact so other roles can act without guessing.
- Define the first real success criteria and invariants before implementation.
- If a separate implementation role exists, stop after artifact setup and status update.

### backend
Responsibilities:
- Implement the current highest-value task against the artifact.
- Translate the Builder plan into the minimum scoped code change.
- Keep implementation tied directly to `SC` and `INV` IDs.

### debugger
Responsibilities:
- Start from failed criteria or critic findings.
- Reproduce the smallest real failure loop before editing when practical.
- Make the smallest fix that restores the failed criteria or invariants.

### critic
Responsibilities:
- Refine criteria so they are harder to game and easier to verify.
- Record `PASS`, `FAIL`, or `NOT VERIFIED` judgments tied to the artifact.
- Add only the missing risks, failure modes, and debugger guidance needed to close gaps.

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
- Record verified items and remaining uncertainty in the artifact.
- If validation fails or remains incomplete, do not publish.

## Commit Policy
- Commit every coherent repo-visible non-private change in the same turn. Do not leave those edits uncommitted.
- Publish verified completed work in the same turn when a confident GitHub destination exists. If it does not, still commit locally and report the limitation explicitly.
- Infer publish destination before asking: check remotes, upstream, repo docs, nearby canonical repos, and the authenticated GitHub account. Ask only when the destination is still genuinely ambiguous.
- Treat repo-visible code, config, docs, scripts, and workflow files as commit-worthy by default. Never commit personal, secret, machine-specific, scratch, cache, or other local-only files unless explicitly requested.
- Keep commits atomic, avoid unrelated staging, default to `main`, and do not auto-push partial, failing, or unverified work.

### Commit Helper
Use the repo-local helper after each meaningful unit:

```bash
bash scripts/codex-commit.sh -m "add codex workflow docs" AGENTS.md docs/queue.md scripts/codex-commit.sh
```

Or let it generate a concise message:

```bash
bash scripts/codex-commit.sh AGENTS.md docs/queue.md
```

For successful verified work that should be published immediately:

```bash
bash scripts/codex-commit.sh git-ghostty-codex-launchpad.sh AGENTS.md README.md
```

Rules:
- Always pass the intended file paths explicitly.
- Messages should be concise, accurate, and human-sounding.
- Target roughly 3 to 8 words.
- Avoid random or empty phrasing.
- Default behavior is commit-and-push; use `--no-push` only when push is intentionally undesired or impossible.

Examples:
- `add auth callback handler`
- `fix project search fallback`
- `refactor pane prompt setup`
- `improve launcher error handling`

## Docs as Working Memory
- Use `docs/` to store durable project knowledge.
- Update docs when behavior, commands, assumptions, or gotchas change.
- Prefer short high-signal docs over speculative large design docs.
- If a repeated correction happens twice, update this file.

## Failure Handling
- Reproduce before editing when fixing a bug.
- Fix forward when the cause is clear and the blast radius is small.
- If the task grows larger than expected, stop and present options before continuing.
- If a complete clean worktree is impossible because of unrelated existing changes, do not alter those files; report the limitation explicitly.
