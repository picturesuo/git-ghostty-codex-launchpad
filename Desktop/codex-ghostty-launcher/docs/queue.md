# Queue

## Now
- [ ] Decide whether `scripts/codex-commit.sh` should stay upstream-only or grow explicit destination-discovery logic.

## Next
- [ ] If smarter auto-publish stays in scope, define one concrete discovery order the helper can implement without guessing.
- [ ] Validate default commit-and-push behavior once this repo has a configured GitHub remote and branch upstream.
- [ ] Compare actual launcher prompt output against the README prompt blocks and remove any remaining duplicated lines.
- [ ] Decide whether the shared artifact should own the bootstrap fallback so the base prompt can stay shorter.
- [ ] Split prompt source blocks out of `README.md` if the launcher starts consuming them directly.
- [ ] Add one concrete example showing how to use `scripts/codex-commit.sh` for a meaningful multi-file workflow change.

## Later
- [ ] Expand subsystem docs only when the project has real subsystems.

## Blocked
- [ ] Waiting on concrete launcher wrapper output or prompt-file samples from the canonical repo.

## Discovered While Working
- [ ] Edge case: decide whether missing-upstream runs should stay hard failures on the default path even when repo docs name a canonical GitHub destination.
- [ ] Edge case: verify helper messaging stays clear when a remote exists but the branch upstream does not.
- [ ] Edge case: verify the helper pushes cleanly when the local branch name differs from the upstream branch name.
- [ ] Cleanup: trim duplicate commit-policy wording between README.md and AGENTS.md once the helper contract settles.
- [ ] Edge case: confirm the default commit rule still excludes external shared-context files even when they are updated during local task execution.
- [ ] Edge case: improve generated messages when staged paths mix one named workflow file with several unrelated files.
- [ ] Edge case: verify `scripts/codex-commit.sh --push` fails cleanly when the current branch has no upstream.
- [ ] Edge case: verify default push behavior reports a clear error when no remote is configured at all.
- [ ] Edge case: verify the role prompt still works when `AGENTS.md` is missing and the shared artifact is the only durable context.
- [ ] Edge case: verify the wrapper-plus-role-block ordering still renders cleanly if a future role prompt adds another fenced block or numbered list.
- [ ] Edge case: verify long absolute paths in the shared wrapper remain readable in launched Codex panes.
- [ ] Edge case: verify the restored `QUEUE-MANAGER` role block stays in sync with the actual launcher role list.
- [ ] Edge case: verify the shorter base prompt still preserves auto-commit behavior and shared-artifact ownership across all roles.
