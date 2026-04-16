# Queue

## Now
- [ ] Tighten `AGENTS.md` into durable repo policy and align the launcher prompts/docs with that split.

## Next
- [ ] Verify the launcher still builds the same title/status snapshot fields after the formatting refactor.
- [ ] Regenerate the prompt docs and check the generated output for the slimmer prompt-source split.
- [ ] Run the repo shell checks that are available locally.

## Later
- [ ] Trim any remaining workflow duplication in user-facing docs if it starts to drift again.

## Blocked
- [ ] Waiting on a concrete follow-up for launch-time behavior or publish-flow changes.

## Discovered While Working
- [ ] Edge case: verify the prompt-source helper output stays stable when the BACKEND block is regenerated.
- [ ] Edge case: verify the launch-state snapshot still handles detached `HEAD` and non-git projects cleanly.
- [ ] Cleanup: remove any now-redundant launcher indirection if the snapshot/title path stays stable.
