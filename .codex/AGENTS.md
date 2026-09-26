<!-- >>> mirror of ~/.agents/AGENTS.md (shared with Claude Code). Edit that file, then re-copy this block; do not edit the block here. >>> -->
# global agent instructions

One file for every harness (Claude Code imports it from ~/.claude/CLAUDE.md; ~/.codex/AGENTS.md mirrors it). Modeled on kunchenguid/dotfiles home/AGENTS.md.

- Never use the em dash "—". Use a plain dash "-" instead.
- Never ask for permission confirmations, never re-introduce yourself, skip onboarding talk, pick up where we left off, keep responses concise and direct.
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated.
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.
- Commit each completed, verified change; push only when the user says yes. Auto-commit work at session end.
- If a repository has `AGENTS.md`, read it before editing and follow it as the repo-local operating manual. `CLAUDE.md` holds Claude-specific additions and must not weaken `AGENTS.md`.

## Reasoning effort

Effort is a ceiling, not a floor. It caps how much a model may think; it never forces thinking, so a high setting still answers "hi" instantly.

- `medium` when the task is already well defined, for example implementing a spec a planner produced, and for interactive orchestrators (first mate, second mates) so they stay fast.
- `xhigh` when the task is not yet well defined: planning, investigation, review, design.
- Avoid `low` (latency rarely matters and intermediate context is often still ambiguous). Never `max` (forces thinking on every turn).
- Bigger model = wisdom, higher effort = diligence. Raise the model for problems that need a genius, raise the effort for problems that need a pen and lots of paper, both only when it needs a genius with a pen.
- Do not switch effort mid-session; it usually breaks prompt caching.

## Model line-up (Sept 2026)

Rule: the first mate runs on Codex against the limited Azure API credit; every crewmate runs on `claude` so it bills a Claude Max subscription (YC Max via `fm-yc`, School Enterprise via `fm-school`).

| Bucket | Model | Effort | Where |
|---|---|---|---|
| Interactive orchestrator (first mate) | gpt-6-astra (`fm-yc --sol` is cheaper) | medium | Azure private credit |
| Interactive orchestrator (second mates) | claude-opus-5-5 | medium | Claude subscription, `~/firstmate/config/secondmate-harness` |
| Planner (specs, hard bug investigation, scouts) | claude-opus-5-5 | xhigh | Claude subscription |
| Implementer (well-defined spec, default crew) | claude-opus-5-5 | medium | Claude subscription |
| Adversarial reviewer | claude-opus-5-5 (captain may name gpt-6-sol) | xhigh | Claude subscription |
| Premium intelligence, escalations | claude-fable-5-1, or gpt-6-astra | xhigh | reserved for truly ambiguous or creative work and untangling messes |
| Trivial fixer (one-liners, config) | claude-haiku-4-5 (or gpt-6-luna on request) | medium | Claude subscription |

Routing for crew lives in `~/firstmate/config/crew-dispatch.json`; the first mate reads it, scripts never do. `codex-sol` / `codex-luna` remain for ad-hoc GPT-6 runs in any tab.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
Let skills absorb narrow, triggered guidance so this always-loaded file stays compact.
<!-- <<< end mirror <<< -->

# Codex-specific additions

## Durable Memory (all provider lanes)

Read `/Users/bensuo/.codex/memories/memory_summary.md` at session start; it is
the compacted durable memory of the user's profile, preferences, and operating
rules and applies identically on every provider lane (Azure, OpenAI API, or
ChatGPT auth - memory is local and does not depend on the signed-in account).
For any Penny work, also read `/Users/bensuo/.codex/penny-context.md` - the
compacted import of the Penny vision and relevant Codex history - and treat
`/Users/bensuo/Desktop/penny/VISION.md` as the authoritative full source.

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
- For non-trivial coding, product, architecture, or Penny work in the Codex app,
  use Codex as the main surface only after the Fable sidecar returns a successful,
  task-relevant response. A successful Fable response is a hard prerequisite for
  implementation and judgment calls; never continue the task with Codex alone.
  The default sidecar command is
  `fable-orchestrator` (Company 1 account lane). Automatically fail over through
  `fable-orchestrator` (Company 1), `fable-orchestrator --leg school`,
  `fable-orchestrator-company-2`, and `fable-orchestrator-bedrock` on explicit
  capacity or usage exhaustion, authentication/profile unavailability,
  transport failure, or a bounded no-response/hung invocation. If the user
  explicitly selected a non-Company 1 lane, try it first, then resume the
  Company 1-first order while skipping lanes already attempted for that call.
  Report each lane transition. If every Fable lane fails, is unavailable, or
  reaches the bounded no-response limit, stop before implementation, tell the
  user that Fable is not working, and report each lane's blocker. Do not rotate
  merely because a reviewer found issues or a repo/runtime check failed. Use
  Codex/GPT-6 Sol at medium reasoning as the default implementation workhorse
  (`codex-workhorse`, launcher `codex-sol` on Azure provider azure_astra);
  raise to xhigh only for investigation or review, never max. Use GPT-6 Luna
  (`codex-luna`) for trivial, already-defined edits; it is slow per task but
  extremely cheap. GPT-6 Astra is the premium escalation for ambiguous,
  open-ended, or high-stakes work; do not rotate automatically merely because
  a repo/runtime check failed. Then use `claude-autoreview` (Company 1) or an
  explicit Claude review lane for post-change review and next-goal judgment.
- In zsh, do not use `status` as a variable name, and use arrays for multi-item
  loops; scalar strings do not word-split like bash.
- After non-trivial code edits, use the `$autoreview` skill with Claude Fable at
  low effort as the default closeout review gate before final/commit/ship when
  available. Do not use review panels or additional engines unless the user
  explicitly asks. Treat findings as advisory, verify them in the real code
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
