---
name: product-ui-polish
description: Use when building or revising customer-facing frontend UI for a startup product, including layout, interaction states, responsiveness, accessibility, demo readiness, and visual differentiation.
---

# Product UI Polish

Use this skill for pages, apps, dashboards, onboarding, billing, settings, and feature flows that customers or buyers will judge.

## Product Frame

Before coding, identify:

- audience: buyer, admin, operator, end user, developer, or founder
- job: what the screen helps them finish
- context: repeated tool, first-run setup, demo, sales page, or internal console
- trust signal: what must feel credible for a startup buyer

Operational tools should be dense, calm, and fast to scan. Marketing pages can be more expressive, but the first viewport must still make the product or offer obvious.

## Build Rules

- Build the usable experience first, not a placeholder landing page.
- Use existing design system components and tokens before inventing new styling.
- Use familiar controls: icons for tools, segmented controls for modes, toggles for binary settings, menus for option sets, tabs for views.
- Include the natural states: empty, loading, success, error, disabled, active, selected, overflow, and mobile.
- Keep text inside containers at every viewport; do not rely on viewport-scaled fonts.
- Use real or representative data so the demo path communicates value.
- Use visual assets when the product, place, object, gameplay, or person needs to be inspected.
- Preserve accessibility: labels, keyboard reachability, contrast, focus states, and reduced-motion sanity.

## Differentiation

Aim for a specific point of view, not generic polish:

- choose a tone that fits the buyer and workflow
- make typography, spacing, imagery, and motion reinforce that tone
- avoid default purple gradients, stock-like decoration, nested cards, and decorative blobs
- keep cards for repeated items, modals, and framed tools; do not make every section a card

## Verification

For local web work, verify in the browser when a dev server or static page is available:

- desktop viewport
- mobile viewport
- primary interaction path
- one failure or empty path
- no overlapping text or clipped controls
- assets load and canvas/3D surfaces are nonblank when relevant

Run the app's lint/type/test/build checks when available and proportional.

## Handoff

Report the URL or file, checks run, visual/runtime proof, and any state or viewport not verified.
