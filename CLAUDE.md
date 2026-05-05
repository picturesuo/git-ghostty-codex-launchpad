# CLAUDE.md

Read `AGENTS.md` first, then read `docs/agent-workflow.md` for the shared Codex/Claude workflow.

Claude-specific notes:
- Use `/compact` around 80% context used, after writing current state to the shared context file.
- Keep Claude-only commands and hooks under `.claude/` when this launcher seeds target projects.
- This launcher repo still follows the repo push boundary in `AGENTS.md`; launched target projects follow their selected publish mode.
