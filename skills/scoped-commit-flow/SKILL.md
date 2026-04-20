---
name: scoped-commit-flow
description: Use when making local commits or optional pushes in this repo. Covers small subtask commits, per-file versus per-logical-change boundaries, and safe use of scripts/codex-commit.sh without assuming every commit should be pushed.
---

# Scoped Commit Flow

Use this skill when a change is ready for a checkpoint or publish step.

## Workflow

1. Check `git status` and `git diff`.
2. Choose the boundary:
   - one commit per meaningful subtask
   - one commit per finished file
   - one commit per logical change spanning a few files
3. Keep the commit scoped to explicit paths.
4. Use a short, human, consistent message.
5. Push only if the user clearly wants that chunk on GitHub.

## Tooling

- Prefer `bash scripts/codex-commit.sh --no-push <paths...>` for scoped local commits.
- Use `bash scripts/codex-commit.sh --each-path --no-push <paths...>` when one commit per file is the cleanest boundary.
- Omit `--no-push` only when the user has clearly asked to publish.

## Guardrails

- Do not stage `.`.
- Do not batch unrelated files into one commit.
- If the repo instructions disagree about push behavior, surface that mismatch instead of guessing.

