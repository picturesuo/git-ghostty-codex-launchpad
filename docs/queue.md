# Queue

## Now
- [ ] Decide whether `docs/role-selection.md` should stay separate now that it is generated from the prompt source.

## Next
- [ ] Verify the generated role-selection page and prompt docs stay in sync after the next regeneration.
- [ ] Confirm the launcher still builds the same title/status snapshot fields after the prompt-doc refresh.
- [ ] Run the repo shell checks that are available locally once `shellcheck` is installed.

## Later
- [ ] Trim any remaining workflow duplication in user-facing docs if it starts to drift again.

## Blocked
- [ ] Waiting on a concrete follow-up for launch-time behavior or publish-flow changes.

## Discovered While Working
- [ ] Edge case: verify the role-selection generator stays stable if the role list changes order.
- [ ] Edge case: verify the prompt-source helper output stays stable when the BACKEND block is regenerated.
- [ ] Edge case: verify the launch-state snapshot still handles detached `HEAD` and non-git projects cleanly.
- [ ] Cleanup: remove any now-unnecessary role-summary prose from hand-maintained docs if it becomes redundant.
- [ ] Cleanup: remove any now-redundant launcher indirection if the snapshot/title path stays stable.
