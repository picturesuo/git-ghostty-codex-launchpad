# Global Codex Instructions

These instructions apply across Codex sessions and repos. Repo-local
`AGENTS.md` files may add project-specific rules, paths, tools, and exceptions,
but keep these global user preferences intact unless the user explicitly
changes them.

Style: concise, direct, small safe diffs. Prefer evidence over guesses.

Source influences:
- Karpathy-style `CLAUDE.md`: think before coding, simplicity first, surgical
  changes, and goal-driven execution.
- Steinberger-style agent scripts: terse durable rules, exact local commands,
  safe git, scoped commits, tool catalogs, skill validation, and no secrets in
  public surfaces.

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
- Read `tools.md` before using repo-local helpers. Prefer exact commands from
  repo docs over guessed commands.
- Read matching skill files for repeated workflows. After editing skills, run
  the repo skill validator when available.

## Think Before Coding

- Before making changes, understand the existing codebase, patterns, naming,
  architecture, docs, and tests relevant to the request.
- State assumptions when they affect the path.
- If any task-relevant ambiguity remains, ask the user questions before acting.
- If multiple interpretations are possible, present the options and tradeoffs
  instead of choosing silently.
- Do not hide confusion. Say what is uncertain, what evidence exists, and what
  decision is needed.
- If a simpler complete approach exists, say so. Push back on unnecessary
  complexity, risky data exposure, brittle architecture, or extra scope.
- Bias toward caution and correctness over speed, while using judgment for
  truly trivial tasks.

## Simplicity First

- Write the minimum code that solves the problem.
- Add no speculative features, abstractions, configurability, or error handling.
- Do not future-proof for requirements the user did not name.
- Prefer direct, readable code over cleverness.
- Do not add a new abstraction unless it removes real duplication or matches an
  existing local pattern.
- If a solution feels overbuilt, make it smaller before handoff.
- If code can be much shorter while staying clear, rewrite it shorter.

## Surgical Changes

- Touch only files required by the current request.
- Follow existing patterns; keep diffs minimal and reviewable.
- Match local style, names, formatting, and ownership boundaries.
- Do not refactor adjacent code unless the change requires it.
- Do not clean up unrelated code, comments, formatting, docs, or config. Mention
  unrelated problems instead of fixing them.
- Every changed line should trace to the request, a verified bug, or cleanup
  caused by your own change.
- Remove orphan imports, variables, functions, files, or comments introduced by
  your own change.
- Never revert unrecognized changes; assume another user or agent made them and
  work around them.
- Avoid repo-wide search-and-replace scripts unless asked.
- If blocked, state what is missing and the next concrete step.

## Goal-Driven Execution

- Convert non-trivial requests into explicit success criteria before editing.
- If the success criteria are weak, vague, or unverifiable, clarify before
  making changes.
- For new behavior, include a validation path for the intended behavior and the
  important invalid or edge case when practical.
- For bugs, prefer a reproducer or failing regression test before the fix.
- For refactors, verify behavior before and after when feasible.
- For multi-step work, maintain a visible checklist and verify each completed
  step before marking it done.
- Do not call the work complete until the stated success criteria pass, critical
  invariants are preserved, and no unresolved high-severity risk remains.

## Verification

- Before handoff, run relevant `lint`, `typecheck`, `tests`, and `build` checks
  when feasible.
- Run the narrowest useful proof that can fail for the change.
- Use `bash scripts/test-launcher.sh` for launcher state, panes, agent
  commands, remote fallback, or prompt rendering when that script exists.
- Run `bash scripts/validate-skills.sh` after editing skills when that script
  exists.
- Run `bash scripts/check-shell.sh` when that script exists and `shellcheck` is
  installed.
- Say exactly what was run, what passed, and what was not run and why.

## Tools And Dependencies

- Prefer repo scripts and package-manager commands before ad hoc shell.
- Do not switch package managers, runtimes, formatters, linters, or major
  tooling unless explicitly asked.
- Verify tools exist before using them when the command is not obvious.
- Use `rg`/`rg --files` for search when available.
- Add new dependencies only when necessary. Prefer standard library or existing
  project dependencies.
- After adding a dependency, run the smallest health check that proves it
  installs, imports, builds, or executes as intended.
- Keep command output and logs focused. Do not paste secrets or large noisy logs
  into docs, issues, PRs, or commits.

## Git And Publish

- Safe git: `git status`, `git diff`, `git log`.
- Check `git status` and `git diff` before edits and before handoff.
- No destructive git, branch changes, deletes, renames, package/runtime/tooling
  swaps, or broad rewrites unless explicitly asked.
- Preserve unrelated user and other-agent changes.
- Commit only private-safe, verified, repo-visible files.
- Keep private, scratch, partial, failing, and unverified work out of commits.
- Prefer focused conventional commits when practical.
- Prefer one commit per finished file by default; group files only when they
  are inseparable, such as source plus generated output.
- Do not amend commits, rebase, force-push, or create/switch branches unless the
  user asks.
- For the `ghostty-codex-launchpad` launcher repo itself, do not push unless the
  user explicitly asks.
- For launched target projects, publish mode `auto` means agents auto-commit
  and auto-push each finished repo-visible non-private file immediately after
  verification.
- Publish mode `off` means local/manual only unless the user asks.
- Use `bash scripts/codex-commit.sh` with explicit paths when that helper is
  available. Use `--no-push` for local-only checkpoints and `--each-path` for
  per-file commits.

## GitHub And Public Text

- Use `gh` for issues, PRs, CI runs, releases, comments, and repo identity when
  available.
- Confirm the active GitHub repo/account before commenting, opening PRs,
  pushing, or releasing when ambiguity is possible.
- Use `--body-file` for public issue, PR, release, or comment bodies when text
  contains shell, environment variables, quotes, or user-provided content.
- Never include tokens, passwords, API keys, private customer data, or raw
  secret-bearing command output in docs, config, commits, issues, PRs, or logs.
- When environment variables matter, name the variable but do not print its
  value.

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
- Use a fresh review context for important diffs, security-sensitive work, and
  high-risk completion claims.

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

## Finish Packet

End substantial work with:
- changed files;
- verification run and result;
- residual risk or unverified area;
- commit, push, PR, or local-only state.
