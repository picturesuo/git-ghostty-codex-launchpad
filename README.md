# git-ghostty-codex-launchpad

A macOS Ghostty launcher that opens a ready-to-work Codex, Claude, or mixed-agent setup with multiple panes, role-based prompts, and a built-in Git publish handoff.

## Why This Matters

Starting a coding session usually involves repetitive setup: opening terminals, finding the project, creating context, and getting each agent into the right role. This project compresses that startup work into one launcher so the workflow is consistent every time.

`ghostty-codex-launchpad` is the canonical repo for ongoing work. The duplicate `ghostty-codex-launcher` folder was the wrong place to keep evolving the project because the real launcher code and workflow engine already live here.
GitHub repo: `picturesuo/git-ghostty-codex-launchpad`.

## What It Does

- Opens a fresh Ghostty window and splits it into a configurable 1-8 agent panes, defaulting to the last used count or four panes
- Prompts for the project you want to work on and tries to find it locally, then asks you to confirm close matches before launching
- Reuses an existing project and shared-context file when the typed project name is only a close match, instead of creating a near-duplicate session by name alone
- Writes a shared session note in `~/.codex/` and preserves it across relaunches
- Starts Codex, Claude, or mixed panes without sending `/fast`, passing the role prompt at launch time instead of pasting it into a live shell later
- Surfaces a compact session snapshot in the launcher title and prompt with the project, branch, dirty state, task artifact, phase, queue, and knowledge-path context so the panes can resume faster
- Sets each pane title directly through Ghostty actions with the project, branch, dirty state, active role, active task artifact, phase, queue-now task, context budget, and session ID, and refreshes matching open launcher terminals for the same project when a session or watcher opens
- Keeps the prompt source as the canonical control surface for the launcher wrapper, role prompts, and push-helper guidance, while the launcher injects only the minimum live context
- Drops role-specific prompts into panes in a predictable order so the work starts with clear responsibility boundaries
- Prompts once for the git remote path and GitHub repo name, prefilled from the last launch or repo config when available, and lets brand-new local projects continue with those fields blank until a remote exists
- Seeds a bootstrap shared task artifact so all active panes start from usable context instead of `TBD` placeholders
- Seeds a lightweight `docs/knowledge.md` file so reusable user guidance and durable project facts have one searchable repo-local home
- Prompts the roles to auto-push coherent repo-visible changes through one shared Git helper, one file at a time when work moves across files and publish mode is `auto`
- Records the last launch state so `--resume-last` can reopen the same project and shared artifact, and `--status-last` can show what was happening without shifting blank saved-state fields
- Can open a live watcher window with `--watch` or `--watch-command` so build and test output stays visible without manual reruns
- Bootstraps missing project `AGENTS.md` and `docs/queue.md` files for both new and existing projects before the role prompts are sent
- Bootstraps `CLAUDE.md`, `docs/agent-workflow.md`, and Claude command/settings scaffolding for target projects without copying long policy text into every agent file
- Offers `--doctor` to check Ghostty, `osascript`, Codex, Claude, git, GitHub CLI, shellcheck, prompt drift, doc-map integrity, and saved-state coherence

The default visible left-to-right pane order is:

1. `BUILDER` - defines the first real task artifact, scope, constraints, success criteria, and invariants before implementation
2. `BACKEND` - does most of the implementation work, mapped directly to the artifact criteria and constraints
3. `DEBUGGER` - maps failures back to specific criteria or invariants and applies the minimum fix
4. `CRITIC` - pressure-tests the artifact, adds risk and failure coverage, acts as the verification gate, and records targeted coaching guidance from recurring weak spots

Extra panes repeat the same role types with suffixes. The fifth pane is `BACKEND-2`, which is the best default extra role because parallel implementation capacity is usually the first useful expansion. The documented base role set remains `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`.

## Workflow

All active panes are expected to use the same shared task artifact in `~/.codex/...-shared-context.md`, and existing task state should survive relaunches.
Durable repo policy belongs in `AGENTS.md`; the shared context should carry the current task artifact and status instead of duplicating the full workflow contract.
Long-running panes should update the shared context and compact or reset around 80% context used. The final 20% of the context window is for finishing tiny active commands, not broad planning or multi-file work.

Prompt source is no longer documented inline in `README.md`.
Canonical prompt source lives in [prompts/prompt-source.sh](/Users/bensuo/ghostty-codex-launchpad/prompts/prompt-source.sh), with generated docs in [docs/generated-prompts.md](/Users/bensuo/ghostty-codex-launchpad/docs/generated-prompts.md).
Use the generated [docs/role-selection.md](/Users/bensuo/ghostty-codex-launchpad/docs/role-selection.md) for the short role rubric and [docs/context-budget.md](/Users/bensuo/ghostty-codex-launchpad/docs/context-budget.md) for the context-budget rules.
Use [scripts/docs-list.sh](/Users/bensuo/ghostty-codex-launchpad/scripts/docs-list.sh) before docs-heavy or workflow-heavy edits so the repo can surface `summary` and `read_when` hints for the current docs set.
Use [scripts/check-prompt-drift.sh](/Users/bensuo/ghostty-codex-launchpad/scripts/check-prompt-drift.sh) to detect drift between the launcher, prompt source, and generated prompt docs.
Use [scripts/check-commit-helper-doc-map.sh](/Users/bensuo/ghostty-codex-launchpad/scripts/check-commit-helper-doc-map.sh) to verify the repo-doc GitHub mapping that helper auto-discovery relies on.

