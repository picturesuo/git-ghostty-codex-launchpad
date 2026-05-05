---
summary: Working queue for the next small task, follow-ups, edge cases, and cleanup items.
read_when:
  - You are starting work and need the current Now item.
  - You finished a meaningful chunk and need to update follow-up tasks.
---

# Queue

## Now
- [x] Run final launcher verification after the agent-neutral, pane-count, publish-mode, context-reset, and docs updates.

## Next
- [ ] Try one real `--agent mixed --panes 5` launch on macOS Ghostty and inspect pane titles.
- [ ] Run `bash git-ghostty-codex-launchpad.sh --doctor` after installing `shellcheck`, if it is missing locally.
- [ ] Watch for Claude settings schema changes before adding more default permissions or hooks.

## Later
- [ ] Consider a layout preset flag if 6-8 panes need a better split pattern than repeated right splits.
- [ ] Consider a dry-run mode that prints the generated AppleScript without opening Ghostty.

## Blocked
- [ ] No current blockers.

## Discovered While Working
- [ ] Edge case: saved-state fields must be written directly or parsed with an empty-field-safe format; tab-delimited `read` shifts blank fields.
- [ ] Edge case: generated prompt placeholders inside braces should not be truncated by title-length limits.
- [ ] Decision: pane five is `BACKEND-2`; extra panes repeat base roles instead of adding a new role type.
