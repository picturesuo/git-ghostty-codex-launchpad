---
summary: Working queue for the next small task, follow-ups, edge cases, and cleanup items.
read_when:
  - You are starting work and need the current Now item.
  - You finished a meaningful chunk and need to update follow-up tasks.
---

# Queue

## Now
- [x] Apply Karpathy-style cleanup: remove duplicated PR feedback doc, simplify BACKEND prompt ritual, and add ambiguity/simplicity guardrails.
- [x] Rewrite local skill files for agentic startup-product engineering, using current local skills plus Steinberger and Karpathy references.
- [x] Finish Steinberger-style agent-script/context cleanup: trim prompt context, add useful guardrails, document commands, and run verification.

## Next
- [ ] Try one real `--agent mixed --panes 5` launch on macOS Ghostty and inspect pane titles.
- [ ] Run `bash git-ghostty-codex-launchpad.sh --doctor` after installing `shellcheck`, if it is missing locally.
- [ ] Watch for Claude settings schema changes before adding more default permissions or hooks.

## Later
- [ ] Consider a layout preset flag if 6-8 panes need something richer than equal-width horizontal splits.
- [ ] Consider a dry-run mode that prints the generated AppleScript without opening Ghostty.

## Blocked
- [ ] No current blockers.

## Discovered While Working
- [ ] Edge case: saved-state fields must be written directly or parsed with an empty-field-safe format; tab-delimited `read` shifts blank fields.
- [ ] Edge case: generated prompt placeholders inside braces should not be truncated by title-length limits.
- [ ] Decision: pane five is `BACKEND-2`; extra panes repeat base roles instead of adding a new role type.
- [ ] Decision: adopt upstream-style skill validation, but keep it local and dependency-light instead of importing personal tools or broad skill packs.
- [ ] Decision: keep `AGENTS.md` terse and policy-only; put commands in `tools.md`, repeated workflows in `skills/`, and mutable task state in the shared context.
- [ ] Decision: product-engineering skills should stay focused on sellable slices, verified implementation, UI polish, and release readiness rather than importing a broad upstream skill catalog.
- [ ] Decision: Karpathy-style rules belong in always-on work policy and target workflow bootstrap, while repeated PR feedback procedure belongs only in `skills/pr-feedback/SKILL.md`.
