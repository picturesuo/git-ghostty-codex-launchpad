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

Rule: the first mate runs on Codex against the limited Azure API credit; every crewmate runs on `claude` so it bills a Claude Max subscription (YC 5x via `fm-yc`, School 20x via `fm-school`). Use `claude-opus-5` until Claude Code lists `claude-opus-5-5`, then swap.

| Bucket | Model | Effort | Where |
|---|---|---|---|
| Interactive orchestrator (first mate) | gpt-6-astra (`fm-yc --sol` is cheaper) | medium | Azure private credit |
| Interactive orchestrator (second mates) | claude-opus-5 | medium | Claude subscription, `~/firstmate/config/secondmate-harness` |
| Planner (specs, hard bug investigation, scouts) | claude-opus-5 | xhigh | Claude subscription |
| Implementer (well-defined spec, default crew) | claude-opus-5 | medium | Claude subscription |
| Adversarial reviewer | claude-opus-5 (captain may name gpt-6-sol) | xhigh | Claude subscription |
| Premium intelligence, escalations | claude-fable-5-1, or gpt-6-astra | xhigh | reserved for truly ambiguous or creative work and untangling messes |
| Trivial fixer (one-liners, config) | claude-haiku-4-5 (or gpt-6-luna on request) | medium | Claude subscription |

Routing for crew lives in `~/firstmate/config/crew-dispatch.json`; the first mate reads it, scripts never do. `codex-sol` / `codex-luna` remain for ad-hoc GPT-6 runs in any tab.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
Let skills absorb narrow, triggered guidance so this always-loaded file stays compact.
