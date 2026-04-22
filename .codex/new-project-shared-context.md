# Codex shared session context

- Project name: new project
- Project directory: /Users/bensuo/Desktop/new-project
- Target file: README.md
- Active task artifact ID: README.md
- Session ID: a5196b41
- Session source of truth: this file

This session is for the named project only.
Wait for the user to give the next instruction before making changes.

## TASK ARTIFACT

1. Goal
- Define a first-pass `README.md` task that gives this repository a minimal, truthful starting document without inventing product details that do not exist yet.

2. Scope
- In scope: create an initial `README.md` that names the project, explains the repository is at an early setup stage, and gives a small amount of orientation for the current repo state.
- Out of scope: feature claims, setup instructions that are not validated in the repo, architecture details, badges, screenshots, or roadmap content beyond the immediate next step.

3. Constraints
- Technical constraints: derive all README content from the current repository contents and session context only; do not claim code, tooling, or workflows that are not present.
- Product constraints: keep the README generic and accurate because no concrete product requirements or implemented functionality are recorded yet.
- Time or complexity constraints: prefer a short, bootstrap-level README that can be implemented in one pass without additional discovery.

4. Success Criteria
- SC1: `README.md` begins with the project name and a concise statement that the repository is in an initial setup state.
- SC2: `README.md` includes a small orientation section that accurately describes the current repo contents or purpose without asserting missing functionality.
- SC3: `README.md` ends with a clear immediate-next-step or placeholder section that makes the repository easier to extend later.

5. Invariants
- INV1: The README must remain truthful to the current repository state and session context.
- INV2: The README must stay minimal; it should not introduce speculative requirements, commands, or implementation details.

6. Failure Modes
- FM1: The README implies the project already has functionality, setup steps, or structure that does not exist.
- FM2: The README is so generic or empty that it fails to orient a future contributor to the current state of the repository.

7. Risks / Open Questions
- R1: The repository currently contains almost no product context, so even a minimal README can drift into guesswork if it is not kept tightly grounded.
- R2: Because the repo is empty aside from task-management docs, the resulting README may need near-term revision once real implementation begins.
- Q1: Should the initial README mention the internal `docs/queue.md` and `docs/knowledge.md` files, or stay focused on external-facing repository basics only?
- Q2: Is the intended audience for this first README the project owner only, or future collaborators as well?

8. Test Mapping
- SC1 -> Verify the first heading is the project name and the opening text states the repository is in an initial or bootstrap state.
- SC2 -> Review each descriptive statement in `README.md` against the actual repo contents and remove any unsupported claims.
- SC3 -> Confirm the README includes one explicit next-step or placeholder section that a later role can expand.


### Reusable Knowledge
- User-provided knowledge: none captured yet
- Durable project facts: none captured yet
- Retrieval path: search `docs/knowledge.md`, this shared context file, and nearby repo docs with `rg` before broader search.
- Ingestible sources in v1: direct user instructions, pasted facts, stable repo docs, and short summaries of resolved task decisions.

### Weak Spots / Coaching
- Weak spots: none recorded yet
- Coaching guidance: none recorded yet
- Learning loop: `CRITIC` should turn repeated or high-severity weak points into targeted coaching guidance that later roles can reuse.

9. Status
- State: ready for implementation
- Outstanding issues: Q1 and Q2 are unresolved, but they do not block drafting a minimal README if the implementer stays conservative.
- Next action: implement `README.md` to satisfy SC1-SC3 while preserving INV1-INV2.
