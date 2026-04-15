# Queue

## Now
- [ ] Validate default commit-and-push behavior once this repo has a configured GitHub remote and branch upstream.

## Next
- [ ] Add one concrete example showing how to use `scripts/codex-commit.sh` for a meaningful multi-file workflow change.
- [ ] Add a short note clarifying when queue-only maintenance changes are too low-signal to commit alone.
- [ ] Decide whether the README should mention that docs collaborators need are commit-worthy even when no code changed.

## Later
- [ ] Expand subsystem docs only when the project has real subsystems.

## Blocked
- [ ] Waiting on concrete launcher wrapper output or prompt-file samples from the canonical repo.

## Discovered While Working
- [ ] Edge case: confirm the default commit rule still excludes external shared-context files even when they are updated during local task execution.
- [ ] Edge case: improve generated messages when staged paths mix one named workflow file with several unrelated files.
- [ ] Edge case: verify `scripts/codex-commit.sh --push` fails cleanly when the current branch has no upstream.
- [ ] Edge case: verify default push behavior reports a clear error when no remote is configured at all.
- [ ] Edge case: verify the role prompt still works when `AGENTS.md` is missing and the shared artifact is the only durable context.
- [ ] Edge case: verify the wrapper-plus-role-block ordering still renders cleanly if a future role prompt adds another fenced block or numbered list.
- [ ] Edge case: verify long absolute paths in the shared wrapper remain readable in launched Codex panes.
- [ ] Cleanup: reduce prompt drift by generating README prompt blocks from the canonical launcher source if this duplication changes again.
