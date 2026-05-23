---
name: product-implementation-loop
description: Use when implementing, refactoring, or debugging product code so the agent reads first, changes surgically, preserves sellable user value, and verifies against explicit success criteria.
---

# Product Implementation Loop

Use this skill for product code changes after the target outcome is clear enough to build.

## Loop

1. Inspect current state:
   - `git status --short`
   - relevant docs and nearby code
   - existing tests, routes, components, schemas, and helpers
2. State assumptions and the smallest viable change.
3. Implement the narrowest vertical slice that satisfies the success criteria.
4. Remove only dead code created by your change.
5. Run focused checks as soon as a slice is testable.
6. Iterate until behavior and proof match the goal.
7. Update docs, generated files, migrations, seeds, or fixtures only when behavior requires it.

## Engineering Bar

- Match the existing stack, style, package manager, test framework, and ownership boundaries.
- Prefer simple code that a startup team can maintain under pressure.
- Add abstractions only when they remove real duplication or encode a proven invariant.
- Treat auth, billing, data retention, privacy, payments, and customer-visible messaging as high-risk surfaces.
- Keep observability practical: log or surface enough context to debug early customer failures without leaking secrets.
- Use current official docs for stale or unstable APIs before coding against memory.

## Verification Mapping

Tie each success criterion to proof:

```text
SC1 -> unit/integration/e2e/manual check:
SC2 -> unit/integration/e2e/manual check:
Risk -> mitigation or explicit not verified:
```

Use tests for deterministic behavior, browser/runtime checks for UI flows, and manual proof only when automation would exceed the task's scope.

## Anti-Patterns

- Rebuilding an adjacent system to make a small feature fit.
- Adding generalized config, factories, or plugin systems before a second use exists.
- Treating a passing build as proof of product behavior.
- Shipping a UI that looks plausible but has no working empty, loading, error, and success states.
- Leaving TODOs where a customer or operator will hit them.

## Handoff

End with:

- what changed
- why it satisfies the product outcome
- tests/checks run
- what remains unverified
- next smallest product step
