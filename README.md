# ghostty codex launcher

## Canonical Repo

This workspace is a duplicate documentation copy, not the canonical project repo.

Use `/Users/bensuo/ghostty-codex-launchpad` for future code changes, validation, and publishing. That repo already contains the real launcher implementation and is the correct repo to reuse instead of treating this folder as a separate project.
For GitHub publishing, treat this duplicate workspace as mapped to `picturesuo/git-ghostty-codex-launchpad`.

This repo currently documents the Codex operating workflow for the project. Keep the durable repo rules in [AGENTS.md](/Users/bensuo/Desktop/codex-ghostty-launcher/AGENTS.md) and keep the current task state in `/Users/bensuo/.codex/codex-ghostty-launcher-shared-context.md`.

## Prompt Split
- `AGENTS.md`: durable repo policy.
- Shared context file: durable task artifact for the current task.
- Per-request prompt: only runtime context, role, and the instruction to read the other two first.
- After `/clear`, re-share the exact terminal's shared project context before the next role prompt so the session keeps its terminal-local task contract.

This keeps prompt overhead low and reduces drift between turns.

## Context Efficiency

Aim for a thin wrapper and durable state outside the prompt.

- Put stable policy in `AGENTS.md`.
- Put current task state in the shared artifact.
- Keep the wrapper limited to terminal-local facts plus the role.
- Make each role prompt describe only its delta.
- Prefer artifact IDs to prose recap.
- Move any rule repeated across roles up into the base prompt or down into repo policy.

The ideal shape is explicit but sparse: low redundancy, clear ownership, and enough structure to keep quality high without paying for the same instructions every turn.

## Commit Defaults

For this repo, the default is to commit every non-private repo-visible file change as soon as that change is coherent enough to save. That includes code, config, scripts, workflow files, and collaborator-facing docs.

Do not commit private or local-only material by default, including external shared-context files, scratch notes, caches, logs, secrets, editor metadata, and machine-specific config.

The helper contract is now:
- [scripts/codex-commit.sh](/Users/bensuo/Desktop/codex-ghostty-launcher/scripts/codex-commit.sh) commits only the paths you pass
- generated commit messages should be short, human-readable, and a little more descriptive than bare labels
- if an upstream already exists, the helper pushes there directly
- if no upstream exists, the helper first tries to infer a safe GitHub destination from existing remotes, repo docs, the canonical repo mapping, and the authenticated GitHub account
- if there is one confident destination, it pushes and sets upstream automatically
- if there is not one confident destination, it fails clearly and tells you to configure the destination or use `--no-push`

Automatic publishing should still be conservative about identity: infer when the match is clear, but do not guess when repo identity is ambiguous.

## Prompt Source

Prompt source blocks no longer live in `README.md`.

- Canonical prompt source: [docs/prompt-source.md](/Users/bensuo/Desktop/codex-ghostty-launcher/docs/prompt-source.md)
- Generated prompt doc: [docs/generated-prompts.md](/Users/bensuo/Desktop/codex-ghostty-launcher/docs/generated-prompts.md)
- Generated launcher contract: [docs/generated-launcher-contract.md](/Users/bensuo/Desktop/codex-ghostty-launcher/docs/generated-launcher-contract.md)
- Generator: [scripts/render-prompt-docs.sh](/Users/bensuo/Desktop/codex-ghostty-launcher/scripts/render-prompt-docs.sh)
- Drift checker: [scripts/check-prompt-drift.sh](/Users/bensuo/Desktop/codex-ghostty-launcher/scripts/check-prompt-drift.sh)
- Role-set checker: [scripts/check-role-set.sh](/Users/bensuo/Desktop/codex-ghostty-launcher/scripts/check-role-set.sh)
- Commit-helper validator: [scripts/validate-codex-commit.sh](/Users/bensuo/Desktop/codex-ghostty-launcher/scripts/validate-codex-commit.sh)
- Context budget: [docs/context-budget.md](/Users/bensuo/Desktop/codex-ghostty-launcher/docs/context-budget.md)

Regenerate docs with:

```bash
bash scripts/render-prompt-docs.sh
```

Check the canonical launcher against the documented prompt contract with:

```bash
bash scripts/check-prompt-drift.sh
```

Check that only the intended four roles appear with:

```bash
bash scripts/check-role-set.sh
```

Exercise `scripts/codex-commit.sh` edge cases with:

```bash
bash scripts/validate-codex-commit.sh
```

## Launcher Drift

The actual launcher-emitted prompt currently lives in `/Users/bensuo/ghostty-codex-launchpad/git-ghostty-codex-launchpad.sh`.

Current drift versus this repo's canonical prompt source:
- The launcher still emits extra wrapper lines beyond project facts and role.
- The launcher still carries fallback behavior that should move into the shared artifact.
- The launcher role list still needs to stay aligned with this repo's documented role set: `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`.

Treat `docs/prompt-source.md` as the target prompt contract for cleanup work.

## Prompt Ownership

- Wrapper and role text: `docs/prompt-source.md`
- Generated prompt doc: `docs/generated-prompts.md`
- Repo-wide policy: `AGENTS.md`
- Current task state, fallback behavior, and status contract: shared context artifact

Keep `README.md` descriptive only. Prompt payloads should stay in the canonical source file, generated prompt doc, and shared artifact instead of returning here.
