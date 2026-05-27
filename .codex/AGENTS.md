# Global AGENTS.md

Global defaults for every Codex repo. Local `AGENTS.md` may add paths, tools,
and exceptions; do not weaken these rules unless the user explicitly changes
them.

## Core Loop

1. Read the smallest task-relevant set: local `AGENTS.md` first, then `README`,
   docs/code, `tools.md`, and matching `skills/*/SKILL.md` only as needed. For
   docs/policy edits run `scripts/docs-list.sh` if present. Before splitting
   work, read `docs/multi-agent-workflow.md` if present.
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
- Use `rg`/`rg --files` when available. Search exact unfamiliar external errors
  before guessing.
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
  `--body-file` for public text. Never dump tokens/env/secrets; name env vars
  only.

## Tools, Context, Agents

- Prefer repo scripts and package-manager commands; verify non-obvious tools
  exist. Keep logs focused.
- If present, run `scripts/test-launcher.sh` for launcher behavior,
  `scripts/validate-skills.sh` after skill edits, and `scripts/check-shell.sh`
  when `shellcheck` is installed.
- Use `docs/queue.md`, `docs/knowledge.md`, shared context, and nearby docs
  before broad search.
- Around 80% context, save status, decisions, files, proof, and next action to
  shared context if one exists. Do not spend the final 20% on broad edits.
- Split agents only when materially useful. Give goal, write scope, expected
  output. Require files, proof, risks. Resolve conflicting assumptions before
  merging. Use fresh review for high-risk, security, or completion claims.

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
