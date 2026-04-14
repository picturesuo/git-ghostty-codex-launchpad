# Queue

## Now
- [ ] Exercise one real launcher run to verify the generated Ghostty prompts render as intended after the auto-publish workflow change.

## Next
- [ ] Decide whether to keep the unused `QUEUE-MANAGER` prompt template as future scaffolding or remove it from the launcher source.
- [ ] Document real validation commands beyond `bash -n` if more checks become standard.
- [ ] Decide whether the README should document detached-HEAD and no-upstream auto-publish behavior explicitly.

## Later
- [ ] Expand subsystem docs only when the project grows beyond a few scripts.

## Blocked
- [ ] Waiting on concrete new launcher behavior requests.

## Discovered While Working
- [ ] Edge case: define how auto-publish should behave on a detached HEAD or on branches without an upstream remote.
- [ ] Edge case: decide whether auto-publish should push ahead commits even when the requested path list has no fresh changes.
- [ ] Small improvement: consider a dedicated `codex-publish.sh` wrapper if `codex-commit.sh --push` becomes awkward to explain.
- [ ] Cleanup: remove the unused `QUEUE-MANAGER` template from the launcher if it never becomes a real non-pane workflow.
- [ ] Edge case: keep canonical-repo wording durable and avoid machine-specific local paths in user-facing docs.
- [ ] Edge case: verify commit helper behavior when a tracked file is deleted.
- [ ] Edge case: verify commit helper behavior when committing from outside the repo directory.
- [ ] Small improvement: add a short validation checklist if shell-based checks grow beyond `shellcheck`.
- [ ] Small improvement: document any repeated Ghostty or AppleScript setup gotchas once they recur.
- [ ] Small improvement: add a release checklist if this repo starts shipping tagged versions.
- [ ] Cleanup: remove duplicate local workspaces once the canonical repo path is stable.
