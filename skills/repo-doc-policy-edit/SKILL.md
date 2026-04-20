---
name: repo-doc-policy-edit
description: Use when editing AGENTS.md, README.md, docs/knowledge.md, docs/queue.md, or tools.md so repo policy stays concise and consistent. Covers docs-first reading, conflict checks, and small policy-only edits.
---

# Repo Doc Policy Edit

Use this skill when the task is changing repo policy, workflow wording, or operator guidance.

## Read First

Read only the docs that control the behavior you are editing:
- Run `bash scripts/docs-list.sh` first when it exists so the current `summary` and `read_when` hints narrow what to read.
- `AGENTS.md` for durable repo policy
- `README.md` for user-facing workflow description
- `docs/knowledge.md` for durable project facts and user guidance
- `docs/queue.md` for the active working queue
- `tools.md` for repo-local command inventory

## Workflow

1. Identify the source-of-truth doc for the specific rule you are changing.
2. Inspect nearby docs for conflicting wording before editing.
3. Make the smallest wording change that removes ambiguity.
4. If the rule exists in multiple docs, either align them in the same pass or leave a clear note about the mismatch.
5. Verify the final text by reading the edited docs directly and running `git diff --check` on the touched files.

## Guardrails

- Keep policy operational, not stylistic.
- Do not invent repo behavior that is not implemented or documented elsewhere.
- Prefer short sections and direct rules over long narrative explanation.
