---
name: product-release-readiness
description: Use before demoing, shipping, publishing, or selling a product change; checks proof, customer data risk, onboarding, billing, analytics, deploy state, docs, and rollback readiness.
---

# Product Release Readiness

Use this skill when the next action is demo, ship, publish, deploy, merge, sales handoff, or customer trial.

## Readiness Pass

Check the product path end to end:

1. Entry: how a new user reaches the feature.
2. Value: the core workflow succeeds with realistic data.
3. Failure: errors explain next steps and do not expose secrets.
4. Persistence: saved state, migrations, seeds, and data exports behave as expected.
5. Trust: auth, permissions, billing, privacy, terms, and destructive actions are correct for the surface.
6. Observability: logs, analytics, or admin views can explain early customer problems.
7. Support: docs, changelog, onboarding, or runbooks cover what changed.
8. Rollback: there is a practical path if the launch fails.

## Proof

Prefer direct evidence:

- automated tests for deterministic logic
- build/type/lint for release blockers
- browser or app walkthrough for customer flows
- CLI/API smoke test for backend surfaces
- current provider docs for unstable external APIs
- CI/release output for published artifacts

Do not treat a green build as proof of onboarding, billing, or product value.

## Startup Buyer Checklist

Before saying "ready", answer:

- Can a buyer understand the value in under one minute?
- Can a new user complete the first useful action without handholding?
- Can the team debug a failed customer attempt?
- Are pricing, limits, and plan gates honest where touched?
- Is customer data protected, exportable when expected, and not logged accidentally?
- Is there a credible demo path with seeded or real-looking data?

## Stop Conditions

Stop before release or handoff when:

- credentials, payment settings, or production access are missing
- a migration, destructive action, or rollback path is unclear
- customer data handling is guessed
- verification does not cover the promised workflow
- generated docs or prompts are stale

State the blocker and the next concrete action.

## Handoff

Use this shape:

```text
Ready / Not ready: <reason>
Proof:
- <command or walkthrough>: <result>
Risks:
- <remaining uncertainty>
Next:
- <one concrete release or fix step>
```
