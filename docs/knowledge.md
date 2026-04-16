# Knowledge

## User-Provided Knowledge
- Capture durable user guidance, preferences, and constraints that should survive past a single task.
- `user`: Keep agent prompts token-efficient and role-specific. Do not give every role shared context it does not need.
- `user`: Use four roles only in this repo's prompt docs and launcher prompts: `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`.
- `user`: Automatically commit any non-private repo-visible file change once it is coherent enough to save.
- `user`: When a GitHub remote and upstream are configured, publish non-private repo-visible commits in the same turn by default.
- `user`: Before asking where to push, try to infer the GitHub destination automatically from remotes, repo docs, nearby canonical repos, and the authenticated GitHub account.

## Project Facts
- Capture stable project facts, decisions, and summaries worth reusing across tasks.
- `repo`: Canonical prompt source lives in `prompts/prompt-source.sh`, and generated prompt docs live in `docs/generated-prompts.md`.
- `repo`: Wrapper-level prompt text should stay minimal and should not duplicate response-format or fallback behavior already owned by `AGENTS.md` or the shared artifact.
- `repo`: The documented role set is four roles only: `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`.
- `repo`: Canonical GitHub repo slug is `picturesuo/git-ghostty-codex-launchpad`.

## Retrieval Hints
- Search this file, the shared context file, and nearby repo docs with `rg` before broader search.
- Label each note by source when useful: `user`, `repo`, or `external`.
