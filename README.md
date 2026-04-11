# git-ghostty-codex-launchpad

A macOS Ghostty launcher that opens a ready-to-work Codex setup with multiple panes, role-based prompts, and a built-in Git commit/push handoff.

## Why This Matters

Starting a coding session usually involves repetitive setup: opening terminals, finding the project, creating context, and getting each agent into the right role. This project compresses that startup work into one launcher so the workflow is consistent every time.

## What It Does

- Opens a fresh Ghostty window and splits it into four panes
- Prompts for the project you want to work on and tries to find it locally
- Writes a shared session note in `~/.codex/`
- Starts Codex in each pane and sends `/fast` before the role prompt
- Assigns four roles so the session begins with clear responsibility split
- Keeps the GitHub commit/push workflow built into the handoff

## Roles

- `BUILDER` - main feature work and end-to-end implementation
- `BACKEND` - APIs, database, auth, validation, and business logic
- `DEBUGGER` - bug investigation and root-cause analysis
- `TESTER` - verification, edge cases, and stability checks

## Files

- `git-ghostty-codex-launchpad.sh` - main launcher
- `start-git-ghostty-codex-launchpad.sh` - thin shell wrapper
- `open-git-ghostty-codex-launchpad.command` - double-clickable macOS launcher

## How To Use It

Run the launcher from Terminal, or double-click the `.command` file from Finder.

## Notes

- macOS-only because it depends on `osascript`
- Ghostty-only because it talks directly to the Ghostty app
- Designed for a personal local workflow rather than a shared service

## Verify

Run `shellcheck git-ghostty-codex-launchpad.sh` from the project directory for a quick shell sanity check.
