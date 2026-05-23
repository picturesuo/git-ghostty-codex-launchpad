---
name: repo-doc-policy-edit
description: Use when changing AGENTS.md, README.md, tools.md, docs, or shared workflow policy so rules stay concise, operational, and consistent with implemented behavior.
---

# Repo Doc Policy Edit

Use this skill when editing durable instructions, operator docs, shared workflow notes, queue state, or command inventory.

## Read First

Run:

```bash
bash scripts/docs-list.sh
```

Then read only the controlling sources for the rule:

- `AGENTS.md`: durable always-on repo policy
- `README.md`: user-facing launcher workflow
- `tools.md`: commands that actually exist
- `docs/context-budget.md`: what belongs in prompts, docs, and shared artifacts
- `docs/agent-workflow.md`: cross-agent reset and publish policy
- `docs/knowledge.md`: durable facts and user preferences
- `docs/queue.md`: current and follow-up task state

## Workflow

1. Identify the source-of-truth doc for the specific rule you are changing.
2. Inspect nearby docs for conflicting wording before editing.
3. Turn vague policy into executable rules, success criteria, or command references.
4. Keep the edit proportional: remove duplicated text, point to the owner doc, and add detail only where agents need it at runtime.
5. If a rule exists in multiple docs, align it in the same pass or leave a clear note about the mismatch.
6. Read the edited text directly and run focused checks.

## Guardrails

- Keep `AGENTS.md` terse. Put commands in `tools.md`, repeated procedures in `skills/`, and mutable task state in the shared artifact.
- Do not add personal upstream paths, private tooling, broad catalogs, or product requirements that do not apply to this repo.
- Do not document behavior that the scripts cannot do.
- Do not preserve outdated wording just because it appears in several files.
- Avoid broad rewrites when a narrow alignment removes the ambiguity.

## Product-Engineering Bias

For startup/product work, docs should help agents ship useful customer-visible increments:

- name the user or operator outcome
- state the smallest safe workflow
- preserve proof commands
- keep rollback/failure modes visible when behavior affects publishing, auth, generated output, or launch state

## Verification

Use the narrowest checks that cover the touched docs:

```bash
git diff --check
bash scripts/docs-list.sh
bash scripts/validate-skills.sh
```

Also run prompt or launcher checks when edited docs describe prompt output, pane behavior, publish behavior, or helper commands.
