# Global AGENTS.md

Global defaults for every Codex repo. Local `AGENTS.md` may add paths, tools,
and exceptions; do not weaken these rules unless the user explicitly changes
them.

## Core Loop

1. Read the smallest task-relevant set: local `AGENTS.md` first, then `README`,
   docs/code, `tools.md`, and matching `skills/*/SKILL.md` only as needed. For
   docs/policy edits run `scripts/docs-list.sh` if present and use
   `$docs-policy-edit` for durable workflow or policy changes. Before splitting
   work, read `docs/multi-agent-workflow.md` if present and use
   `$multi-agent-workflow`.
2. Clarify: if any task-relevant ambiguity remains, ask. Present options and
   tradeoffs; never guess silently or hide confusion.
3. Define done: for non-trivial work, write success criteria and the narrowest
   proof that can fail.
4. Edit: smallest complete change. Match local style. No speculative features,
   abstractions, configurability, future-proofing, or impossible-case handling.
   No adjacent cleanup/refactors unless required.
5. Verify: run the narrow proof plus relevant lint/type/test/build checks when
   feasible. For bugs, prefer a reproducer/regression test before the fix. Say
   exactly what ran, passed, and was skipped.
6. Finish: report changed files, proof, residual risk, and commit/push/PR or
   local-only state.

## Code Rules

- Understand nearby code, patterns, docs, and tests before editing.
- Every changed line must trace to the request, a verified bug, or cleanup from
  this change.
- Remove only orphans your change created. Mention unrelated dead code; do not
  delete it.
- Prefer root-cause fixes, readable code, existing dependencies, existing
  runtime, and repo package manager. New deps need real need plus a health
  check.
- Compatibility shims, aliases, and fallback paths need a real contract: public
  API/CLI/config/data, tagged upgrade path, security boundary, or observed
  production state. Use `$compatibility-contract-audit` for the decision and
  proof. If unsure, ask before keeping them.
- For user-visible behavior changes, update the relevant docs, runbooks, or
  changelog-style notes when they exist.
- Use `rg`/`rg --files` when available. Search exact unfamiliar external errors
  before guessing.
- Avoid repo-wide scripted search/replace. Keep edits small, reviewed, and
  path-scoped.
- If the solution feels overbuilt, shrink it before handoff.

## Git And Public Safety

- Safe git by default: `status`, `diff`, `log`. No destructive ops, branch
  changes, amend, rebase, force-push, deletes, renames, or broad rewrites unless
  asked.
- Never revert unknown changes; assume user/agent work and route around it.
- Auto-commit and push each completed, verified, public-safe repo change. Keep
  secrets, private data, scratch, partial, failing, and unverified work out.
- Prefer focused conventional commits. Split unrelated finished changes; keep
  inseparable files together. Use repo commit helpers with explicit paths when
  present.
- Respect explicit local-only or publish-off instructions.
- Use `gh` for GitHub when available. Confirm repo/account if ambiguous. Use
  `--body-file` for public text. Use `$public-github-publish` for public
  issues, PR bodies, releases, and comments. Never dump tokens/env/secrets;
  name env vars only.
- For public GitHub issue/PR bodies or comments, write the body to a temp file,
  inspect it, then use `gh ... --body-file`. Do not inline shell-sensitive text
  in quoted CLI arguments.
- After pushing landed work, run `git status --short --branch` and verify the
  visible checkout is clean and on the expected branch.

## Tools, Context, Agents

- Prefer repo scripts and package-manager commands; verify non-obvious tools
  exist. Keep logs focused.
- In zsh, do not use `status` as a variable name, and use arrays for multi-item
  loops; scalar strings do not word-split like bash.
- After non-trivial code edits, use the `$autoreview` skill with the default
  Codex-only reviewer as the closeout review gate before final/commit/ship when
  available. Do not use review panels or optional non-Codex engines unless the
  user explicitly asks. Treat findings as advisory, verify them in the real code
  path, fix only in-scope blockers, rerun focused proof after review-triggered
  fixes, and rerun `$autoreview` until no accepted/actionable findings remain or
  scope must be escalated.
- If present, run `scripts/test-launcher.sh` for launcher behavior,
  `scripts/validate-skills.sh` after skill edits, and `scripts/check-shell.sh`
  when `shellcheck` is installed.
- Use `docs/queue.md`, `docs/knowledge.md`, shared context, and nearby docs
  before broad search.
- Around 80% context, save status, decisions, files, proof, and next action to
  shared context if one exists; use `$shared-context-checkpoint` for the
  handoff shape. Do not spend the final 20% on broad edits.
- Split agents only when materially useful. Give goal, write scope, expected
  output. Require files, proof, risks. Use `$multi-agent-workflow` for splits.
  Resolve conflicting assumptions before merging. Use fresh review for
  high-risk, security, or completion claims.

## UI Isolation

- Never take the user's active screen for click-through, browser testing,
  screenshots, or app inspection without explicit current-task foreground
  approval.
- Do not open tabs/windows in the active browser, switch Spaces, move the
  visible cursor, focus apps, click menu/Dock items, or use
  `osascript`/System Events on visible UI without approval.
- Prefer Codex in-app Browser, cmux browser/workspace, offscreen renderers,
  logs, diagnostics, accessibility metadata, isolated screenshots, and
  app-generated artifacts.
- If only foreground UI works, such as a logged-in browser, native app, or
  system dialog, stop and ask.
- `/click` uses the `click-through` skill in an isolated surface. Done requires
  isolated UI evidence or a clear reason it was impossible.
