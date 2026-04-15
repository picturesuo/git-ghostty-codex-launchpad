# Queue

## Now
- [ ] Verify one real launcher-generated role prompt against the published README template after the wrapper emits stable prompt files or sample payloads.

## Next
- [ ] Add one fully filled example prompt that uses this repo's actual paths and the current four-field output contract.
- [ ] Document when Builder should update shared-artifact header metadata versus only the numbered task sections.
- [ ] Add a small validation note or script for `scripts/codex-commit.sh --push` success and failure cases.

## Later
- [ ] Expand subsystem docs only when the project has real subsystems.

## Blocked
- [ ] Waiting on concrete launcher wrapper output or prompt-file samples from the canonical repo.

## Discovered While Working
- [ ] Edge case: verify `scripts/codex-commit.sh --push` fails cleanly when the current branch has no upstream.
- [ ] Edge case: verify the role prompt still works when `AGENTS.md` is missing and the shared artifact is the only durable context.
- [ ] Cleanup: move role prompt templates into a dedicated doc or generator if the wrapper contract changes again.
