---
summary: Workflow for reading pull request comments, preparing replies, and tracking which review points still need changes.
read_when:
  - You are addressing GitHub PR review comments.
  - You need to summarize reviewer feedback before making follow-up edits.
---

# PR Feedback

Use this workflow when the task is driven by GitHub pull request comments or review threads.

## Read First

1. Run `bash scripts/docs-list.sh` when the task also touches docs-heavy parts of the repo.
2. Inspect the PR with `gh pr view --comments`.
3. If the review discussion is large, capture a short list of:
   - open requests
   - resolved requests
   - unclear requests that need confirmation

## Workflow

1. Group comments by file, behavior, or decision.
2. Separate actionable fixes from opinion-only discussion.
3. Make the smallest changes that fully address the actionable feedback.
4. Re-run the most relevant checks for the touched files.
5. Prepare a reply that states:
   - what changed
   - where it changed
   - what was verified
   - what remains open, if anything

## Guardrails

- Do not reply as if a comment is fixed until the code or docs change is actually in place.
- Do not mark ambiguous comments as resolved without stating the interpretation you implemented.
- If a comment conflicts with existing repo policy or another accepted comment, surface the conflict explicitly.
- Keep replies concrete and file-aware instead of generic.

## Helpful Commands

```bash
gh pr view --comments
gh pr diff
gh run list --limit 10
```
