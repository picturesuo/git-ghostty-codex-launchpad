# Prompt Source

Canonical prompt source lives in [prompts/prompt-source.sh](/Users/bensuo/ghostty-codex-launchpad/prompts/prompt-source.sh).

Generated prompt docs live in [docs/generated-prompts.md](/Users/bensuo/ghostty-codex-launchpad/docs/generated-prompts.md), and the generated role summary lives in [docs/role-selection.md](/Users/bensuo/ghostty-codex-launchpad/docs/role-selection.md).

Rules:
- Keep the wrapper limited to terminal-local project facts, session metadata, and `ROLE`.
- Keep shared fallback behavior in `AGENTS.md` and the shared artifact instead of repeating it in every role block.
- Keep role bodies role-specific and token-efficient.
- Keep the documented role set to `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`.
