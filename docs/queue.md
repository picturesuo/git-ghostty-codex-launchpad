# Queue

## Now
- [ ] Validate `scripts/codex-commit.sh` auto-discovery against one non-canonical project repo with no configured remote.

## Next
- [ ] Verify one live Ghostty launch against an existing repo with the canonical prompt source now wired into launcher output.
- [ ] Decide whether migrated shared-context sections should stay as lightweight `###` headings or be normalized into numbered artifact sections in a later slice.
- [ ] Decide whether migrated shared-context files should be backfilled with starter content from `docs/knowledge.md` or stay empty until roles record reusable knowledge.
- [ ] Decide whether the launcher should compact or rewrite repeated migrated knowledge/coaching sections if older artifacts are relaunched many times.
- [ ] Document real validation commands beyond `bash -n` if more checks become standard.
- [ ] Decide whether the README should document detached-HEAD and no-upstream auto-publish behavior explicitly.
- [ ] Decide whether the launcher should compact repeated boilerplate in existing project-local `AGENTS.md` files or leave that to repo owners.

## Later
- [ ] Expand subsystem docs only when the project grows beyond a few scripts.

## Blocked
- [ ] Waiting on concrete new launcher behavior requests.

## Discovered While Working
- [ ] Edge case: verify migration behavior when a legacy shared-context file already contains one of the two new sections but not both.
- [ ] Edge case: verify migration placement when the task artifact has no `Status` section or uses nonstandard numbering.
- [ ] Cleanup: decide whether the migrated `###` knowledge/coaching headings should be normalized into numbered artifact sections once the format stabilizes.
- [ ] Edge case: define how auto-publish should behave on a detached HEAD or on branches without an upstream remote.
- [ ] Edge case: decide whether auto-publish should push ahead commits even when the requested path list has no fresh changes.
- [ ] Edge case: verify the shared helper still refuses paths outside the selected project root when called by absolute path from another repo.
- [ ] Edge case: verify helper doc-mapped auto-discovery still behaves correctly when multiple repo docs mention different GitHub repos.
- [ ] Small improvement: consider a dedicated `codex-publish.sh` wrapper if `codex-commit.sh --push` becomes awkward to explain.
- [ ] Edge case: verify the bootstrap path does not overwrite an existing project `AGENTS.md` or `docs/queue.md`.
- [ ] Edge case: keep canonical-repo wording durable and avoid machine-specific local paths in user-facing docs.
- [ ] Edge case: verify commit helper behavior when a tracked file is deleted.
- [ ] Edge case: verify commit helper behavior when committing from outside the repo directory.
- [ ] Small improvement: add a short validation checklist if shell-based checks grow beyond `shellcheck`.
- [ ] Small improvement: document any repeated Ghostty or AppleScript setup gotchas once they recur.
- [ ] Edge case: verify `codex "<prompt>"` launch-time handoff still behaves correctly when the prompt contains quotes, backticks, or long multiline content.
- [ ] Edge case: verify legacy shared-context files with hand-edited text around the generated boilerplate still compact safely.
- [ ] Small improvement: add a release checklist if this repo starts shipping tagged versions.
- [ ] Cleanup: remove duplicate local workspaces once the canonical repo path is stable.
