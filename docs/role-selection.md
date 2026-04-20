---
summary: Generated quick reference for when to use each launcher role.
read_when:
  - You need the shortest current role-selection rubric.
  - You are checking whether role guidance drifted from prompts/prompt-source.sh.
---

# Role Selection

- `BUILDER`: use when the task artifact is missing, vague, or needs tighter success criteria before implementation.
- `BACKEND`: use when the artifact is concrete enough to implement the next scoped change.
- `CRITIC`: use when implementation exists and needs pass/fail judgment, missing risks, or stronger criteria.
- `DEBUGGER`: use when a criterion failed, an invariant broke, or a critic finding needs a minimal confirmed fix.
