---
name: click-through
description: Non-interrupting UI walkthrough and verification by actually operating the target. Use when the user says "click through", "/click", "act like a real user", "click each button", "test this flow manually", asks for background click-through/testing that should not take over their active screen, or asks Codex to operate a website, app, prototype, browser, or desktop UI by clicking, typing, scrolling, screenshotting, and checking that each interaction worked. Always prefer an isolated browser, in-app Browser, or cmux surface. Do not open tabs/windows in the user's active browser or use foreground screen control unless the user explicitly approves that for the current task.
---

# Click Through

## Overview

Operate the target UI like a real user instead of only inspecting code or giving advice. Move through the experience with actual clicks, typing, scrolling, waiting, and verification until the requested goal is completed or a real blocker is found.

Default to non-interrupting operation. For websites, localhost apps, prototypes,
and browser-based product flows, use an isolated browser, Codex in-app Browser,
or cmux browser/workspace surface instead of touching the user's active
desktop. If a task cannot be completed without opening a visible tab/window,
switching Spaces, moving the foreground cursor, or focusing an app the user is
using, stop and ask for approval or an alternate route.

## Non-Interruption Contract

- Do not open a tab or window in the user's active browser for click-through
  work.
- Do not use foreground Computer Use, switch macOS Spaces, move the visible
  cursor, or focus apps on the user's active desktop unless the user explicitly
  approves that for the current task.
- Do not use `osascript`/System Events to click visible app menus, menu-bar
  items, Dock items, browser tabs, or system dialogs unless the user explicitly
  approves foreground access for the current task.
- Do not take full-screen desktop screenshots with `screencapture`, Computer
  Use, or similar tools for verification unless the user explicitly approves
  foreground access. Prefer app-rendered artifacts, isolated surfaces, logs,
  accessibility metadata, or screenshots from an isolated browser/cmux surface.
- Use a separate automation surface that can be clicked, inspected,
  screenshotted, and summarized without changing what the user is watching or
  doing.
- If the only viable route needs the user's logged-in browser session, a native
  desktop app, a system dialog, or foreground-only UI, report that limitation
  and ask before proceeding.

## Core Workflow

1. Identify the UI surface the user wants operated:
   - Default to an isolated surface for "click through", "/click",
     "test this flow manually", websites, local apps, prototypes, and browser
     targets. Do not take over the user's active screen just because the word
     "click" appears.
   - Use the Codex in-app Browser for local apps, localhost, file URLs, or
     browser targets that do not require the user's main browser profile.
   - Use cmux browser/workspace tools when the target is inside cmux or the user
     asks for a separate workspace, monitor-like surface, or background testing
     pane.
   - Use Chrome automation only when it can operate without opening or focusing
     a tab/window in the user's active browser. If the user's logged-in browser
     profile, cookies, extensions, or existing tabs are required and no
     isolated route is available, ask before continuing.
   - Use Computer Use only after explicit foreground approval for native
     desktop apps, existing visible windows, system dialogs, or visible cursor
     movement.
2. Open or attach to the isolated target surface as appropriate for the selected tool, then take a fresh state snapshot or screenshot before acting.
3. Turn the user's goal into a short checklist of concrete user actions.
4. Perform one action at a time. Prefer user-level clicks, keypresses, typing, selection, and scrolling over DOM mutation, direct API calls, or code-only inspection. Use a visible cursor only when the selected tool and user intent call for it.
5. After every meaningful action, verify the result from the UI:
   - Check navigation, changed text, enabled/disabled controls, validation messages, toasts, modals, saved state, or visual changes.
   - Re-snapshot or re-read the screen after navigation, DOM changes, animation, or loading.
   - If a click appears to do nothing, try the most likely user-level recovery once, such as waiting, scrolling the target into view, refocusing, or clicking a more precise visible element.
6. Continue until the goal is done, the user needs to provide credentials/2FA/payment approval, or the UI is blocked by a real bug.
7. Report what was clicked, what was verified, and any failures or uncertainty.

## Operating Rules

- Be user-like: use visible controls and natural interaction paths unless the user asks for implementation-level inspection.
- Prefer isolated browser control when the target can run in a browser. "Click
  through" means actually operate the UI, not operate the user's current screen.
- Honor background requests when feasible:
  - For websites, local apps, prototypes, and browser-based flows, use the
    Codex in-app Browser, cmux browser tools, or another isolated automation
    surface so the user can keep using another tab, window, or Space.
  - If the user asks for "another Space", "another monitor", "off to the
    side", or "without taking over my screen", interpret that as a request for
    a separate automation surface, not for foreground Computer Use.
  - Do not use macOS Space switching as the isolation mechanism. Switching
    Spaces is itself foreground control and can interrupt the user.
  - If a logged-in session is needed, avoid the active browser. Ask whether to
    use a separate login inside the isolated surface or whether foreground
    browser access is acceptable for this task.
  - If the target is a native app or system dialog, true background operation
    may not be possible. Explain the limitation and ask before taking over any
    visible UI.
  - For native menu-bar apps, default to non-UI checks such as build/signature
    verification, logs, diagnostics files, process state, generated screenshots
    from an offscreen renderer, or a verifier mode that does not launch/focus
    the app. Treat foreground menu clicking as explicit opt-in only.
- Be persistent: explore obvious next steps, menus, tabs, and buttons needed to complete the requested goal.
- Be careful with irreversible actions: pause before purchases, sends, deletes, publishing, permission grants, account changes, or external notifications unless the user explicitly asked for that exact action.
- Keep the user informed during long walkthroughs with concise progress updates.
- Do not mark a flow complete from code inspection alone. Completion requires visible UI verification or a clear explanation of why UI verification was impossible.
- Capture enough evidence from the isolated surface to be useful: screenshots,
  exact labels, screen states, URLs, or error messages when they matter.

## Verification Checklist

For each button, form, or navigation path exercised, verify at least one concrete outcome:

- The expected page, panel, modal, or menu appears.
- The requested value is entered and remains visible.
- The save, submit, or transition produces a success state.
- Error states are visible, understandable, and recoverable.
- Disabled or loading states clear before the next action.
- The UI remains usable after refresh, navigation, or repeated clicks when relevant.

## Reporting

End with a concise walkthrough summary:

- Actions performed.
- Results verified.
- Bugs, broken controls, confusing states, or blockers found.
- Anything not completed and why.
