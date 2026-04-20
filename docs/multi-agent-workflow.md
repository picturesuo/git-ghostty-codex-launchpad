---
summary: Lightweight coordination rules for splitting work across multiple agents or persistent panes.
read_when:
  - You plan to run multiple agents on the same task.
  - You need explicit ownership, handoff, or persistent-session guidance.
---

# Multi-Agent Workflow

Use this playbook only when multiple agents materially help the task. Keep coordination explicit and keep ownership narrow.

## When To Split Work

Use multiple agents when:
- one agent can keep moving on the main path while another handles a bounded side task
- validation, documentation, or exploration can run in parallel with implementation
- the work has clean ownership boundaries

Do not split work when:
- the next step is blocked on one urgent result
- multiple agents would edit the same files at the same time
- the coordination cost is higher than the likely speedup

## Coordination Rules

- One agent per task or concern.
- Give each agent a clear goal, write scope, and expected output.
- Keep coordination explicit: state who owns which files, checks, or decisions.
- Prefer fast models for repetitive, background, or exploratory work.
- Use stronger models for integration, design choices, and ambiguous fixes.

## Long-Running Work

- Put long-running agents in a persistent environment such as `tmux` or a dedicated terminal pane.
- Keep interactive debugging, log tails, and watcher commands in persistent panes so they stay visible.
- Do not rely on undocumented helper scripts; use standard shell, repo scripts, and explicit commands.

## Handoffs

- Queue work with a short task statement, relevant paths, and acceptance criteria.
- Ask agents to report changed files, verification run, and open risks.
- Integrate completed chunks quickly so stale branches of work do not drift.
- If two agents discover conflicting assumptions, stop and resolve the conflict before merging their changes.

## Git Boundaries

- Keep write scopes disjoint whenever possible.
- Prefer one commit per finished file or one commit per logical change, whichever is cleaner.
- Push only when the user clearly wants that chunk published.
- Check `git status` and `git diff` before integrating another agent's work.

## Repo Fit

This repo already uses multiple roles and panes. Use that structure as the default coordination model before inventing a more elaborate orchestration layer.
