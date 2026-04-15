# Queue

## Now
- [ ] Validate the shared git helper against a representative selected project repo so commit-and-push works outside the launchpad repo.
- [ ] Exercise one launcher run against an existing project missing `AGENTS.md` to verify the bootstrap path now seeds `AGENTS.md`, `docs/queue.md`, and usable publish guidance before prompts are sent.
- [ ] Run one live launcher session and confirm the generated role prompts point at the shared helper path for the selected project.

## Next
- [ ] Decide whether the shared helper should detect and warn on projects with no git remote before agents finish a task.
- [ ] Document real validation commands beyond `bash -n` if more checks become standard.
- [ ] Decide whether the README should document detached-HEAD and no-upstream auto-publish behavior explicitly.
- [ ] Decide whether the launcher should compact repeated boilerplate in existing project-local `AGENTS.md` files or leave that to repo owners.

## Later
- [ ] Expand subsystem docs only when the project grows beyond a few scripts.

## Blocked
- [ ] Waiting on concrete new launcher behavior requests.

## Discovered While Working
- [ ] Edge case: define how auto-publish should behave on a detached HEAD or on branches without an upstream remote.
- [ ] Edge case: decide whether auto-publish should push ahead commits even when the requested path list has no fresh changes.
- [ ] Edge case: verify the shared helper still refuses paths outside the selected project root when called by absolute path from another repo.
- [ ] Small improvement: consider a dedicated `codex-publish.sh` wrapper if `codex-commit.sh --push` becomes awkward to explain.
- [ ] Cleanup: remove the unused `QUEUE-MANAGER` template from the launcher if it never becomes a real non-pane workflow.
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
- [ ] Cleanup: remove the unused `QUEUE-MANAGER` template if the four-pane launcher will stay fixed.
