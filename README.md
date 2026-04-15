# git-ghostty-codex-launchpad

A macOS Ghostty launcher that opens a ready-to-work Codex setup with multiple panes, role-based prompts, and a built-in Git commit/push handoff.

## Why This Matters

Starting a coding session usually involves repetitive setup: opening terminals, finding the project, creating context, and getting each agent into the right role. This project compresses that startup work into one launcher so the workflow is consistent every time.

`ghostty-codex-launchpad` is the canonical repo for ongoing work. The duplicate `ghostty-codex-launcher` folder was the wrong place to keep evolving the project because the real launcher code and workflow engine already live here.

## What It Does

- Opens a fresh Ghostty window and splits it into four panes
- Prompts for the project you want to work on and tries to find it locally
- Writes a shared session note in `~/.codex/` and preserves it across relaunches
- Starts Codex in each pane without sending `/fast`, passing the role prompt at launch time instead of pasting it into a live shell later
- Drops four different Codex roles into the panes in a fixed left-to-right order so the work starts with a clear split of responsibilities
- Seeds a bootstrap shared task artifact so all four panes start from usable context instead of `TBD` placeholders
- Prompts the roles to auto-publish successful completed work through one shared Git helper that operates on the selected project repo
- Bootstraps missing project `AGENTS.md` and `docs/queue.md` files for both new and existing projects before the role prompts are sent

The visible left-to-right pane order is:

1. `BUILDER` - defines the first real task artifact, scope, constraints, success criteria, and invariants before implementation
2. `BACKEND` - does most of the implementation work, mapped directly to the artifact criteria and constraints
3. `DEBUGGER` - maps failures back to specific criteria or invariants and applies the minimum fix
4. `CRITIC` - pressure-tests the artifact, adds risk and failure coverage, and acts as the verification gate with pass/fail judgments

## Workflow

All four panes are expected to use the same shared task artifact in `~/.codex/...-shared-context.md`, and existing task state should survive relaunches.
Durable repo policy belongs in `AGENTS.md`; the shared context should carry the current task artifact and status instead of duplicating the full workflow contract.

The workflow rules are:

- Do not use `/fast` as part of launch or normal role behavior.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- Once a task meets that completion bar, the workflow is expected to publish the intended files with the launcher-provided shared helper, which commits first and then pushes by default when run from a normal branch.
- If the current branch has no upstream, the helper uses `git push -u` to set it automatically; it refuses to push from a detached `HEAD` and fails fast if the configured remote does not exist.
- If the selected project is missing `AGENTS.md`, the launcher seeds a starter `AGENTS.md` and `docs/queue.md` and targets `AGENTS.md` first so the Builder has concrete bootstrap work.
- Use stable IDs like `SC1`, `INV1`, `FM1`, `R1`, `Q1`, and `F1` so handoffs stay traceable.

Bootstrap behavior:

- A fresh shared-context file starts with a usable bootstrap artifact instead of all-`TBD` sections.
- `BUILDER` should still refine that bootstrap artifact into task-specific criteria once the user gives a concrete request.
- The other roles should refine the minimum sections they need when the user explicitly redirects them, rather than stopping at `NOT READY`.
- The launcher prompt wrapper stays intentionally short and relies on `AGENTS.md` plus the shared artifact for the rest of the durable workflow context.
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
