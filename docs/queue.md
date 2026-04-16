# Queue

## Now
- [ ] Verify a live Ghostty launch auto-opens exact matches and asks before using close fuzzy matches.

## Next
- [ ] Verify `--resume-last` reuses saved remote metadata without prompting for the project again.
- [ ] Verify `--status-last` prints the last saved project, phase, and remote fields.
- [ ] Verify `--watch-command` still opens a live watcher window in a fresh Ghostty window.
- [ ] Decide whether the confirmation dialog should show the candidate path, the folder name, or both.
- [ ] Decide whether any additional README note is needed for exact-match vs close-match launch behavior.
- [ ] Document one or two real validation commands beyond `bash -n` if more checks become standard.

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
