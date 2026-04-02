# git-ghostty-codex-launchpad

git-ghostty-codex-launchpad is a small macOS helper I use on my personal Mac to spin up a ready-to-go Ghostty workspace for Codex and keep the GitHub commit/push workflow built into the handoff.

When I run it, it:

- Opens a fresh Ghostty window
- Splits it into four panes
- Asks what project I want to work on
- Tries to find that project folder on my machine
- Writes a shared session note in `~/.codex/`
- Drops four different Codex roles into the panes so the work starts with a clear split of responsibilities

The four roles are:

- `BUILDER` - main feature work and end-to-end user-facing implementation
- `BACKEND` - APIs, database, validation, auth, and business logic
- `DEBUGGER` - root-cause analysis for bugs and broken behavior
- `TESTER` - verification, edge cases, and stability checks

This is intentionally simple and pretty personal. It is built for Ghostty on macOS, and it is meant to make my own local workflow faster when I am bouncing into a project and want the Codex panes and GitHub workflow set up the same way every time.

After you give permission to commit, git can stage the approved changes, create the commit, and push it online to GitHub without extra manual steps.

## Files

- `git-ghostty-codex-launchpad.sh` - the main launcher
- `start-git-ghostty-codex-launchpad.sh` - thin wrapper for shell or shortcut use
- `open-git-ghostty-codex-launchpad.command` - double-clickable macOS launcher

## Notes

- This is macOS-only because it uses `osascript`.
- This is Ghostty-only because it talks to the Ghostty app directly.
- It is designed for a single-user personal setup, not a cloud service or shared team tool.

## Use

Run the launcher from Terminal, or double-click the `.command` file if you want Finder to open it.

## Verify

For a quick shell sanity check, run `shellcheck git-ghostty-codex-launchpad.sh` from inside the project directory.
