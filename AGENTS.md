# AGENTS.md

Style: concise, direct, small safe diffs. Prefer evidence over guesses.

## Read First
- Read relevant docs and nearby code before editing.
- Read `docs/agent-workflow.md` for launcher workflow, target bootstrap, or shared Codex/Claude policy.
- Run `bash scripts/docs-list.sh` before docs-heavy, policy-heavy, or workflow-heavy edits.
- Read `tools.md` before using repo-local helpers; read matching `skills/*/SKILL.md` for repeated workflows.
- Read `docs/multi-agent-workflow.md` before splitting work across agents or panes.

## Safety
- Safe git: `git status`, `git diff`, `git log`.
- No destructive git, branch changes, deletes, renames, package/runtime/tooling swaps, or broad rewrites unless explicitly asked.
- Never revert unrecognized changes; assume another user/agent made them and work around them.
- Search exact external or unfamiliar error text before guessing.

## Work
- Follow existing patterns; keep diffs minimal and reviewable.
- Fix root causes when practical; add focused regression coverage when changing behavior or fixing bugs.
- Update docs/comments when behavior, commands, or workflows change.
- Prefer readability over cleverness; avoid repo-wide search-and-replace scripts unless asked.
- If blocked, state what is missing and the next concrete step.

## Verification
- Before handoff, run relevant `lint`, `typecheck`, `tests`, and `build` checks when feasible.
- Use `bash scripts/test-launcher.sh` for launcher state, panes, agent commands, remote fallback, or prompt rendering.
- Run `bash scripts/validate-skills.sh` after editing skills.
- Run `bash scripts/check-shell.sh` when `shellcheck` is installed.
- Say exactly what was not run and why.

## Git / Publish
- Check `git status` and `git diff` before edits and before handoff.
- This launcher repo: do not push unless the user explicitly asks.
- Launched target projects: publish mode `auto` means agents may auto-commit and auto-push coherent repo-visible non-private files through the launcher helper.
- Publish mode `off`: local/manual only unless the user asks.
- Prefer one commit per finished file or logical change; keep messages short and human.
- Use `bash scripts/codex-commit.sh` with explicit paths. Use `--no-push` for local-only checkpoints and `--each-path` for per-file commits.

## Context
- Treat about 80% context used as the reset point.
- Before compacting or starting fresh, write status, decisions, changed files, verification, and next action to the shared context file.
- Do not spend the final 20% on broad planning or multi-file edits.
