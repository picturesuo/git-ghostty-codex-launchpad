# git-ghostty-codex-launchpad

A macOS Ghostty launcher that opens a ready-to-work Codex setup with multiple panes, role-based prompts, and a built-in Git push handoff.

## Why This Matters

Starting a coding session usually involves repetitive setup: opening terminals, finding the project, creating context, and getting each agent into the right role. This project compresses that startup work into one launcher so the workflow is consistent every time.

`ghostty-codex-launchpad` is the canonical repo for ongoing work. The duplicate `ghostty-codex-launcher` folder was the wrong place to keep evolving the project because the real launcher code and workflow engine already live here.
GitHub repo: `picturesuo/git-ghostty-codex-launchpad`.

## What It Does

- Opens a fresh Ghostty window and splits it into four panes
- Prompts for the project you want to work on and tries to find it locally, then asks you to confirm close matches before launching
- Reuses an existing project and shared-context file when the typed project name is only a close match, instead of creating a near-duplicate session by name alone
- Writes a shared session note in `~/.codex/` and preserves it across relaunches
- Starts Codex in each pane without sending `/fast`, passing the role prompt at launch time instead of pasting it into a live shell later
- Surfaces a compact session snapshot in the launcher title and prompt with the project, branch, dirty state, task artifact, phase, queue, and knowledge-path context so the panes can resume faster
- Sets each pane title with the project, branch, dirty state, active role, active task artifact, phase, queue-now task, context budget, and session ID so interrupted sessions are easier to resume
- Keeps the prompt source as the canonical control surface for the launcher wrapper, role prompts, and push-helper guidance, while the launcher injects only the minimum live context
- Drops four different Codex roles into the panes in a fixed left-to-right order so the work starts with a clear split of responsibilities
- Prompts once for the git remote path and GitHub repo name, prefilled from the last launch or repo config when available, then threads those values into all four panes and the shared session context
- Seeds a bootstrap shared task artifact so all four panes start from usable context instead of `TBD` placeholders
- Seeds a lightweight `docs/knowledge.md` file so reusable user guidance and durable project facts have one searchable repo-local home
- Prompts the roles to auto-push coherent repo-visible changes through one shared Git helper, one file at a time when work moves across files
- Records the last launch state so `--resume-last` can reopen the same project and shared artifact, and `--status-last` can show what was happening
- Can open a live watcher window with `--watch` or `--watch-command` so build and test output stays visible without manual reruns
- Bootstraps missing project `AGENTS.md` and `docs/queue.md` files for both new and existing projects before the role prompts are sent

The visible left-to-right pane order is:

1. `BUILDER` - defines the first real task artifact, scope, constraints, success criteria, and invariants before implementation
2. `BACKEND` - does most of the implementation work, mapped directly to the artifact criteria and constraints
3. `DEBUGGER` - maps failures back to specific criteria or invariants and applies the minimum fix
4. `CRITIC` - pressure-tests the artifact, adds risk and failure coverage, acts as the verification gate, and records targeted coaching guidance from recurring weak spots

The documented role set is only `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`.

## Workflow

All four panes are expected to use the same shared task artifact in `~/.codex/...-shared-context.md`, and existing task state should survive relaunches.
Durable repo policy belongs in `AGENTS.md`; the shared context should carry the current task artifact and status instead of duplicating the full workflow contract.

Prompt source is no longer documented inline in `README.md`.
Canonical prompt source lives in [prompts/prompt-source.sh](/Users/bensuo/ghostty-codex-launchpad/prompts/prompt-source.sh), with generated docs in [docs/generated-prompts.md](/Users/bensuo/ghostty-codex-launchpad/docs/generated-prompts.md).
Use the generated [docs/role-selection.md](/Users/bensuo/ghostty-codex-launchpad/docs/role-selection.md) for the short role rubric and [docs/context-budget.md](/Users/bensuo/ghostty-codex-launchpad/docs/context-budget.md) for the context-budget rules.
Use [scripts/check-prompt-drift.sh](/Users/bensuo/ghostty-codex-launchpad/scripts/check-prompt-drift.sh) to detect drift between the launcher, prompt source, and generated prompt docs.
Use [scripts/check-commit-helper-doc-map.sh](/Users/bensuo/ghostty-codex-launchpad/scripts/check-commit-helper-doc-map.sh) to verify the repo-doc GitHub mapping that helper auto-discovery relies on.

