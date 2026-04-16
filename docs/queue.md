# Queue

## Now
- [ ] Refactor the launch-state rendering into one structured snapshot helper.

## Next
- [ ] Verify a live Ghostty launch still auto-opens exact matches and asks before using close fuzzy matches.
- [ ] Verify the remote-path and GitHub-repo dialogs prefill from the last launch or repo config on repeated launches.
- [ ] Verify `--resume-last` reuses saved remote metadata without prompting for the project again.
- [ ] Verify `--status-last` prints the last saved project, Builder/plan phase, and remote fields.
- [ ] Verify `--watch-command` still opens a live watcher window in a fresh Ghostty window.
- [ ] Decide whether the confirmation dialog should show the candidate path, the folder name, or both.
- [ ] Verify `scripts/check-shell.sh` runs cleanly once `shellcheck` is available in the environment.

## Later
- [ ] Expand subsystem docs only when the project grows beyond a few scripts.

## Blocked
- [ ] Waiting on concrete new launcher behavior requests.

## Discovered While Working
- [ ] Edge case: verify rejection of a fuzzy match returns cleanly to the project prompt without launching Ghostty.
- [ ] Edge case: verify exact-match resolution still prefers the canonical project directory when session files exist for the same repo.
- [ ] Edge case: verify the confirmation dialog remains readable when the candidate path is long.
- [ ] Edge case: verify `--resume-last` fails cleanly if the last saved project directory no longer exists.
- [ ] Edge case: verify `--watch-command` preserves shell quoting when the command contains spaces, quotes, or pipes.
- [ ] Edge case: verify the launcher does not overwrite an existing project `AGENTS.md` or `docs/queue.md`.
- [ ] Cleanup: remove duplicate local workspaces once the canonical repo path is stable.
