# Codex shared session context

- Project name: ghostty codex launcher
- Project directory: /Users/bensuo/Desktop/ghostty-codex-launcher
- Target file: README.md
- Session source of truth: this file

This session is for the named project only.
Wait for the user to give the next instruction before making changes.

## Workflow Contract

- Use the shared context file as the durable TASK ARTIFACT and source of truth.
- Read `/Users/bensuo/Desktop/ghostty-codex-launcher/AGENTS.md` first if it exists and follow repo policy there.
- No implementation starts before initial success criteria exist.
- Reference artifact IDs exactly: `SC1`, `INV1`, `FM1`, `R1`, `Q1`, `F1`.
- Keep scope tight and avoid task expansion unless a true blocker is identified.
- If assumptions are made, state them explicitly.

## TASK ARTIFACT

1. Goal
- Reuse the existing `/Users/bensuo/ghostty-codex-launchpad` repo as the canonical project instead of continuing to treat `Desktop/ghostty-codex-launcher` as a separate repo.

2. Scope
- In scope: inspect `/Users/bensuo/ghostty-codex-launchpad`, confirm it already contains the real launcher code and shared-artifact workflow logic, add repo-operating files there, and update the duplicate workspace `README.md` to redirect future work to the canonical repo.
- Out of scope: deleting repos, changing GitHub visibility, rewriting launcher runtime behavior, or rewiring the parent `/Users/bensuo` git repo remote.

3. Constraints
- Technical constraints: keep changes limited to `/Users/bensuo/ghostty-codex-launchpad`, `/Users/bensuo/Desktop/ghostty-codex-launcher/README.md`, and this shared artifact; do not change the parent repo remote from a nested directory.
- Product constraints: make the canonical repo obvious and attach future workflow docs to the repo that already contains the real launcher code.
- Time or complexity constraints: prefer the smallest safe fix that prevents repeated use of the duplicate workspace.

4. Success Criteria
- SC1: `/Users/bensuo/ghostty-codex-launchpad` is inspected and confirmed to already contain the launcher implementation and shared-artifact workflow behavior, so repo reuse is justified.
- SC2: `/Users/bensuo/ghostty-codex-launchpad` gains practical repo-operating files: `AGENTS.md`, `docs/queue.md`, and `scripts/codex-commit.sh`.
- SC3: The commit helper works safely when the project root is also the git root, so the canonical repo does not inherit nested-repo assumptions.
- SC4: `/Users/bensuo/Desktop/ghostty-codex-launcher/README.md` clearly redirects future work to `/Users/bensuo/ghostty-codex-launchpad`.
- SC5: Lightweight validation is run and reported for the canonical repo files and the redirect note.

5. Invariants
- INV1: Preserve the existing launcher code and shared-artifact workflow behavior already present in `/Users/bensuo/ghostty-codex-launchpad`.
- INV2: Do not invent runtime, setup, or validation commands that do not exist in the canonical repo.
- INV3: Be explicit about what was verified versus not verified.

6. Failure Modes
- FM1: The duplicate `ghostty-codex-launcher` workspace continues to be treated like a separate project even though the real launcher already lives in `/Users/bensuo/ghostty-codex-launchpad`.
- FM2: Repo-operating files are added to the canonical repo but still assume a nested project root, causing incorrect helper behavior.
- FM3: The duplicate workspace is left without a clear redirect and future work keeps landing in the wrong folder.

7. Risks / Open Questions
- R1: `Desktop/ghostty-codex-launcher` is nested inside a larger git repo rooted at `/Users/bensuo`, so remote changes from that folder would be risky and misleading.
- R2: The canonical GitHub repo state was inferred from the local checkout and remote config, not revalidated through the GitHub API in this turn.
- Q1: Assumption: `/Users/bensuo/ghostty-codex-launchpad` is the existing repo the user referred to as “Get Go See Codex Launch Pad.”
- Q2: Assumption: the safest fix in this turn is to redirect to and reuse the canonical repo rather than delete or rename any repo.

8. Test Mapping
- SC1 -> Inspect `/Users/bensuo/ghostty-codex-launchpad` files and launcher script contents for existing launcher and artifact-driven workflow behavior.
- SC2 -> Inspect the new `AGENTS.md`, `docs/queue.md`, and `scripts/codex-commit.sh` in `/Users/bensuo/ghostty-codex-launchpad`.
- SC3 -> Run `bash -n /Users/bensuo/ghostty-codex-launchpad/scripts/codex-commit.sh` and inspect the root-handling logic.
- SC4 -> Inspect `/Users/bensuo/Desktop/ghostty-codex-launcher/README.md` for the canonical-repo redirect.
- SC5 -> Inspect scoped `git status --short -- .` in `/Users/bensuo/ghostty-codex-launchpad` after the file additions.

9. Status
- State: local fix applied and validated; commit pending user approval
- Outstanding issues:
  - F2 Failure mapping: `SC1`, `SC2`, `SC4`, `INV1`, and `FM1` failed because a duplicate `ghostty-codex-launcher` workspace was being treated like a separate repo even though the real launcher code already exists in `/Users/bensuo/ghostty-codex-launchpad`.
  - F2 Root cause: repository selection drifted away from the canonical repo, and the duplicate workspace lives inside a different parent git repo, making remote reuse from that folder unsafe.
  - F2 Minimal fix plan: add the missing repo-operating files to `/Users/bensuo/ghostty-codex-launchpad`, make the commit helper safe at a repo root, and redirect the duplicate workspace through `README.md`.
  - F2 Re-test targets: `SC1`, `SC2`, `SC3`, `SC4`, `SC5`, `FM1`, `FM2`, `FM3` validated locally.
- Next action: commit the canonical repo changes in `/Users/bensuo/ghostty-codex-launchpad` if the user wants the fix recorded in git now.

Use this end-of-turn format every time:
1. Summary: one or two sentences describing what changed.
2. Artifact updates: list only the artifact sections you created, changed, verified, or diagnosed this turn, using the artifact IDs directly.
3. Changed files: list only the files you actually touched.
4. Why: one short sentence explaining why these changes or artifact updates were made.
