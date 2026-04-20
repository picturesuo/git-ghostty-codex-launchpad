---
summary: Working queue for the next small task, follow-ups, edge cases, and cleanup items.
read_when:
  - You are starting work and need the current Now item.
  - You finished a meaningful chunk and need to update follow-up tasks.
---

# Queue

## Now
- [ ] Tighten `README.md` so its workflow and publishing text matches the automatic per-file commit-and-push policy.

## Next
- [ ] Compare the README workflow wording against `AGENTS.md` and `docs/knowledge.md` so the README does not drift from current repo policy.
- [ ] Update the README sections that describe per-file publishing so each finished file clearly gets its own short commit message and push before the next file starts.
- [ ] Read the final README wording once for overclaims about remotes, automation, or private-file publishing before publishing it.

## Later
- [ ] Revisit the generated docs only if the README wording reveals a policy mismatch that is not actually README-only.

## Blocked
- [ ] No current blockers.

## Discovered While Working
- [ ] Edge case: avoid README wording that implies private, personal, scratch, or local-only files are part of the default publish path.
- [ ] Edge case: avoid README wording that still reads as if multiple changed files can be bundled into one commit or one push.
- [ ] Cleanup: trim duplicated per-file publish wording if both the workflow and publishing sections end up saying the same thing twice.
