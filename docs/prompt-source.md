---
summary: Ownership guide for the canonical prompt source and its generated prompt docs.
read_when:
  - You are editing prompts/prompt-source.sh or the generated prompt docs.
  - You need to know where wrapper text and role guidance should live.
---

# Prompt Source

Canonical prompt source lives in [prompts/prompt-source.sh](/Users/bensuo/ghostty-codex-launchpad/prompts/prompt-source.sh).

Generated prompt docs live in [docs/generated-prompts.md](/Users/bensuo/ghostty-codex-launchpad/docs/generated-prompts.md), and the generated role summary lives in [docs/role-selection.md](/Users/bensuo/ghostty-codex-launchpad/docs/role-selection.md).

Rules:
- Keep the wrapper limited to terminal-local project facts, session metadata, and `ROLE`.
- Include only compact live control fields in the wrapper: agent role, publish mode, remote hints, and the 80% context reset reminder.
- Keep shared fallback behavior in `AGENTS.md` and the shared artifact instead of repeating it in every role block.
- Keep role bodies role-specific and token-efficient.
- Keep the documented base role set to `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`; repeated panes use suffixes such as `BACKEND-2` and should reuse the base role body.
- Do not truncate brace placeholders in generated docs; placeholders such as `{SESSION_ID}` should render whole so drift is obvious.
