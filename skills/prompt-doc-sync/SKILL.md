---
name: prompt-doc-sync
description: Use when editing launcher prompts, role bodies, generated prompt docs, or prompt-size policy so source, rendered docs, and verification stay aligned.
---

# Prompt Doc Sync

Use this skill when work touches launcher prompt behavior, generated prompt docs, role bodies, or context budget.

## Workflow

1. Treat `prompts/prompt-source.sh` as the source of truth.
2. Read the current rendered output before editing:
   - `docs/generated-prompts.md`
   - `docs/role-selection.md`
3. Identify which layer owns the rule:
   - durable repo policy: `AGENTS.md`
   - runtime wrapper or role prompt: `prompts/prompt-source.sh`
   - mutable task state: shared context artifact
   - command inventory: `tools.md`
   - repeated workflow: `skills/*/SKILL.md`
4. Make the smallest source edit that expresses the behavior once.
5. Remove duplicated boilerplate instead of adding a second copy.
6. Regenerate prompt docs.
7. Validate drift and relevant launcher behavior.

## Commands

```bash
bash scripts/render-prompt-docs.sh
bash scripts/check-prompt-drift.sh
bash scripts/test-launcher.sh
```

If shell entry points changed and `shellcheck` is installed:

```bash
bash scripts/check-shell.sh
```

## Prompt Quality Bar

- Keep shared wrapper text short; role prompts should carry role-specific deltas only.
- Prefer source-of-truth pointers over copied command catalogs.
- Keep live session state out of generated docs unless it is a placeholder or documented example.
- Keep base roles stable: `BUILDER`, `BACKEND`, `DEBUGGER`, `CRITIC`; extra panes repeat with suffixes.
- Do not add motivational or generic agent advice that is already covered by repo policy.

## Guardrails

- Do not hand-edit generated prompt docs unless the task is explicitly about generated output formatting and the source cannot express it.
- Do not let `AGENTS.md`, `README.md`, generated docs, and prompt source disagree about publish or context-reset behavior.
- Do not treat prompt drift checks as enough when the edit changes launcher state, pane layout, or agent commands; run the relevant launcher tests too.
- If generated docs change unexpectedly, inspect the source diff before accepting the rendered output.

## Handoff Evidence

Report:

- source files changed
- generated files refreshed
- drift check result
- launcher or shell checks run
- any skipped verification and the reason
