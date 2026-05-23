---
name: product-slice-planning
description: Use when turning a startup product idea, feature request, vague build task, or customer problem into a narrow sellable slice with assumptions, scope, proof, and next implementation steps.
---

# Product Slice Planning

Use this skill before implementation when the work is a product, MVP, paid feature, demo, or customer-facing workflow.

## Start

Convert the request into a sellable slice:

1. Buyer/user: who pays, who uses it, who approves it.
2. Pain: the expensive or frequent problem this solves.
3. Promise: the smallest outcome worth showing or charging for.
4. Existing surface: where this belongs in the current product.
5. Constraints: time, stack, data, auth, billing, integrations, compliance, device/browser support.
6. Proof: how success can be verified by tests, demo flow, analytics, customer feedback, or live behavior.

If more than one interpretation exists, state it. Ask only when the choice changes architecture, data exposure, billing, compliance, or the core user promise.

## Slice Shape

Prefer one vertical path over many partial layers:

- landing/onboarding path only if it gets a real user to value
- one core job-to-be-done
- one source of truth for state
- one happy path plus the top failure path
- focused observability or analytics when it changes product decisions
- enough admin/operator visibility to debug early customers

Avoid speculative roles, settings, integrations, dashboards, themes, and abstractions until a real user workflow requires them.

## Output

For planning handoff, produce:

```text
Goal: <customer-visible outcome>
Assumptions: <explicit, risky first>
Scope:
- In:
- Out:
Success criteria:
- SC1:
- SC2:
Invariants:
- INV1:
Failure modes:
- FM1:
Verification:
- <test/build/demo/check>
Next implementation step: <single concrete step>
```

Use stable IDs (`SC1`, `INV1`, `FM1`, `Q1`) when the plan will feed multiple agents or a shared artifact.

## Product Filters

Keep the slice oriented toward selling to startups:

- Shorten time-to-value.
- Make setup self-serve where practical.
- Make the demo path reliable and seeded with credible data.
- Make failure states explain what to do next.
- Prefer boring dependable tech over novelty.
- Keep pricing, auth, billing, and data-export implications visible when touched.

## Guardrails

- Do not invent product requirements unrelated to the user's goal.
- Do not plan a platform when a narrow workflow can validate demand.
- Do not hide uncertainty in generic language.
- Do not start broad implementation until success criteria and proof are usable.
