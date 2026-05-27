# Global Codex Instructions

These instructions apply across Codex sessions and repos. Repo-local
`AGENTS.md` files may add project-specific rules, paths, tools, and exceptions,
but keep these global user preferences intact unless the user explicitly
changes them.

Style: concise, direct, small safe diffs. Prefer evidence over guesses.

## Read First

- Read relevant docs and nearby code before editing.
- Read the repo-local `AGENTS.md` first when present.
- Read `README.md`, `docs/agent-workflow.md`, `docs/queue.md`,
  `docs/knowledge.md`, `tools.md`, and relevant `skills/*/SKILL.md` files when
  they exist and fit the task.
- Run `bash scripts/docs-list.sh` before docs-heavy, policy-heavy, or
  workflow-heavy edits when that script exists.
- Read `docs/multi-agent-workflow.md` before splitting work across agents,
  panes, or persistent terminals when that doc exists.

## Safety

- Safe git: `git status`, `git diff`, `git log`.
- No destructive git, branch changes, deletes, renames, package/runtime/tooling
  swaps, or broad rewrites unless explicitly asked.
- Never revert unrecognized changes; assume another user or agent made them and
  work around them.
- Search exact external or unfamiliar error text before guessing.
- State assumptions when they affect the path.
- Ask when ambiguity changes scope, data exposure, architecture, or publish
  behavior.

## Work

- Follow existing patterns; keep diffs minimal and reviewable.
- Prefer the simplest complete fix.
- Do not add speculative features, abstractions, configurability, or error
  handling.
- Every changed line should trace to the request, a verified bug, or cleanup
  caused by your own change.
- Fix root causes when practical.
- Add focused regression coverage when changing behavior or fixing bugs.
- Update docs/comments when behavior, commands, or workflows change.
- Prefer readability over cleverness.
- Avoid repo-wide search-and-replace scripts unless asked.
- If blocked, state what is missing and the next concrete step.

## Verification

- Before handoff, run relevant `lint`, `typecheck`, `tests`, and `build` checks
  when feasible.
- Define success criteria for non-trivial work and loop until the matching
  checks pass or are explicitly blocked.
- Use `bash scripts/test-launcher.sh` for launcher state, panes, agent
  commands, remote fallback, or prompt rendering when that script exists.
- Run `bash scripts/validate-skills.sh` after editing skills when that script
  exists.
- Run `bash scripts/check-shell.sh` when that script exists and `shellcheck` is
  installed.
- Say exactly what was not run and why.

## Git And Publish

- Check `git status` and `git diff` before edits and before handoff.
- Preserve unrelated user and other-agent changes.
- Commit only private-safe, verified, repo-visible files.
- Keep private, scratch, partial, failing, and unverified work out of commits.
- Prefer the most commits that stay coherent: one commit per finished file by
  default; group files only when they are inseparable, such as source plus
  generated output.
- For the `ghostty-codex-launchpad` launcher repo itself, do not push unless the
  user explicitly asks.
- For launched target projects, publish mode `auto` means agents auto-commit
  and auto-push each finished repo-visible non-private file immediately after
  verification.
- Publish mode `off` means local/manual only unless the user asks.
- Use `bash scripts/codex-commit.sh` with explicit paths when that helper is
  available. Use `--no-push` for local-only checkpoints and `--each-path` for
  per-file commits.

## Context

- Treat about 80% context used as the reset point.
- Before compacting or starting fresh, write status, decisions, changed files,
  verification, and next action to the shared context file when one exists.
- Use `docs/queue.md`, `docs/knowledge.md`, the shared context, and nearby repo
  docs before broader search.
- Do not spend the final 20% of context on broad planning or multi-file edits.

## Multi-Agent Work

- Split work only when multiple agents materially help.
- Keep ownership narrow when multiple panes or agents are active.
- Use one agent per task or concern, with a clear goal, write scope, and
  expected output.
- Ask agents to report changed files, verification run, and open risks.
- If two agents discover conflicting assumptions, stop and resolve the conflict
  before merging their changes.

## Non-Interrupting UI Work

- Do not take over the user's active screen for click-through, browser testing,
  UI verification, screenshots, or app inspection unless the user explicitly
  approves foreground control for the current task.
- Do not open tabs or windows in the user's active browser for automated
  click-through work.
- Do not switch macOS Spaces, move the visible cursor, focus apps, click
  menu-bar items, click Dock items, or use System Events/`osascript` to operate
  visible UI unless foreground control was explicitly approved for the current
  task.
- Prefer isolated automation surfaces: Codex in-app Browser, cmux browser or
  workspace surfaces, offscreen renderers, logs, diagnostics, accessibility
  metadata, screenshots from isolated browser surfaces, and app-generated
  artifacts.
- If a task truly requires the user's logged-in browser session, a native app,
  a system dialog, or other foreground-only UI, stop and ask before proceeding.

## Click-Through Default

For `/click`, "click through", manual UI testing, or similar requests, use the
`click-through` skill and keep the run isolated from the user's active desktop.
Completion requires UI evidence from the isolated surface or a clear statement
that non-interrupting verification was not possible.
