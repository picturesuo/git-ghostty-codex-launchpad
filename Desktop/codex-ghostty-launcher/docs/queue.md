# Queue

## Now
- [ ] Keep the prompt-source contract, generated docs, and canonical launcher output aligned.

## Next
- [ ] Add one README example that shows smart push configuring upstream on first publish.
- [ ] Teach `scripts/check-prompt-drift.sh` to verify wrapper notes as well as role bodies if the canonical launcher gains extra shared lines.
- [ ] Decide whether bootstrap fallback text belongs in the shared artifact instead of the launcher wrapper.

## Later
- [ ] Trim duplicate wording between `README.md`, `AGENTS.md`, and `docs/context-budget.md`.
- [ ] Add one multi-file commit-helper example once the smart-push flow settles.
- [ ] Expand subsystem docs only when the project has real subsystems.

## Blocked
- [ ] Waiting on canonical launcher changes that materially alter the prompt wrapper contract.

## Discovered While Working
- [ ] Edge case: verify smart push still picks the correct remote when one GitHub remote exists under a non-`origin` name.
- [ ] Edge case: verify repo-doc mapping stays unambiguous if multiple GitHub repo slugs appear in docs.
- [ ] Edge case: verify the helper fails clearly when the configured upstream has unrelated history.
- [ ] Cleanup: keep the documented role list aligned with the actual launcher role list.
