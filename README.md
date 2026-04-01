# Ghostty Codex Launchpad

Ghostty Codex Launchpad is a small macOS helper I use on my personal Mac to spin up a ready-to-go Ghostty workspace for Codex.

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

This is intentionally simple and pretty personal. It is built for Ghostty on macOS, and it is meant to make my own local workflow faster when I am bouncing into a project and want the Codex panes set up the same way every time.

## Files

- `ghostty-codex-launchpad.sh` - the main launcher
- `start-ghostty-codex-4pane.sh` - thin wrapper for shell or shortcut use
- `open-ghostty-codex.command` - double-clickable macOS launcher

## Notes

- This is macOS-only because it uses `osascript`.
- This is Ghostty-only because it talks to the Ghostty app directly.
- It is designed for a single-user personal setup, not a cloud service or shared team tool.

## Use

Run the launcher from Terminal, or double-click the `.command` file if you want Finder to open it.