The workflow rules are:

- Do not use `/fast` as part of launch or normal role behavior.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- Once a task meets that completion bar and publish mode is `auto`, the workflow automatically publishes the intended repo-visible files with the launcher-provided shared helper, which commits first and then pushes. Private, personal, scratch, and other local-only files stay out of that default path. If the work moves from one file to another, each completed repo-visible file gets its own short commit message and push before the next file starts.
- The helper prefers an existing upstream. When the selected project already has remote context to work from, it uses that remote and `git push -u` when it needs to establish the branch tracking setup.
- If no remote is configured, the helper can use launcher-provided `GIT_REMOTE_PATH` or `GITHUB_REPO_SLUG` context, then falls back to documented repo mapping when available.
- It refuses to push from a detached `HEAD` and fails fast if the selected project has no safe remote context.
- If the selected project is missing `AGENTS.md`, the launcher seeds a starter `AGENTS.md` and `docs/queue.md` and targets `AGENTS.md` first so the Builder has concrete bootstrap work.
- Durable reusable knowledge belongs in `docs/knowledge.md`, while the shared context file carries current-task state and active handoff notes.
- `--resume-last` reopens the last saved project session even if remote metadata is still blank, `--status-last` prints the last saved launch summary, and `--watch` opens a live state watcher for the current project.
- The workflow should search `docs/knowledge.md`, the shared context, and nearby repo docs first; use broader search only when local context is insufficient.
- Docs under `docs/` should keep short `summary` and `read_when` front matter so the docs index can point the next agent at the right references quickly.
- Use stable IDs like `SC1`, `INV1`, `FM1`, `R1`, `Q1`, and `F1` so handoffs stay traceable.

Bootstrap behavior:

- A fresh shared-context file starts with a usable bootstrap artifact instead of all-`TBD` sections.
- A fresh project bootstrap also seeds `docs/knowledge.md` so user-provided knowledge and durable facts can be reused across later tasks with simple local search.
- `BUILDER` should still refine that bootstrap artifact into task-specific criteria once the user gives a concrete request.
- The other roles should refine the minimum sections they need when the user explicitly redirects them, rather than stopping at `NOT READY`.
- `BACKEND` owns the first slice of knowledge ingest and retrieval, while `CRITIC` keeps the existing pressure-testing role and adds targeted coaching notes from observed weak points.
- The launcher prompt wrapper stays intentionally short and relies on `AGENTS.md` plus the shared artifact for the rest of the durable workflow context.

## Repo Guidance Layers

The repo now splits guidance by purpose instead of keeping everything in one file:

- [AGENTS.md](/Users/bensuo/ghostty-codex-launchpad/AGENTS.md) holds durable repo policy.
- [tools.md](/Users/bensuo/ghostty-codex-launchpad/tools.md) lists repo-local commands and safe examples.
- [skills/](/Users/bensuo/ghostty-codex-launchpad/skills) holds specialist workflows for repeated tasks.
- [docs/](/Users/bensuo/ghostty-codex-launchpad/docs) holds workflow docs, durable notes, and generated references.
- The shared context file in `~/.codex/` still carries current task state and role-owned handoff notes.

Use the smallest layer that fits the task: durable policy in `AGENTS.md`, real commands in `tools.md`, repeatable procedures in `skills/`, and task-local state in the shared artifact.

## Common Use Cases

### Index Docs Before Editing Policy Or Workflow Text

Run:

```bash
bash scripts/docs-list.sh
```

Use this when:
- editing `AGENTS.md`, `README.md`, `docs/knowledge.md`, `docs/queue.md`, or other docs-heavy workflow text
- deciding which docs to read first from their `summary` and `read_when` front matter

Docs under `docs/` now use short front matter like:

```yaml
---
summary: One-line description of the document.
read_when:
  - Situations where this doc should be read first.
---
```

### Look Up Real Repo Commands

Read [tools.md](/Users/bensuo/ghostty-codex-launchpad/tools.md) when you need an existing command instead of guessing.

Typical commands:

```bash
bash scripts/docs-list.sh
bash scripts/render-prompt-docs.sh
bash scripts/codex-commit.sh --no-push README.md
gh pr view --comments
```

Use this when:
- finding the right helper for docs, prompt generation, verification, commits, launcher state, or GitHub review work

### Use Specialist Skills For Repeated Work

The repo now has small specialist guides under [skills/](/Users/bensuo/ghostty-codex-launchpad/skills):

