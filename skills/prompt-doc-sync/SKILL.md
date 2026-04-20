---
name: prompt-doc-sync
description: Use when editing the Ghostty launcher prompt system, generated prompt docs, or role summaries. Covers source-of-truth edits in prompts/prompt-source.sh, when to regenerate docs, and how to validate prompt drift.
---

# Prompt Doc Sync

Use this skill when work touches any of:
- `prompts/prompt-source.sh`
- `docs/generated-prompts.md`
- `docs/role-selection.md`
- launcher wrapper text that should stay in sync with generated prompt output

## Workflow

1. Treat `prompts/prompt-source.sh` as the source of truth.
2. Inspect the current generated docs before editing to see what is already rendered.
3. Make the smallest source edit that expresses the new behavior.
4. Regenerate prompt docs with `bash scripts/render-prompt-docs.sh`.
5. Validate with `bash scripts/check-prompt-drift.sh`.
6. If shell entry points changed too, also run `bash scripts/check-shell.sh`.

## Guardrails

- Do not hand-edit generated prompt docs unless the task is explicitly about generated output formatting and the source cannot express it.
- Keep wrapper text minimal when the prompt source already owns the behavior.
- Call out any mismatch between `AGENTS.md`, `README.md`, prompt source, and generated docs instead of leaving conflicting instructions behind.

