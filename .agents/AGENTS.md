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
- Across every project and harness, default to validating, committing, and pushing each completed, verified, public-safe change directly to the intended delivery branch without creating a PR or waiting for a separate push request. This is the user-selected delivery default; retain applicable tests, review, and CI checks. Respect protected branches and explicit repository-required PR gates, local-only or publish-off instructions. If direct delivery is unsupported or refused, report the blocker rather than silently creating a PR or bypassing a gate. Never publish secrets, private data, scratch, partial, failing, or unverified work; never force-push or discard work. This does not authorize speculative changes or relax destructive-action or security-sensitive approval boundaries.
- If a repository has `AGENTS.md`, read it before editing and follow it as the repo-local operating manual. `CLAUDE.md` holds Claude-specific additions and must not weaken `AGENTS.md`.
- At task completion, automatically retire only the agent-created worker sessions, terminal panes/tabs, temporary workspaces/worktrees, browser test surfaces, and processes owned by that task after proving work is safely delivered and no live validation, unresolved decision, or unlanded change still depends on them. Use the owning tool's guarded teardown, preserve deliverables and durable handoff evidence, and never force cleanup or close the user's primary session, unrelated work, or another installation. Report a refused cleanup once and keep it pending; do not leave finished worker surfaces cluttering the workspace.

## Computer use - all projects

- Run computer use in the background by default across every project and harness. Use headless browsers, hidden or isolated browser surfaces, offscreen rendering, or app APIs/CLIs that do not disturb the active desktop.
- Never take over the user's active screen, browser, keyboard, or visible cursor: do not focus apps, switch Spaces, open or navigate visible tabs/windows, or operate visible menus or dialogs unless the user explicitly requests foreground interaction for the current task. A request to browse, click through, test, or use a computer is not foreground approval.
- A separate browser profile, window, workspace, or session is not sufficient isolation if it becomes visible, steals focus, or affects the user's input. Verify the chosen surface is actually non-interfering before operating it.
- If the task requires foreground-only UI, report that limitation and ask one concise question rather than silently taking over. Background execution does not expand permission to send messages, publish, purchase, or perform destructive actions.

## Reasoning effort

Effort is a ceiling, not a floor. It caps how much a model may think; it never forces thinking, so a high setting still answers "hi" instantly.

- `medium` when the task is already well defined, for example implementing a spec a planner produced, and for interactive orchestrators (first mate, second mates) so they stay fast.
- `xhigh` when the task is not yet well defined: planning, investigation, review, design.
- Avoid `low` (latency rarely matters and intermediate context is often still ambiguous). Never `max` (forces thinking on every turn).
- Bigger model = wisdom, higher effort = diligence. Raise the model for problems that need a genius, raise the effort for problems that need a pen and lots of paper, both only when it needs a genius with a pen.
- Do not switch effort mid-session; it usually breaks prompt caching.

## Model line-up (Oct 2026)

Rule: the first mate runs on Codex against the limited Azure API credit; every crewmate runs on `claude` so it bills a Claude Max subscription (YC Max via `fm-yc`, School Enterprise via `fm-school`).

| Bucket | Model | Effort | Where |
|---|---|---|---|
| Interactive orchestrator (first mate) | gpt-6.1-sol (`fm-yc --astra` for GPT-6 Astra at about 5x the price) | medium | Azure private credit |
| Interactive orchestrator (second mates) | claude-opus-5-5 | medium | Claude subscription, `~/firstmate/config/secondmate-harness` |
| Planner (specs, hard bug investigation, scouts) | claude-opus-5-5 | xhigh | Claude subscription |
| Implementer (well-defined spec, default crew) | claude-opus-5-5 | medium | Claude subscription |
| Small well-specified change (stated-root-cause fix, contained feature, tests, docs) | claude-sonnet-5-5 | medium | Claude subscription |
| Adversarial reviewer | claude-opus-5-5 (captain may name gpt-6.1-sol for a different family) | xhigh | Claude subscription |
| Premium intelligence, escalations | claude-fable-5-1, or gpt-6-astra | xhigh | reserved for truly ambiguous or creative work and untangling messes |
| Trivial fixer (one-liners, config) | claude-haiku-4-5 (or gpt-6-luna on request) | medium | Claude subscription |

Routing for crew lives in each installation's `config/crew-dispatch.json` (identical copies in `~/firstmate` and every `~/firstmate-<project>`); the first mate reads it, scripts never do, and `data/captain.md` must never override it. Crewmates are ephemeral: retire each one when its task ends. `codex-sol` / `codex-luna` remain for ad-hoc GPT-6 runs in any tab.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
Let skills absorb narrow, triggered guidance so this always-loaded file stays compact.