The workflow rules are:

- Do not use `/fast` as part of launch or normal role behavior.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- Once a task meets that completion bar, the workflow is expected to publish the intended files with the launcher-provided shared helper, which commits first and then pushes by default. If the work moves from one file to another, each file gets its own commit and push before the next file starts.
- The helper prefers an existing upstream. When the selected project already has remote context to work from, it uses that remote and `git push -u` when it needs to establish the branch tracking setup.
- It refuses to push from a detached `HEAD` and fails fast if the selected project has no git remote context or cannot resolve a safe destination from existing remotes.
- If the selected project is missing `AGENTS.md`, the launcher seeds a starter `AGENTS.md` and `docs/queue.md` and targets `AGENTS.md` first so the Builder has concrete bootstrap work.
- Durable reusable knowledge belongs in `docs/knowledge.md`, while the shared context file carries current-task state and active handoff notes.
- `--resume-last` reopens the last saved project session, `--status-last` prints the last saved launch summary, and `--watch` opens a live state watcher for the current project.
- The workflow should search `docs/knowledge.md`, the shared context, and nearby repo docs first; use broader search only when local context is insufficient.
- Use stable IDs like `SC1`, `INV1`, `FM1`, `R1`, `Q1`, and `F1` so handoffs stay traceable.

Bootstrap behavior:

- A fresh shared-context file starts with a usable bootstrap artifact instead of all-`TBD` sections.
- A fresh project bootstrap also seeds `docs/knowledge.md` so user-provided knowledge and durable facts can be reused across later tasks with simple local search.
- `BUILDER` should still refine that bootstrap artifact into task-specific criteria once the user gives a concrete request.
- The other roles should refine the minimum sections they need when the user explicitly redirects them, rather than stopping at `NOT READY`.
- `BACKEND` owns the first slice of knowledge ingest and retrieval, while `CRITIC` keeps the existing pressure-testing role and adds targeted coaching notes from observed weak points.
- The launcher prompt wrapper stays intentionally short and relies on `AGENTS.md` plus the shared artifact for the rest of the durable workflow context.

## Publishing Defaults

This repo should auto-push coherent non-private repo-visible file changes by default.
When the work moves from one file to another, publish each completed file separately with its own commit message and push.
Use `scripts/codex-commit.sh --each-path` for that file-by-file publish flow.

Verified completed work should be published in the same turn by default with the shared helper in `scripts/codex-commit.sh`.
The launcher collects the git remote path and GitHub repo name up front so every pane shares the same publish target.
The helper commits first, then pushes by default, prefers an existing upstream when available, and fails clearly if the selected project has no safe existing remote context.
If the helper cannot resolve a safe push target or the branch is detached, it fails clearly; use `--no-push` only for an intentional local-only commit.

When destination is unclear, the workflow should first check git remotes and existing upstreams. If no safe destination exists, it should fail clearly and ask for a remote or `--no-push` instead of inventing one.
## Files

- `git-ghostty-codex-launchpad.sh` - main launcher
- `start-git-ghostty-codex-launchpad.sh` - thin shell wrapper
- `open-git-ghostty-codex-launchpad.command` - double-clickable macOS launcher

## How To Use It

Run the launcher from Terminal, or double-click the `.command` file from Finder.
Useful command-line modes:

- `bash git-ghostty-codex-launchpad.sh --resume-last`
- `bash git-ghostty-codex-launchpad.sh --status-last`
- `bash git-ghostty-codex-launchpad.sh --watch-command "npm test -- --watch"`

## Notes

- macOS-only because it depends on `osascript`
- Ghostty-only because it talks directly to the Ghostty app
- Designed for a personal local workflow rather than a shared service

## Verify

Run `bash scripts/check-shell.sh` for shell sanity checks and `bash scripts/check-prompt-drift.sh` to verify prompt docs stay in sync.
