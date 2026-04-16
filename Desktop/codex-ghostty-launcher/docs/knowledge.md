# Knowledge

## User-Provided Knowledge
- Capture durable user guidance, preferences, and constraints that should survive past a single task.
- `user`: Backend turns should update the shared context file directly, but only in sections owned by the role.
- `user`: Keep agent prompts token-efficient. Prefer role-specific instructions only, and avoid giving every agent context it does not need.
- `user`: Use four roles only in this repo's prompt docs: `BUILDER`, `BACKEND`, `CRITIC`, and `DEBUGGER`. Do not reintroduce `QUEUE-MANAGER` unless the user asks for it.
- `user`: Automatically commit any non-private repo-visible file change once it is coherent enough to save. Personal or local-only files should remain uncommitted unless explicitly requested.
- `user`: When a GitHub remote and upstream are configured, publish non-private repo-visible commits in the same turn by default. If not configured, say so explicitly.
- `user`: Before asking where to push, try to infer the GitHub destination automatically from remotes, repo docs, nearby canonical repos, and the authenticated GitHub account. Ask only when the destination is genuinely ambiguous.

## Project Facts
- Capture stable project facts, decisions, and summaries worth reusing across tasks.
- `repo`: This repository is a duplicate documentation/workflow copy; `/Users/bensuo/ghostty-codex-launchpad` is the canonical implementation repo.
- `repo`: This duplicate workspace publishes to GitHub repo `picturesuo/git-ghostty-codex-launchpad` when automatic destination resolution is needed.
- `repo`: Even in this duplicate repo, artifact-scoped workflow behavior should stay in repo-local files unless the shared artifact is revised first.
- `repo`: Prompt source blocks should live in `docs/prompt-source.md`, with generated prompt docs in `docs/generated-prompts.md`, not inline in `README.md`.

## Retrieval Hints
- Search this file, the shared context file, and nearby repo docs with `rg` before broader search.
- Label each note by source when useful: `user`, `repo`, or `external`.
