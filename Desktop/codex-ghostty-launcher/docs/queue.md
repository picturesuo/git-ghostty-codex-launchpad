# Queue

## Now
- [ ] Decide whether `scripts/codex-commit.sh` should stay upstream-only or grow explicit destination-discovery logic.

## Next
- [ ] If smarter auto-publish stays in scope, define one concrete discovery order the helper can implement without guessing.
- [ ] Compare actual launcher output against `docs/prompt-source.md` and remove duplicated wrapper lines.
- [ ] Decide whether bootstrap fallback text belongs in the shared artifact instead of the launcher wrapper.

## Later
- [ ] Add one concrete `scripts/codex-commit.sh` example for a multi-file workflow change.
- [ ] Trim duplicate commit-policy wording between `README.md` and `AGENTS.md` once the helper contract settles.
- [ ] Expand subsystem docs only when the project has real subsystems.

## Blocked
- [ ] Waiting on concrete launcher wrapper output or prompt-file samples from the canonical repo.

## Discovered While Working
- [ ] Edge case: decide whether missing-upstream runs should stay hard failures even when docs name a canonical GitHub destination.
- [ ] Edge case: confirm the helper messaging stays clear when a remote exists but the branch upstream does not.
- [ ] Cleanup: keep the documented role list aligned with the actual launcher role list.
