---
name: pr-feedback
description: Use when GitHub PR comments, review threads, or CI feedback drive the task; gather evidence with gh, group actionable fixes, patch narrowly, verify, and reply concretely.
---

# PR Feedback

Use this skill when a pull request, review thread, reviewer request, or CI result defines the work.

## Workflow

1. Start from local truth:
   - `git status --short --branch`
   - `gh pr view --comments`
   - `gh pr diff --patch` when the diff matters
2. Group feedback:
   - correctness bug
   - missing test or proof
   - product/UX concern
   - docs or generated output drift
   - question needing clarification
   - request that conflicts with repo policy
3. Read the owning code, tests, and docs before editing. Do not patch from a comment alone.
4. Apply the smallest change that fully addresses the actionable feedback.
5. Add or update focused regression coverage when behavior changes.
6. Run checks that cover the touched surface.
7. Prepare a terse reply with changed files, proof, and remaining risk.

## Review Quality Bar

- Lead with findings when asked for review.
- Use file, line, symbol, or command evidence.
- Say `not proven` when evidence is missing.
- Separate product fit from implementation correctness.
- Prefer a slightly larger bounded refactor when it removes the bug class; avoid cosmetic rewrites.
- Do not approve, merge, close, resolve, rerun, push, or comment unless the user asked for that action.

## Guardrails

- Do not claim a comment is fixed until the change is in the repo.
- Do not collapse multiple unrelated comments into one vague reply.
- If a reviewer request is ambiguous, state the interpretation you implemented.
- If GitHub state matters, prefer `gh` output over memory or guesswork.
- If author trust, security impact, or customer data risk matters, deepen review before accepting the change.
- If CI is stale, missing, or unrelated, do not treat it as proof.

## Useful Commands

- `gh pr view --comments`
- `gh pr diff`
- `gh run list --limit 10`
- `gh run view <id> --log-failed`
- `git diff --check`

## Reply Shape

Use a compact reply:

```text
Addressed:
- <comment/theme>: <file or behavior changed>

Verified:
- <command>: <result>

Not run / risk:
- <only if applicable>
```
