# Codex shared session context

- Project name: ghostty codex launcher
- Project directory: /Users/bensuo/Desktop/ghostty-codex-launcher
- Target file: README.md
- Session source of truth: this file

This session is for the named project only.
Wait for the user to give the next instruction before making changes.

## Workflow Contract

- Use the shared context file as the durable TASK ARTIFACT and source of truth.
- On the first pass in a newly opened tab, the artifact may still be empty or only contain placeholders. Do not treat that as a failure.
- If you are the Builder and the artifact is still empty, initialize it before implementation.
- If you are not the Builder and the artifact is still empty on the first pass, acknowledge that Builder must initialize it and do not block on the missing artifact yet.
- Do not use `/fast` or enable fast mode as part of this workflow.
- No implementation starts before initial success criteria exist.
- No task is complete until all success criteria pass, critical invariants are preserved, and no unresolved high-severity risk remains.
- Reference artifact IDs exactly: `SC1`, `INV1`, `FM1`, `R1`, `Q1`, `F1`.
- Keep scope tight and avoid task expansion unless a true blocker is identified.
- If assumptions are made, state them explicitly.
- Distinguish clearly between goal, implementation, verification, and diagnosis.
- Prefer structured, low-verbosity output that later roles can reuse directly.

## TASK ARTIFACT

1. Goal
- Inspect the `ghostty-codex-launcher` project for any existing AGENTS-equivalent repo-operating document, then create and commit a practical root-level `AGENTS.md` plus minimal supporting workflow files if no true equivalent exists.

2. Scope
- In scope: inspect the project directory for existing artifact or workflow documents, evaluate whether any existing file is truly equivalent to `AGENTS.md`, create or update `/Users/bensuo/Desktop/ghostty-codex-launcher/AGENTS.md`, create `/Users/bensuo/Desktop/ghostty-codex-launcher/docs/queue.md` and `/Users/bensuo/Desktop/ghostty-codex-launcher/scripts/codex-commit.sh` if missing, run lightweight validation, and commit the intended repository files.
- Out of scope: editing product code beyond the workflow files above, broad documentation rewrites outside the new operating docs, altering unrelated files in the parent git repository, or cleaning unrelated pre-existing worktree noise.

3. Constraints
- Technical constraints: use this shared context file as the source of truth, keep changes localized to the project directory, use `apply_patch` for file edits, prefer CLI-first inspection and validation, and preserve any useful instructions already present in the external shared context file.
- Product constraints: the resulting `AGENTS.md` must directly instruct Codex on navigation, commands, validation, coding constraints, workflow expectations, commit behavior, working memory, and the four-pane role model.
- Time or complexity constraints: keep the solution minimal and immediately usable; if the git root being `/Users/bensuo` prevents a fully clean worktree due to unrelated existing files, do not modify unrelated files and report the limitation explicitly.

4. Success Criteria
- SC1: The repository is inspected for existing AGENTS-equivalent documents, and the final result explicitly states what was found and whether it is truly equivalent to `AGENTS.md`.
- SC2: A root-level `AGENTS.md` exists in `/Users/bensuo/Desktop/ghostty-codex-launcher` and includes the requested operating principles, four-pane role definitions (`builder`, `critic`, `debugger`, `queue-manager`), commit expectations, validation guidance, queue usage, and maintenance rules.
- SC3: `/Users/bensuo/Desktop/ghostty-codex-launcher/docs/queue.md` exists with a practical task queue structure that the roles in `AGENTS.md` can use immediately.
- SC4: `/Users/bensuo/Desktop/ghostty-codex-launcher/scripts/codex-commit.sh` exists, is executable, stages intended changes, creates concise human-sounding commit messages when needed, and can be invoked directly from `AGENTS.md`.
- SC5: Lightweight validation is run and reported, including at minimum a shell syntax check for the commit helper and a direct inspection of created files for completeness.
- SC6: The intended project files are committed with a concise accurate commit message, and there is no unresolved high-severity issue in the created workflow files.

5. Invariants
- INV1: Preserve any genuinely useful existing instructions by incorporating or referencing them rather than replacing them blindly.
- INV2: Do not touch unrelated files outside `/Users/bensuo/Desktop/ghostty-codex-launcher` except for this shared artifact and git metadata needed for the requested commit.
- INV3: Be explicit about what was verified versus not verified.

6. Failure Modes
- FM1: A partial artifact, such as the external shared context file, is incorrectly treated as a full `AGENTS.md` equivalent even though it lacks repo-operating instructions.
- FM2: The new `AGENTS.md` omits one or more requested operating principles or role definitions, making it incomplete for the user's workflow.
- FM3: The commit helper stages too broadly or generates unusably generic commit messages.
- FM4: The overall git worktree cannot be made fully clean because the parent git repository already contains unrelated untracked files, and that limitation is not surfaced clearly.

7. Risks / Open Questions
- R1: The project directory is nested inside a larger git repository rooted at `/Users/bensuo`, so repository cleanliness may be affected by unrelated existing files.
- R2: The project currently contains almost no files, so the new `AGENTS.md` must avoid pretending there are existing project-specific test or build commands when none are present.
- Q1: Assumption confirmed for this task: the "root-level" `AGENTS.md` lives at `/Users/bensuo/Desktop/ghostty-codex-launcher/AGENTS.md`, treating the project directory as the working repo root for Codex instructions.
- Q2: Assumption confirmed for this task: the new project files are committed within the parent git repository while unrelated pre-existing untracked files outside the project remain untouched.

8. Test Mapping
- SC1 -> Search the project directory for repo-operating files and review the external shared context file to assess equivalence.
- SC2 -> Inspect `AGENTS.md` and verify it contains the requested operating principles, role definitions, workflow expectations, commit behavior, and maintenance guidance.
- SC3 -> Inspect `docs/queue.md` and verify it contains usable queue sections for immediate execution.
- SC4 -> Run `bash -n scripts/codex-commit.sh`, inspect the script contents, and verify the file mode is executable.
- SC5 -> Review the created files directly and report the validation commands that were run.
- SC6 -> Stage and commit only the intended project files, then inspect the relevant git status for those files.

9. Status
- State: complete with repo-level cleanliness limitation noted
- Outstanding issues: the parent git repository rooted at `/Users/bensuo` already contains unrelated untracked files, so the overall worktree cannot be made globally clean without touching unrelated user files.
- Next action: none for this task; future work should start from `docs/queue.md` and the new `AGENTS.md`.

Use this end-of-turn format every time:
1. Summary: one or two sentences describing what changed.
2. Artifact updates: list only the artifact sections you created, changed, verified, or diagnosed this turn, using the artifact IDs directly.
3. Changed files: list only the files you actually touched.
4. Why: one short sentence explaining why these changes or artifact updates were made.
5. Commit message: write the exact commit message you want to use, in a single line, in practical plain English. If no code changed, say `No code changes in this turn`.
6. Commit request: explicitly ask whether to commit now. If there are no code changes, say there is nothing to commit yet.
7. Status: say whether the task is waiting for Critic review, Tester verification, Debugger action, user approval, or is complete because all criteria pass and no unresolved high-severity issue remains.
