---
name: pr-feedback
description: Use when a task is driven by GitHub pull request comments, review threads, or follow-up replies. Covers reading gh PR feedback, grouping comments into actionable work, and replying with concrete change and verification notes.
---

# PR Feedback

Use this skill when review comments, requested changes, or reply preparation drive the task.

## Workflow

1. Inspect the PR with `gh pr view --comments`.
2. Group comments into:
   - direct code or doc fixes
   - questions needing clarification
   - conflicts with existing repo policy or accepted decisions
3. Apply the smallest changes that fully address the actionable comments.
4. Re-run the most relevant checks for the touched files.
5. Reply with a short note covering what changed, where it changed, and what was verified.

## Guardrails

- Do not claim a comment is fixed until the change is in the repo.
- Do not collapse multiple unrelated comments into one vague reply.
- If a reviewer request is ambiguous, state the interpretation you implemented.
- If GitHub state matters, prefer `gh` output over memory or guesswork.

## Useful Commands

- `gh pr view --comments`
- `gh pr diff`
- `gh run list --limit 10`
