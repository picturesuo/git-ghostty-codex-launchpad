---
summary: Shared workflow rules for Codex and Claude sessions launched from this repo.
read_when:
  - You are changing AGENTS.md, CLAUDE.md, or target-project bootstrap instructions.
  - You need the agent-neutral context reset and publish policy.
---

# Agent Workflow

This is the shared workflow source for agent sessions. Keep agent-specific files short and point here instead of copying this policy into multiple places.

## Context Reset

- Treat about 80% context used as the reset point.
- Before compacting or starting a fresh pane, update the shared context file with status, decisions, changed files, verification, and next action.
- Codex should compact or start a fresh launcher pane after updating the shared context.
- Claude should use `/compact` after updating the shared context.
- Do not spend the final 20% of context on broad planning or multi-file edits.

## Publish Policy

- This launcher repo does not push unless the user explicitly asks.
- Launched target projects may auto-commit and auto-push only when publish mode is `auto`.
- Publish mode `auto` means each completed repo-visible file should be committed and pushed before work moves to the next file.
- Publish mode `off` means no push without an explicit user request.
- Private, personal, scratch, partial, failing, and unverified work stays out of the default publish path.

## Multi-Agent Shape

- The base role set is `BUILDER`, `BACKEND`, `DEBUGGER`, and `CRITIC`.
- Extra panes repeat the base roles; the fifth pane is `BACKEND-2`.
- Keep ownership narrow when multiple panes are active.
- Use the shared context, `docs/queue.md`, and `docs/knowledge.md` before broader search.

## Decision Discipline

- State assumptions when they affect the path.
- Ask when ambiguity changes scope, data exposure, architecture, or publish behavior.
- Prefer the simplest complete change; no speculative features, abstractions, or configurability.
- Every changed line should trace to the request, a verified bug, or cleanup caused by your own change.
- Define success criteria for non-trivial work and loop until the matching checks pass or are explicitly blocked.
