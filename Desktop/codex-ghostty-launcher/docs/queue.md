# Queue

## Now
- [ ] Add one fully filled example prompt that uses this repo's actual paths and the current four-field output contract.

## Next
- [ ] Document when Builder should update shared-artifact header metadata versus only the numbered task sections.
- [ ] Add a small validation note or script for `scripts/codex-commit.sh --push` success and failure cases.
- [ ] Audit `AGENTS.md` and other local docs for stale shared-context path references.

## Later
- [ ] Expand subsystem docs only when the project has real subsystems.

## Blocked
- [ ] Waiting on concrete launcher wrapper output or prompt-file samples from the canonical repo.

## Discovered While Working
- [ ] Edge case: verify `scripts/codex-commit.sh --push` fails cleanly when the current branch has no upstream.
- [ ] Edge case: verify the role prompt still works when `AGENTS.md` is missing and the shared artifact is the only durable context.
- [ ] Edge case: verify the wrapper-plus-role-block ordering still renders cleanly if a future role prompt adds another fenced block or numbered list.
- [ ] Edge case: verify long absolute paths in the shared wrapper remain readable in launched Codex panes.
- [ ] Cleanup: move role prompt templates into a dedicated doc or generator if the wrapper contract changes again.
- [ ] Cleanup: reduce prompt drift by generating README prompt blocks from the canonical launcher source if this duplication changes again.
