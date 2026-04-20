---
summary: Rules for what belongs in repo policy, shared task state, and runtime prompt context.
read_when:
  - You are changing prompt size, context packing, or shared-artifact ownership.
  - You need to decide whether guidance belongs in AGENTS.md, docs, or the shared task artifact.
---

# Context Budget

- Stable policy belongs in `AGENTS.md`.
- Mutable task state belongs in the shared artifact.
- Runtime prompt should carry only local project facts and role-specific delta.
- Durable reusable notes belong in `docs/knowledge.md`.
- Do not repeat output-format text when it is already owned by the shared artifact or repo policy.