- [skills/prompt-doc-sync/SKILL.md](/Users/bensuo/ghostty-codex-launchpad/skills/prompt-doc-sync/SKILL.md) for prompt-source edits and generated prompt docs
- [skills/scoped-commit-flow/SKILL.md](/Users/bensuo/ghostty-codex-launchpad/skills/scoped-commit-flow/SKILL.md) for small scoped commits and optional pushes
- [skills/repo-doc-policy-edit/SKILL.md](/Users/bensuo/ghostty-codex-launchpad/skills/repo-doc-policy-edit/SKILL.md) for coordinated repo-policy edits
- [skills/pr-feedback/SKILL.md](/Users/bensuo/ghostty-codex-launchpad/skills/pr-feedback/SKILL.md) for pull-request comment workflows

Use this when:
- a task repeats often enough that the same read/check/edit flow would otherwise be reinvented each time

### Sync Prompt Docs After Prompt Changes

Run:

```bash
bash scripts/render-prompt-docs.sh
bash scripts/check-prompt-drift.sh
```

Use this when:
- editing `prompts/prompt-source.sh`
- changing role prompts, wrapper text, or generated role-selection guidance

### Make Small Scoped Commits

For a local-only checkpoint:

```bash
bash scripts/codex-commit.sh --no-push README.md
```

For one commit per file:

```bash
bash scripts/codex-commit.sh --each-path --no-push AGENTS.md tools.md
```

Use this when:
- you want one commit per meaningful subtask
- you want one commit per finished file
- you want one commit per logical change spanning a few files

If you want the finished chunk published to GitHub, drop `--no-push`.

### Handle GitHub PR Feedback

Read [docs/pr-feedback.md](/Users/bensuo/ghostty-codex-launchpad/docs/pr-feedback.md) when review comments drive the task.

Typical commands:

```bash
gh pr view --comments
gh pr diff
gh run list --limit 10
```

Use this when:
- summarizing reviewer requests
- grouping actionable fixes
- preparing replies that say what changed, where it changed, and what was verified

### Coordinate Multiple Agents

Read [docs/multi-agent-workflow.md](/Users/bensuo/ghostty-codex-launchpad/docs/multi-agent-workflow.md) before splitting work across panes, agents, or persistent terminals.

Use this when:
- one agent can implement while another validates or updates docs
- you want long-running watchers, logs, or debugging sessions to stay visible in a dedicated pane or `tmux`

### Reuse Policy Across Repos

Read [docs/repo-layering.md](/Users/bensuo/ghostty-codex-launchpad/docs/repo-layering.md) when bootstrapping `AGENTS.md` in other repos.

Use this when:
- you want one canonical/shared guardrail source
- you want tiny repo-local `AGENTS.md` files with only local additions

## Publishing Defaults

This launcher repo does not push unless the user explicitly asks. When the user does ask, publish each completed file separately when that is the requested workflow.

Launched target projects use publish mode:

- `--publish-mode auto` lets panes auto-commit and auto-push coherent repo-visible file changes while keeping private, personal, scratch, and other local-only files out of the default publish path.
- `--publish-mode off` keeps commits and pushes manual unless the user explicitly asks.

When target-project work moves from one file to another in publish mode `auto`, publish each completed file separately with its own short commit message and push before starting the next file. Use `scripts/codex-commit.sh --each-path` for that file-by-file publish flow.

Completed work should be published in the same turn with the shared helper in `scripts/codex-commit.sh`.
The launcher collects the git remote path and GitHub repo name up front so every pane shares the same publish target.
The helper commits first, then pushes, prefers an existing upstream when available, and can add a launcher-provided remote when a target project has none.
If the helper cannot resolve a safe push target or the branch is detached, it fails clearly; the launcher should stop there and fix the remote or branch setup before any further file work.

When destination is unclear, the workflow should first check git remotes and existing upstreams. If no safe destination exists, it should fail clearly and fix the repository setup instead of inventing a local-only path.
## Files

- `git-ghostty-codex-launchpad.sh` - main launcher
- `start-git-ghostty-codex-launchpad.sh` - thin shell wrapper
- `open-git-ghostty-codex-launchpad.command` - double-clickable macOS launcher

## How To Use It

Run the launcher from Terminal, or double-click the `.command` file from Finder.
Useful command-line modes:

- `bash git-ghostty-codex-launchpad.sh --resume-last`
- `bash git-ghostty-codex-launchpad.sh --status-last`
- `bash git-ghostty-codex-launchpad.sh --doctor`
- `bash git-ghostty-codex-launchpad.sh --agent claude --panes 5`
- `bash git-ghostty-codex-launchpad.sh --agent mixed --panes 6 --publish-mode auto`
- `bash git-ghostty-codex-launchpad.sh --watch-command "npm test -- --watch"`

## Notes

- macOS-only because it depends on `osascript`
- Ghostty-only because it talks directly to the Ghostty app
- Designed for a personal local workflow rather than a shared service

## Verify

If you want a quick sanity check, run `bash scripts/test-launcher.sh`, `bash scripts/check-prompt-drift.sh`, and `bash git-ghostty-codex-launchpad.sh --doctor`.
Run `bash scripts/check-shell.sh` when `shellcheck` is installed.
