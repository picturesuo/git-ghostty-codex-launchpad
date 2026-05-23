---
name: scoped-commit-flow
description: Use when checkpointing or publishing a finished change with explicit paths, small commit boundaries, launcher-versus-target push rules, and proof before handoff.
---

# Scoped Commit Flow

Use this skill when a coherent change is ready to save, publish, or hand off. Bias toward small, reviewable commits that map to a real product or workflow outcome.

## Workflow

1. Inspect `git status --short` and the relevant `git diff`.
2. Confirm the work is finished: implementation, docs, generated files, and focused verification are done or explicitly not applicable.
3. Choose the smallest honest boundary:
   - one commit per finished file by default
   - one coupled commit only when files are inseparable, such as source plus generated output
   - one commit per independent product/workflow slice
4. Stage only explicit paths. Never use broad staging as a shortcut.
5. Write a short subject that says what changed in human terms.
6. Commit and push when policy allows it for this checkout.

## Tooling

Prefer the repo helper:

```bash
bash scripts/codex-commit.sh --no-push <paths...>
bash scripts/codex-commit.sh --each-path --no-push <paths...>
```

For launched target projects, publish mode `auto` means the helper commits and pushes each finished repo-visible non-private file immediately after verification. For this launcher repo, keep `--no-push` unless the user explicitly asks to push.

## Guardrails

- Do not stage `.`.
- Do not commit private, scratch, partial, failing, or unverified work.
- Do not mix unrelated product slices, prompt/doc changes, and tool changes in one commit.
- Do not group files just because they were edited in the same session.
- Do not rewrite history, amend, reset, restore, clean, or change branches unless explicitly asked.
- If unrecognized changes are present, assume another user or agent made them. Work around them and keep your commit paths narrow.
- If repo policy and launcher publish mode disagree, follow the stricter rule and state the mismatch.

## Handoff Evidence

Before final handoff, capture:

- files committed or intentionally left uncommitted
- verification commands and results
- any check not run and why
- whether a push happened, and to which remote, or why it did not
