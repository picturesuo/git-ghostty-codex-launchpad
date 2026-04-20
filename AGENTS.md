# AGENTS.md

Be concise and direct. Prefer small, safe, reviewable changes.

## Portable Defaults
- Read relevant docs and nearby code before editing.
- Search exact error text when debugging external or unfamiliar failures.
- Follow existing patterns before introducing new ones.
- Prefer minimal diffs over broad rewrites.
- Fix root causes when practical.
- If behavior changes, update docs or comments where appropriate.
- If blocked, say what is missing and propose the next step.

## Safety
- Safe git by default: `status`, `diff`, and `log` are always okay.
- Never run destructive commands without explicit approval.
- Do not delete or rename unexpected files unless asked.
- Do not change package manager, framework, runtime, or build tooling unless asked.
- Do not push unless explicitly asked.

## Verification
- Before handoff, run relevant checks when feasible:
  - `lint`
  - `typecheck`
  - `tests`
  - `build`
- Prefer the most end-to-end verification the repo already supports when practical.
- If you cannot run something, say exactly why.

## Code Quality
- Keep edits small and reviewable.
- Keep files reasonably maintainable; split large files when it clearly helps.
- Add or update tests when fixing bugs or changing logic, when tests exist or fit naturally.
- Prefer readability over cleverness.
- Avoid repo-wide search-and-replace or bulk rewrite scripts unless explicitly asked.

## Docs
- If a `docs/` directory exists, inspect relevant docs before coding.
- If docs link to other relevant docs, follow those links until the local workflow or domain is clear.
- If `docs/repo-layering.md` exists, use it when editing or bootstrapping `AGENTS.md` across multiple repos.
- Update docs when behavior, commands, or workflows change.
- Respect any project-specific "read this first" guidance.

## Git
- Check `git status` and `git diff` before editing and before handoff.
- Make local commits at meaningful subtask boundaries when the work is substantial enough to benefit from a checkpoint.
- If a task spans multiple files, prefer one commit per finished file or one commit per logical change, whichever is cleaner.
- Do not push unless explicitly asked.
- Push after each completed chunk only when the user clearly wants that chunk published to GitHub.
- Do not assume a local commit should be pushed; pushing is separate and requires explicit user intent.
- Do not change branches unless asked.
- Do not amend commits unless asked.
- Keep commits scoped and understandable.
- Keep commit messages short, consistent, human, and understandable; use conventional-style messages when they fit naturally.

## Runtime / Tooling
- If `tools.md` exists, read the relevant sections before using repo-local commands or helper scripts.
- If `skills/` exists, read the matching skill before doing specialized repeated workflows.
- If multiple agents are working at once, read `docs/multi-agent-workflow.md` before splitting the work.
- Use the repo's existing package manager and runtime.
- Do not swap tools or introduce new dependencies without a clear reason.
- If you must add a dependency, prefer maintained and established options, and note why it was needed.
- If you edit reusable helper scripts, keep them portable and avoid unnecessary repo-specific coupling.

## Optional Local Tools
- If `scripts/committer` exists, prefer it for scoped commits.
- It stages only explicitly listed files, refuses `.`, creates a local commit only, does not push, and should clear a stale git index lock only when run with `--force`.
- If `scripts/codex-commit.sh` exists, use `--no-push` when you want the same scoped local-commit behavior without publishing.
- If `docs/` exists and a repo-local docs listing helper is available, run it before editing docs-heavy parts of the codebase.
- Use the docs helper output, including `summary` and `read_when` hints when available, to identify which docs to read before coding.
- Do not assume custom local tools exist unless they are present in this repo or on this machine.
