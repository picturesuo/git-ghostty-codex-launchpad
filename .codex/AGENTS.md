# Global Codex Instructions

These instructions apply across Codex sessions and repos. Repo-local
`AGENTS.md` files may add project-specific rules, but keep these global user
preferences intact unless the user explicitly changes them.

## Non-Interrupting UI Work

- Do not take over the user's active screen for click-through, browser testing,
  UI verification, screenshots, or app inspection unless the user explicitly
  approves foreground control for the current task.
- Do not open tabs or windows in the user's active browser for automated
  click-through work.
- Do not switch macOS Spaces, move the visible cursor, focus apps, click
  menu-bar items, click Dock items, or use System Events/`osascript` to operate
  visible UI unless foreground control was explicitly approved for the current
  task.
- Prefer isolated automation surfaces: Codex in-app Browser, cmux browser or
  workspace surfaces, offscreen renderers, logs, diagnostics, accessibility
  metadata, screenshots from isolated browser surfaces, and app-generated
  artifacts.
- If a task truly requires the user's logged-in browser session, a native app,
  a system dialog, or other foreground-only UI, stop and ask before proceeding.

## Click-Through Default

For `/click`, "click through", manual UI testing, or similar requests, use the
`click-through` skill and keep the run isolated from the user's active desktop.
Completion requires UI evidence from the isolated surface or a clear statement
that non-interrupting verification was not possible.
