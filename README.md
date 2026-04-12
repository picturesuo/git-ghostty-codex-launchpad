# git-ghostty-codex-launchpad

A macOS Ghostty launcher that opens a ready-to-work Codex setup with multiple panes, role-based prompts, and a built-in Git commit/push handoff.

## Why This Matters

Starting a coding session usually involves repetitive setup: opening terminals, finding the project, creating context, and getting each agent into the right role. This project compresses that startup work into one launcher so the workflow is consistent every time.

## What It Does

- Opens a fresh Ghostty window and splits it into four panes
- Prompts for the project you want to work on and tries to find it locally
- Writes a shared session note in `~/.codex/`
- Starts Codex in each pane without sending `/fast`
- Drops four different Codex roles into the panes in a fixed left-to-right order so the work starts with a clear split of responsibilities
- Seeds a shared task artifact contract so all four panes work from the same definition of success
- Keeps the GitHub commit/push workflow built into the handoff

The visible left-to-right pane order is:

1. `BUILDER` - defines the first real task artifact, scope, constraints, success criteria, and invariants before implementation
2. `BACKEND` - does most of the implementation work, mapped directly to the artifact criteria and constraints
3. `DEBUGGER` - maps failures back to specific criteria or invariants and applies the minimum fix
4. `CRITIC` - pressure-tests the artifact, adds risk and failure coverage, and acts as the verification gate with pass/fail judgments

## Workflow

All four panes are expected to use the same shared task artifact in `~/.codex/...-shared-context.md`.

The workflow rules are:

- Do not use `/fast` as part of launch or normal role behavior.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- Use stable IDs like `SC1`, `INV1`, `FM1`, `R1`, `Q1`, and `F1` so handoffs stay traceable.

There is one first-pass exception:

- When a brand-new tab opens, the artifact may still be empty or only contain placeholders.
- On that first pass, `BUILDER` should initialize the artifact.
- On that first pass, the other roles should not treat the missing artifact as a problem yet; they should acknowledge that Builder needs to initialize it first.
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
